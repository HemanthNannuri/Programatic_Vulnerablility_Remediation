<#
.SYNOPSIS
    This PowerShell script ensures that Information systems not protected with strong password schemes (including passwords of minimum length) provide the opportunity for anyone to crack the password, thus gaining access to the system and compromising the device, information, or the local network.
.NOTES    
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-11
    Last Modified   : 2025-01-11
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-AC-000035

.TESTED ON
    Date(s) Tested  : 2025-01-11
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG ID: WN10-AC-000035-Remediation.ps1
#>

Write-Host "Setting minimum password length to 14 characters..."

# Set minimum password length to 14
net accounts /minpwlen:14

Write-Host "`nValidating current account policy..."
net accounts | Out-Host
