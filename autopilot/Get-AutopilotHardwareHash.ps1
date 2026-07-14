<#
.SYNOPSIS
    Get-AutopilotHardwareHash.ps1 - Collects Windows Autopilot hardware hash for device registration.

.DESCRIPTION
    Extracts the hardware hash, serial number, and product key from the local device
    and exports it as a CSV file ready for import into Microsoft Intune Autopilot portal.

.AUTHOR
    Muhammad Arslan - Senior Infrastructure Engineer

.EXAMPLE
    .\Get-AutopilotHardwareHash.ps1 -OutputPath "C:\Temp\AutopilotHash.csv"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\AutopilotHash.csv"
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Windows Autopilot Hardware Hash Collector" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "[ERROR] This script must be run as Administrator."
    exit 1
}

# Install required module if not present
if (-not (Get-Module -ListAvailable -Name "Get-WindowsAutopilotInfo")) {
    Write-Host "[INFO] Installing Get-WindowsAutopilotInfo module..." -ForegroundColor Yellow
    Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$false
}

# Collect hardware hash
try {
    $computerInfo = Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
    $serialNumber = (Get-CimInstance -Class Win32_BIOS).SerialNumber
    $hardwareHash = $computerInfo.DeviceHardwareData

    $autopilotDevice = [PSCustomObject]@{
        'Device Serial Number' = $serialNumber
        'Windows Product ID'   = ''
        'Hardware Hash'        = $hardwareHash
    }

    $autopilotDevice | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "[SUCCESS] Hardware hash exported to: $OutputPath" -ForegroundColor Green
    Write-Host "[INFO] Serial Number: $serialNumber" -ForegroundColor Cyan
    Write-Host "[INFO] Import this CSV into Intune > Devices > Enrollment > Windows Autopilot devices" -ForegroundColor Yellow
} catch {
    Write-Error "[ERROR] Failed to retrieve hardware hash: $_"
    exit 1
}