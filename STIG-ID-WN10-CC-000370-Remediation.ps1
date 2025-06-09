<#
.SYNOPSIS
    This PowerShell script ensures that The convenience PIN for Windows 10 must be disabled. This policy controls whether a domain user can sign in using a convenience PIN to prevent enabling (Password Stuffer).
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-14
    Last Modified   : 2025-01-14
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-CC-000370

.TESTED ON
    Date(s) Tested  : 2025-01-14
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-CC-000370-Remediation.ps1
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

# Function to get current registry value
function Get-RegistryValue {
    param (
        [string]$RegistryPath,
        [string]$ValueName
    )

    try {
        if (Test-Path -Path $RegistryPath) {
            $value = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
            return $value.$ValueName
        } else {
            return $null
        }
    } catch {
        Log-Message "Failed to retrieve registry value '$ValueName'. Error: $_" "ERROR"
        return $null
    }
}

# Function to set registry value
function Set-RegistryValue {
    param (
        [string]$RegistryPath,
        [string]$ValueName,
        [object]$Value,
        [string]$PropertyType = "DWORD"
    )

    try {
        # Ensure the registry path exists
        if (-not (Test-Path -Path $RegistryPath)) {
            Log-Message "Registry path '$RegistryPath' does not exist. Creating..." "INFO"
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        # Set the registry value
        New-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -PropertyType $PropertyType -Force | Out-Null
        Log-Message "Registry value '$ValueName' set to '$Value' at '$RegistryPath'." "INFO"
    } catch {
        Log-Message "Failed to set registry value '$ValueName'. Error: $_" "ERROR"
        exit 1
    }
}

# Function to verify registry setting
function Verify-RegistrySetting {
    param (
        [string]$RegistryPath,
        [string]$ValueName,
        [object]$ExpectedValue
    )

    $currentValue = Get-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName

    if ($null -eq $currentValue) {
        Log-Message "Verification failed: Registry value '$ValueName' does not exist." "ERROR"
        return $false
    }

    if ($currentValue -eq $ExpectedValue) {
        Log-Message "Verification successful: '$ValueName' is set to '$currentValue'." "INFO"
        return $true
    } else {
        Log-Message "Verification failed: '$ValueName' is set to '$currentValue', expected '$ExpectedValue'." "ERROR"
        return $false
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for administrative privileges
Check-AdminPrivileges

# Define registry settings
$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\System"
$ValueName = "AllowDomainPINLogon"
$DesiredValue = 0  # 0 = Disabled, 1 = Enabled

# Step 2: Get current setting
$currentSetting = Get-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName
if ($null -eq $currentSetting) {
    Log-Message "'Turn on convenience PIN sign-in' is not currently set." "INFO"
} else {
    Log-Message "Current 'Turn on convenience PIN sign-in' setting: '$currentSetting'." "INFO"
}

# Step 3: Set the policy to Disabled
Set-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName -Value $DesiredValue

# Step 4: Verify the setting
$verificationResult = Verify-RegistrySetting -RegistryPath $RegistryPath -ValueName $ValueName -ExpectedValue $DesiredValue
if (-not $verificationResult) {
    Log-Message "Failed to configure 'Turn on convenience PIN sign-in' policy. Exiting." "ERROR"
    exit 1
}

Log-Message "Policy configuration completed successfully." "INFO"

# -----------------------------
# End of Script
# -----------------------------
