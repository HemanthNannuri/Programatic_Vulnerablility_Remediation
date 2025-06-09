<#
.SYNOPSIS
    This PowerShell script ensures that The built-in guest account must be renamed. The built-in guest account is a well-known user account on all Windows systems and, as initially installed, does not require a password. This can allow access to system resources by unauthorized users. Renaming this account to an unidentified name improves the protection of this account and the system.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-14
    Last Modified   : 2025-01-14
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-SO-000025

.TESTED ON
    Date(s) Tested  : 2025-01-14
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-SO-000025-Remediation.ps1
#>

# Enable verbose output
$VerbosePreference = "Continue"

# -----------------------------
# Function Definitions
# -----------------------------

# Function to log messages
function Log-Message {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    switch ($Level) {
        "INFO"  { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN"  { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

# Function to check administrative privileges
function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "This script must be run as an Administrator. Exiting." "ERROR"
        exit 1
    } else {
        Log-Message "Administrative privileges verified." "INFO"
    }
}

# Function to get the current guest account name
function Get-GuestAccountName {
    try {
        $guestAccount = Get-WmiObject -Class Win32_UserAccount -Filter "SID LIKE 'S-1-5-21-%-501' AND LocalAccount=True"
        if ($guestAccount -and $guestAccount.Name) {
            Log-Message "Current guest account name is '$($guestAccount.Name)'." "INFO"
            return $guestAccount.Name
        } else {
            Log-Message "Guest account not found." "WARN"
            return $null
        }
    } catch {
        Log-Message "Failed to retrieve guest account name. Error: $_" "ERROR"
        return $null
    }
}

# Function to rename the guest account
function Rename-GuestAccount {
    param (
        [string]$CurrentName,
        [string]$NewName
    )

    try {
        Log-Message "Renaming guest account from '$CurrentName' to '$NewName'." "INFO"
        Rename-LocalUser -Name $CurrentName -NewName $NewName -ErrorAction Stop
        Log-Message "Guest account successfully renamed to '$NewName'." "INFO"
    } catch {
        Log-Message "Failed to rename guest account. Error: $_" "ERROR"
        exit 1
    }
}

# Function to verify the renamed guest account
function Verify-GuestAccount {
    param (
        [string]$ExpectedName
    )

    try {
        $guestAccount = Get-WmiObject -Class Win32_UserAccount -Filter "SID LIKE 'S-1-5-21-%-501' AND LocalAccount=True"
        if ($guestAccount -and $guestAccount.Name -eq $ExpectedName) {
            Log-Message "Verification successful: Guest account is renamed to '$ExpectedName'." "INFO"
            return $true
        } else {
            Log-Message "Verification failed: Guest account is not renamed to '$ExpectedName'." "ERROR"
            return $false
        }
    } catch {
        Log-Message "Failed to verify guest account. Error: $_" "ERROR"
        return $false
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for administrative privileges
Check-AdminPrivileges

# Step 2: Define the new guest account name
$NewGuestName = "Temp-User"

# Step 3: Get the current guest account name
$CurrentGuestName = Get-GuestAccountName

if ($null -eq $CurrentGuestName) {
    Log-Message "No guest account found. Exiting." "ERROR"
    exit 1
}

# Step 4: Rename the guest account if necessary
if ($CurrentGuestName -ne $NewGuestName) {
    Rename-GuestAccount -CurrentName $CurrentGuestName -NewName $NewGuestName
} else {
    Log-Message "Guest account is already named '$NewGuestName'. No changes needed." "INFO"
}

# Step 5: Verify the change
$VerificationResult = Verify-GuestAccount -ExpectedName $NewGuestName
if (-not $VerificationResult) {
    Log-Message "Failed to configure 'Accounts: Rename guest account' policy. Exiting." "ERROR"
    exit 1
}

Log-Message "Policy configuration completed successfully." "INFO"

# -----------------------------
# End of Script
# -----------------------------
