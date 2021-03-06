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
    [ValidateSet('1.2.7','1.2.6','1.3.0')]
    $puppetagentver='1.3.0',
    $Puppetmaster = 'PuppetMaster1',
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"
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
$Puppetmaster = "$Puppetmaster.$env:USERDOMAIN"
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
$Setuppath = "\\vmware-host\Shared Folders\Sources\Puppet\puppet-agent-$puppetagentver-x64.msi"
.$NodeScriptDir\test-setup -setup PuppetAgent -setuppath $Setuppath
Write-Warning "Installing Puppet Agent $puppetagentver"
$PuppetArgs = '/qn /norestart /i "'+$Setuppath+'" PUPPET_MASTER_SERVER='+$Puppetmaster
Start-Process -FilePath "msiexec.exe" -ArgumentList $PuppetArgs -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
