<#
.SYNOPSIS
    This PowerShell script ensures that Microsoft consumer experiences provides suggestions and notifications to users, which may include the installation of Windows Store apps. Organizations may control the execution of applications through other means such as whitelisting. Turning off Microsoft consumer experiences will help prevent the unwanted installation of suggested applications.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-09
    Last Modified   : 2025-01-09
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-CC-000197

.TESTED ON
    Date(s) Tested  : 2025-01-09
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-CC-000197-Remediation.ps1
#>

# Define the registry key and value for "Turn off Microsoft consumer experiences"
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$RegistryValueName = "DisableWindowsConsumerFeatures"
$RegistryValueData = 1  # 1 = Enabled (turns off Microsoft consumer experiences)

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Turn off Microsoft consumer experiences" policy to Enabled
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Turn off Microsoft consumer experiences' policy has been enabled."
