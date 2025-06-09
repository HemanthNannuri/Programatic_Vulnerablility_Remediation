

Write-Host "=== Enforcing SMB client to always perform SMB signing (STIG WN10-SO-000100) ===`n"

$regPath  = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
$regName  = 'RequireSecuritySignature'
$regValue = 1  # 1 = Always require signing

if (-not (Test-Path $regPath)) {
    Write-Error "Registry path '$regPath' not found. Exiting."
    return
}

try {
    New-ItemProperty -Path $regPath `
                     -Name $regName `
                     -Value $regValue `
                     -PropertyType DWORD `
                     -Force | Out-Null

    Write-Host "Set '$regName' to $regValue under $regPath."
}
catch {
    Write-Error "Failed to set registry property. Error: $_"
    return
}

Write-Host "`nForcing a group policy update (local)..."
Start-Process gpupdate -ArgumentList '/force' -Wait

Write-Host "`nScript completed. 
If domain-joined, verify no domain GPO is set to disable SMB signing, 
or your local changes may be overwritten."
