<#
.SYNOPSIS
    This PowerShell script ensures that saving passwords in the Remote Desktop Client could allow an unauthorized user to establish a remote desktop session to another system. The system must be configured to prevent users from saving passwords in the Remote Desktop Client.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-09
    Last Modified   : 2025-01-09
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-CC-000270

.TESTED ON
    Date(s) Tested  : 2025-01-09
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-CC-000270-Remediation.ps1
#>

# Define the registry key and value for the "Do not allow passwords to be saved" policy
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$RegistryValueName = "DisablePasswordSaving"
$RegistryValueData = 1  # 1 = Enabled (disables saving passwords)

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Do not allow passwords to be saved" policy to Enabled (1)
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Do not allow passwords to be saved' policy has been enabled."
