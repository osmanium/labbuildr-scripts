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
    $nodes = 2,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"
    )
$Nodescriptdir = "$Scriptdir\NODE"
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
# Test-Cluster –Node GenNode1, GenNode2, GenNode3, GenNode4–Include “Storage Spaces Direct”,Inventory,Network,”System Configuration”
Write-Host "Enabling Spaces Direct"
# Enable-ClusterStorageSpacesDirect
Enable-ClusterStorageSpacesDirect -SkipEligibilityChecks -Autoconfig:$false -PoolFriendlyName S2DPool -confirm:$false
#Enable-ClusterS2D -S2DCacheMode Disabled
$Domain = $env:USERDOMAIN
$FQDN = $env:USERDNSDOMAIN
$ClusterName = (Get-Cluster .).Name
$Clusterfqdn = "$ClusterName.$FQDN"
Write-Host "Getting Storage Subsystems for Cluster $Clusterfqdn"
$StorageSubSystem = Get-StorageSubSystem -Name $Clusterfqdn
Write-Host "Creating S2D Pool for $Clusterfqdn"
$Storagepool = $StorageSubSystem | New-StoragePool  -FriendlyName "$Domain-Pool1" -WriteCacheSizeDefault 0 -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisk ($StorageSubSystem | Get-PhysicalDisk)
# Get-StoragePool Pool1 | Get-PhysicalDisk |? MediaType -eq SSD | Set-PhysicalDisk -Usage Journal
Write-Host "Building CSV Volumes with ReFS"
foreach ($vdisk in 1..3)
    {
    $Storagepool | New-Volume -FriendlyName "VDISK$vdisk" -PhysicalDiskRedundancy 1 -FileSystem CSVFS_REFS –Size 50GB
    }
if ($Nodes -ge 3)
{
$Storagepool | New-VOlume -FriendlyName VDISK4 -PhysicalDiskRedundancy 2 -FileSystem CSVFS_REFS –Size 50GB
$Storagepool | New-Volume -FriendlyName VDISK5 -PhysicalDiskRedundancy 1 -FileSystem CSVFS_REFS –Size 50GB -ResiliencySettingName Parity
$Storagepool | New-Volume -FriendlyName VDISK6 -PhysicalDiskRedundancy 2 -FileSystem CSVFS_REFS -Size 50GB -ResiliencySettingName Parity
}
#Set-FileIntegrity C:\ClusterStorage\Volume1 –Enable $false
