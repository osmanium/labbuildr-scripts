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
    [Parameter(Mandatory = $false)]
    [ValidateSet('de_DE','en_US')]
    [alias('e14_lang')]$ex_lang = 'de_DE',
    $ex_version= "E2010",
    $Prereq ="Prereq",
    $Scriptdir = '\\vmware-host\Shared Folders\Scripts',
    $SourcePath = '\\vmware-host\Shared Folders\Sources',
    $logpath = "c:\Scripts"
)
$Nodescriptdir = Join-Path $Scriptdir "Node"
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
$Prereq_dir = Join-Path $SourcePath $Prereq
$Prereq_dir = Join-Path $Prereq_dir $ex_lang

.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath

$Setupcmd = "UcmaRuntimeSetup.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

$Setupcmd = "FilterPack64bit.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

if ($ex_lang -eq "de_DE")
    {
    $Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-de-de.exe"
    }
else
    {
    $Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-en-Us.exe"
    }
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
