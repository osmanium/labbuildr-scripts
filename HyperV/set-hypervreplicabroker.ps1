﻿<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    [string]$Clustervolume = "C:\ClusterStorage\Volume1"

)
$Nodescriptdir = "$Scriptdir\NODE"
$EXScriptDir = "$Scriptdir\$ex_version"
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
######################################################################

if (!(Test-Path "$Clustervolume\Replica"))
    {
    New-Item -ItemType Directory -Path "$Clustervolume\Replica" -Force
    }

$Clustername = (get-cluster .).name

switch ($Clustername)
    {
    "HV1Cluster"
    {
    $Broker_IP = "192.168.2.154"
    }
    "HV2Cluster"
    {
    $Broker_IP = "192.168.2.159"
    }
}
$BrokerName = “$($Clustername)-Broker”
Add-ClusterServerRole -Name $BrokerName –StaticAddress $Broker_IP
Add-ClusterResource -Name “Virtual Machine Replication Broker” -Type "Virtual Machine Replication Broker" -Group $BrokerName
Add-ClusterResourceDependency “Virtual Machine Replication Broker” $BrokerName
Start-ClusterGroup $BrokerName


