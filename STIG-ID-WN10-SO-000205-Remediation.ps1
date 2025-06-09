

Write-Host "Setting LAN Manager authentication level to send NTLMv2 only, refuse LM & NTLM..."

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$lmaValueName = 'LmCompatibilityLevel'
$lmaValueData = 5  # 5 => Send NTLMv2 only, refuse LM & NTLM

# Ensure the registry path exists
if (-not (Test-Path $regPath)) {
    New-Item -Path (Split-Path $regPath) -Name (Split-Path $regPath -Leaf) -Force | Out-Null
}

# Create/Update the LmCompatibilityLevel value
New-ItemProperty -Path $regPath -Name $lmaValueName -Value $lmaValueData -PropertyType DWORD -Force | Out-Null

Write-Host "LmCompatibilityLevel is now set to 5.`nVerifying..."

(Get-ItemProperty -Path $regPath -Name $lmaValueName) |
    Select-Object -Property $lmaValueName

Write-Host "`nSTIG WN10-SO-000205 remediation complete. If domain-joined, ensure no GPO overrides this setting."
