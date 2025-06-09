<#
.SYNOPSIS
    This PowerShell script ensures that the account lockout feature, when enabled, prevents brute-force password attacks on the system. The higher this value is, the less effective the account lockout feature will be in protecting the local system. The number of bad logon attempts must be reasonably small to minimize the possibility of a successful password attack, while allowing for honest errors made during a normal user logon.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-11
    Last Modified   : 2025-01-11
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-AC-000010

.TESTED ON
    Date(s) Tested  : 2025-01-011
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator.
    Example syntax:
    PS C:\> .\STIG-ID-WN10-AC-000010-Remediation.ps1 
#>

# Define desired values (adjust if your STIG or policy requires different)
[int]$lockoutThreshold   = 3    # Number of invalid attempts before lockout
[int]$lockoutDuration    = 30   # How many minutes the account stays locked
[int]$lockoutWindow      = 30   # How many minutes before the bad logon counter resets

Write-Host "Current Account Policy Settings:"
net accounts

Write-Host "`nApplying STIG-compliant Account Lockout Settings..."

# Configure the Lockout Threshold
net accounts /lockoutthreshold:$lockoutThreshold

# Configure the Lockout Duration (minutes)
net accounts /lockoutduration:$lockoutDuration

# Configure the timeframe to reset invalid logon attempts (minutes)
net accounts /lockoutwindow:$lockoutWindow

Write-Host "`nAccount Lockout settings updated. Verifying changes..."

# Re-check the current account policy
net accounts | Out-Host
Write-Host "`nSTIG WN10-AC-000010 remediation script completed."
