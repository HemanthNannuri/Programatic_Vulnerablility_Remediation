<#
.SYNOPSIS
    This PowerShell script ensures that Remote connections must be encrypted to prevent interception of data or sensitive information. Selecting "High Level" will ensure encryption of Remote Desktop Services sessions in both directions.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-09
    Last Modified   : 2025-01-09
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-CC-000290

.TESTED ON
    Date(s) Tested  : 2025-01-09
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-CC-000290-Remediation.ps1
#>

# Define the registry key and values for "Set client connection encryption level"
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$RegistryValueName = "MinEncryptionLevel"
$RegistryValueData = 3  # 3 = High Level encryption

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Set client connection encryption level" policy to Enabled and High Level (3)
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Set client connection encryption level' has been enabled and set to High Level."
