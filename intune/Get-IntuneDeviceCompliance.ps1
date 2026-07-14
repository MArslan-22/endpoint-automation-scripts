<#
.SYNOPSIS
    Get-IntuneDeviceCompliance.ps1 - Retrieves compliance status of all Intune-managed devices.

.DESCRIPTION
    Uses Microsoft Graph API to query device compliance policies and generates a summary report.
    Requires Graph API permissions: DeviceManagementManagedDevices.Read.All

.AUTHOR
    Muhammad Arslan - Senior Infrastructure Engineer

.EXAMPLE
    .\Get-IntuneDeviceCompliance.ps1 -TenantId "your-tenant-id"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\ComplianceReport.csv"
)

# Connect to Microsoft Graph
try {
    Connect-MgGraph -TenantId $TenantId -Scopes "DeviceManagementManagedDevices.Read.All"
    Write-Host "[INFO] Connected to Microsoft Graph for tenant: $TenantId" -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Failed to connect to Microsoft Graph: $_"
    exit 1
}

# Retrieve all managed devices
$devices = Get-MgDeviceManagementManagedDevice -All

# Build compliance report
$report = foreach ($device in $devices) {
    [PSCustomObject]@{
        DeviceName       = $device.DeviceName
        UserPrincipal    = $device.UserPrincipalName
        ComplianceState  = $device.ComplianceState
        OS               = $device.OperatingSystem
        OSVersion        = $device.OsVersion
        LastSyncDateTime = $device.LastSyncDateTime
        ManagementAgent  = $device.ManagementAgent
        EncryptionStatus = $device.IsEncrypted
    }
}

# Export report
$report | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "[INFO] Compliance report exported to: $OutputPath" -ForegroundColor Cyan
Write-Host "[INFO] Total devices: $($report.Count)" -ForegroundColor Cyan
Write-Host "[INFO] Compliant: $(($report | Where-Object ComplianceState -eq 'Compliant').Count)" -ForegroundColor Green
Write-Host "[INFO] Non-Compliant: $(($report | Where-Object ComplianceState -eq 'NonCompliant').Count)" -ForegroundColor Red