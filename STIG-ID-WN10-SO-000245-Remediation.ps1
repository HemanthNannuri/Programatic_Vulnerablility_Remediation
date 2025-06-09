<#
.SYNOPSIS
    This PowerShell script ensures that the User Account Control (UAC) is a security mechanism for limiting the elevation of privileges, including administrative accounts, unless authorized. This setting configures the built-in Administrator account so that it runs in Admin Approval Mode.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-09
    Last Modified   : 2025-01-09
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-SO-000245

.TESTED ON
    Date(s) Tested  : 2025-01-09
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-SO-000245-Remediation.ps1
#>

# Define the registry key and value for "User Account Control: Admin Approval Mode for the Built-in Administrator account"
$RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "FilterAdministratorToken"
$RegistryValueData = 1  # 1 = Enabled (Admin Approval Mode enabled for Built-in Administrator account)

# Set the registry value to enable Admin Approval Mode for the Built-in Administrator account
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'User Account Control: Admin Approval Mode for the Built-in Administrator account' has been enabled."
