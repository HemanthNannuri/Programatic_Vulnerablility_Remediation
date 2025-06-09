<#
.SYNOPSIS
    This PowerShell script ensures that the server message block (SMB) protocol provides the basis for many network operations. Digitally signed SMB packets aid in preventing man-in-the-middle attacks. If this policy is enabled, the SMB client will only communicate with an SMB server that performs SMB packet signing.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-11
    Last Modified   : 2025-01-11
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-SO-000100

.TESTED ON
    Date(s) Tested  : 2025-01-011
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator.
    Example syntax:
    PS C:\> .\STIG-ID-WN10-SO-000100-Remediation.ps1 
#>

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
