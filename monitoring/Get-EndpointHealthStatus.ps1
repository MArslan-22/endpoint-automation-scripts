<#
.SYNOPSIS
    Get-EndpointHealthStatus.ps1 - Comprehensive endpoint health check for hybrid environments.

.DESCRIPTION
    Performs a series of health checks on the local endpoint including disk space,
    Windows Update status, Defender status, Intune sync, and network connectivity.

.AUTHOR
    Muhammad Arslan - Senior Infrastructure Engineer
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   Endpoint Health Status Report" -ForegroundColor Cyan
Write-Host "   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

$results = @()

# 1. Disk Space Check
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,
    @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}},
    @{n='TotalGB';e={[math]::Round($_.Size/1GB,2)}},
    @{n='PercentFree';e={[math]::Round(($_.FreeSpace/$_.Size)*100,1)}}

foreach ($d in $disk) {
    $status = if ($d.PercentFree -lt 10) { "CRITICAL" } elseif ($d.PercentFree -lt 20) { "WARNING" } else { "OK" }
    $results += [PSCustomObject]@{ Check = "Disk $($d.DeviceID)"; Value = "$($d.FreeGB)GB / $($d.TotalGB)GB ($($d.PercentFree)%)"; Status = $status }
}

# 2. Windows Defender Status
try {
    $defender = Get-MpComputerStatus
    $defStatus = if ($defender.AntivirusEnabled) { "OK" } else { "CRITICAL" }
    $results += [PSCustomObject]@{ Check = "Defender Antivirus"; Value = "Enabled: $($defender.AntivirusEnabled)"; Status = $defStatus }
    $results += [PSCustomObject]@{ Check = "Defender Signatures"; Value = "Last Updated: $($defender.AntivirusSignatureLastUpdated)"; Status = "INFO" }
} catch {
    $results += [PSCustomObject]@{ Check = "Defender Status"; Value = "Unable to query"; Status = "WARNING" }
}

# 3. Last Windows Update
try {
    $hotfix = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    $daysSince = ((Get-Date) - $hotfix.InstalledOn).Days
    $updateStatus = if ($daysSince -gt 30) { "WARNING" } else { "OK" }
    $results += [PSCustomObject]@{ Check = "Last Windows Update"; Value = "$($hotfix.HotFixID) ($daysSince days ago)"; Status = $updateStatus }
} catch {
    $results += [PSCustomObject]@{ Check = "Last Windows Update"; Value = "Unable to determine"; Status = "WARNING" }
}

# 4. Uptime
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeStatus = if ($uptime.Days -gt 30) { "WARNING" } else { "OK" }
$results += [PSCustomObject]@{ Check = "System Uptime"; Value = "$($uptime.Days) days, $($uptime.Hours) hours"; Status = $uptimeStatus }

# 5. DNS Resolution
try {
    $dns = Resolve-DnsName "graph.microsoft.com" -ErrorAction Stop
    $results += [PSCustomObject]@{ Check = "DNS (graph.microsoft.com)"; Value = "Resolved: $($dns[0].IPAddress)"; Status = "OK" }
} catch {
    $results += [PSCustomObject]@{ Check = "DNS (graph.microsoft.com)"; Value = "FAILED"; Status = "CRITICAL" }
}

# Output
$results | Format-Table -AutoSize