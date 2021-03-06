﻿<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(    
    [Parameter(Mandatory=$true)]
    [ValidateSet('MDM','TB','SDS','SDC','gateway','LIA')]$role,
    [Parameter(Mandatory=$true)]$Disks,
 	<# ScaleIOVersion
	'2.0-13000.211','2.0-10000.2075','2.0-12000.122',
	'2.0-7536.0','2.0-7536.0','2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	#>	   
	[Parameter(Mandatory=$true)]
	[ValidateSet(
	'2.0-13000.211','2.0-10000.2075','2.0-12000.122',
	'2.0-7536.0','2.0-7536.0','2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	)]
    [alias('siover')]$ScaleIOVer,    
	[Parameter(Mandatory=$false)]$mdmipa,
    [Parameter(Mandatory=$false)]$mdmipb,
    $LiaPassword = "Password123!",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $SIO_Password = 'Password123!'

)
$Nodescriptdir = "$Scriptdir\Node"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
if ($mdmipa -eq $mdmipb)
    {
    $sdc_options = "MDM_IP='+$mdmipa+'"
    }
else
    {
    $sdc_options = "MDM_IP='+$mdmipa+','+$mdmipb+'"
    }
$scaleio_major = $ScaleIOVer[0]
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
$ScaleIORoot = Join-Path $SourcePath "Scaleio"
While ((Test-Path $ScaleIORoot) -Ne $true)
    {
    Write-Warning "Cannot find $ScaleIORoot
    Make sure USB Drive Connected to Host
    Make Sure USB Stick IS NOT connected to VM
    press any key when done pr Ctrl-C to exit"
    pause
    }
if ($role -eq 'gateway')
    {
    try
        {
        $Setuppath = @()
        $Setuppath += (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*$role-$ScaleIOVer*-x64.msi" -Exclude ".*" -ErrorAction Stop ).FullName
        Write-Host $Setuppath
        }
    Catch
        {
        Write-Warning "Cannot find ScaleIO $ScaleIOVer in $ScaleIORoot
        Make sure the Windows Package is downloaded and extracted to $ScaleIORoot
        or select different version
        press any key when done pr Ctrl-C to exit"
        Break
        }
    
    $Setuppath = $Setuppath[0]
    $ScaleIOArgs = 'GATEWAY_ADMIN_PASSWORD="'+$SIO_Password+'" /i "'+$Setuppath+'" /quiet'
    Write-Verbose "ScaleIO Gateway Args = $ScaleIOArgs"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
    $Content = get-content -Path "C:\Program Files\EMC\scaleio\Gateway\webapps\ROOT\WEB-INF\classes\gatewayUser.properties"
    $Content = $Content -notmatch "mdm.ip.addresses="
    $Content += "mdm.ip.addresses=$mdmipa`;$mdmipb"
    $Content | set-content -Path "C:\Program Files\EMC\scaleio\Gateway\webapps\ROOT\WEB-INF\classes\gatewayUser.properties"
    ### path for Password Bug
    Start-Process -FilePath  "C:\Program Files\EMC\scaleio\Gateway\bin\SioGWTool.bat" -ArgumentList "--reset_password  --password Password123! --config_file `"C:\Program Files\EMC\scaleio\Gateway\webapps\ROOT\WEB-INF\classes\gatewayUser.properties`""
    Restart-Service EMCScaleIOGateway
	Write-Host -ForegroundColor Gray " ==>Adjusting Ciphers"
	$serverxml = "C:\Program Files\EMC\scaleio\Gateway\conf\server.xml"
	(Get-Content $serverxml) | ForEach-Object { $_ -replace "ciphers=.+" , 'ciphers="TLS_DHE_DSS_WITH_AES_128_CBC_SHA256,TLS_DHE_DSS_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA3842"' } | Set-Content $serverxml -Encoding UTF8
    Restart-Service 'EMC ScaleIO Gateway'
    }
else
    {
    If ($Role -match
     "TB" -and $scaleio_major -ge 2)
        { 
        $Testrole = "MDM"
        }
    else
        {
        $Testrole = $Role
        }
    While (!($ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*$Testrole-$ScaleIOVer.msi" -Exclude ".*").Directory.FullName))
    {
    Write-Warning "Cannot find ScaleIO $ScaleIOVer in $ScaleIORoot
    Make sure the Windows Package is downloaded and extracted to $ScaleIORoot
    or select different version
    press any key when done pr Ctrl-C to exit"
    }

    if ($role -ne "SDS")
        {
        switch ($role)
            {
                "TB"
                {
                switch ($scaleio_major)
                    {
                    1
                        {
                        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
                        $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
                        }
                    2
                        {
                        Write-Verbose "got major $scaleio_major"
                        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-mdm-$ScaleIOVer.msi"
                        $ScaleIOArgs = '/i "'+$Setuppath+'" MDM_ROLE_IS_MANAGER=0 /quiet'
                        }
                    }

                }
                "MDM"
                {
                switch ($scaleio_major)
                    {
                    1
                        {
                        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
                        $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
                        }
                    2
                        {
                        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
                        $ScaleIOArgs = '/i "'+$Setuppath+'" MDM_ROLE_IS_MANAGER=1 /quiet'
                        }
                    }
                }
                default
                {
                $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
                $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
                }
            
            }
            .$NodeScriptDir\test-setup.ps1 -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
            Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
        }
    foreach ($role in ("sds","sdc","lia"))
        {
        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
        switch ($role)
            {
            "sdc"
                {
                $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet' # MDM_IP='+$mdmipa+','+$mdmipb+'
                # $ScaleIOArgs = '/i "'+$Setuppath+'" '+$sdc_options+' /quiet' 
                }
            "lia"
                {
                #switch ($scaleio_major)
                    #{
                    #1
                        #{                        
                        #$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
                        #}
                   # 2
                        #{
                        $ScaleIOArgs = '/i "'+$Setuppath+'" TOKEN="'+$SIO_Password+'" /quiet'
                        #}
                    #}

                }
            default
                {
                $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
                }

            }
        
        .$NodeScriptDir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
        Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
        }
    ### configure lia
    $Content = @()
    $Content += "lia_token=$SIO_Password"
    $Content += "lia_enable_configure_call_home=0"
    $Content += Get-Content 'C:\Program Files\EMC\scaleio\lia\cfg\conf.txt'| where {$_ -NotMatch "lia_token"}
    $Content | Set-Content -Path 'C:\Program Files\EMC\scaleio\lia\cfg\conf.txt'
    restart-service lia_service

    
    
    ####sdc checkup

    Write-Verbose "Preparing Disks"
    # $Disks = (get-disk).count-1
    Write-Host $Disks
    # Stop-Service ShellHWDetection
    $PrepareDisk = "'C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe'" 
    foreach ($Disk in 1..$Disks)
        {
        Write-Output $Disk
        $Drive = "\\?\PhysicalDrive$Disk"
     Write-Output $Drive
    do {
        Write-Output "Testing ScaleIO Device"
        Start-Process -FilePath "C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe" -ArgumentList "$Drive" -Wait
        # sleep 5
        }
    until (Test-Path "c:\scaleio_devices\PhysicalDrive$Disk")
    }
}
