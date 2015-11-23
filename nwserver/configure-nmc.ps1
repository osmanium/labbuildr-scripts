<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[CmdletBinding()]
param(
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq"
     
)
$Nodescriptdir = "$Scriptdir\Node"
$NWScriptDir = "$Scriptdir\nwserver"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile -Value "$($MyInvocation.BoundParameters)"
############
$Uri = "http://localhost:9000/gconsole.jnlp"
do 
    {
    try
        {
        $gconsole_ready = Invoke-WebRequest -uri $Uri -UseBasicParsing -Method Head -ErrorAction SilentlyContinue
        }
    catch #[Microsoft.PowerShell.Commands.InvokeWebRequestCommand]
        {
        Write-Warning "Error '$_' Catched, NMC still not running, waiting 10 Seconds"
        sleep -Seconds 10
        }
    }
Until ($gconsole_ready.StatusCode -eq "200")
Write-Verbose "Setting Up NMC"
start-process $Uri

