

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

# Function to get the current policy value
function Get-CurrentPolicyValue {
    param (
        [string]$PolicyName
    )

    try {
        $currentValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "$PolicyName" -ErrorAction SilentlyContinue).$PolicyName
        return $currentValue
    } catch {
        Log-Message "Failed to retrieve the current policy value for '$PolicyName'. Error: $_" "ERROR"
        return $null
    }
}

# Function to set the policy value
function Set-PolicyValue {
    param (
        [string]$PolicyName,
        [int]$DesiredValue
    )

    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "$PolicyName" -Value $DesiredValue -Force
        Log-Message "Policy '$PolicyName' set to '$DesiredValue'." "INFO"
    } catch {
        Log-Message "Failed to set the policy value for '$PolicyName'. Error: $_" "ERROR"
        exit 1
    }
}

# Function to verify the policy value
function Verify-PolicyValue {
    param (
        [string]$PolicyName,
        [int]$ExpectedValue
    )

    $currentValue = Get-CurrentPolicyValue -PolicyName $PolicyName

    if ($currentValue -eq $ExpectedValue) {
        Log-Message "Verification successful: '$PolicyName' is set to '$currentValue'." "INFO"
        return $true
    } else {
        Log-Message "Verification failed: '$PolicyName' is set to '$currentValue', expected '$ExpectedValue'." "ERROR"
        return $false
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Check for administrative privileges
Check-AdminPrivileges

# Define the policy name and desired value
$PolicyName = "InactivityTimeoutSecs"
$DesiredValue = 900  # 900 seconds or less, excluding 0

# Log the start of configuration
Log-Message "Configuring 'Interactive logon: Machine inactivity limit' policy to '$DesiredValue' seconds." "INFO"

# Test the current setting
$currentValue = Get-CurrentPolicyValue -PolicyName $PolicyName
if ($null -eq $currentValue) {
    Log-Message "Current policy value for '$PolicyName' is not set." "INFO"
} else {
    Log-Message "Current policy value for '$PolicyName': $currentValue." "INFO"
}

# Apply the desired setting
Set-PolicyValue -PolicyName $PolicyName -DesiredValue $DesiredValue

# Verify the applied setting
if (Verify-PolicyValue -PolicyName $PolicyName -ExpectedValue $DesiredValue) {
    Log-Message "'Interactive logon: Machine inactivity limit' policy configured successfully." "INFO"
} else {
    Log-Message "Failed to configure 'Interactive logon: Machine inactivity limit' policy." "ERROR"
    exit 1
}

Log-Message "Policy configuration process completed." "INFO"
WN10-SO-000025✅✅
