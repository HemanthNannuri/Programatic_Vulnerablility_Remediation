<#
.SYNOPSIS
    This PowerShell script ensures that the Kerberos v5 authentication protocol is the default for authentication of users who are logging on to domain accounts. NTLM, which is less secure, is retained in later Windows versions for compatibility with clients and servers that are running earlier versions of Windows or applications that still use it. It is also used to authenticate logons to stand-alone computers that are running later versions.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-11
    Last Modified   : 2025-01-11
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-SO-000205

.TESTED ON
    Date(s) Tested  : 2025-01-011
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator.
    Example syntax:
    PS C:\> .\STIG-ID-WN10-SO-000205-Remediation.ps1 
#>

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
