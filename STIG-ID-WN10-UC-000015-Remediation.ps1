
# Enable verbose output
$VerbosePreference = "Continue"

# -----------------------------
# Function Definitions
# -----------------------------

function Log-Message {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    switch ($Level) {
        "INFO"  { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN"  { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "This script must be run as an Administrator. Exiting." "ERROR"
        exit 1
    } else {
        Log-Message "Administrative privileges verified." "INFO"
    }
}

function Ensure-RegistryPathExists {
    param ([string]$RegistryPath)
    if (-not (Test-Path -Path $RegistryPath)) {
        Log-Message "Registry path '$RegistryPath' does not exist. Creating..." "INFO"
        New-Item -Path $RegistryPath -Force | Out-Null
        Log-Message "Registry path '$RegistryPath' created successfully." "INFO"
    } else {
        Log-Message "Registry path '$RegistryPath' exists." "INFO"
    }
}

function Set-RegistryValue {
    param (
        [string]$RegistryPath,
        [string]$ValueName,
        [int]$Value
    )
    try {
        New-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -PropertyType DWORD -Force | Out-Null
        Log-Message "Registry value '$ValueName' set to '$Value' under '$RegistryPath'." "INFO"
    } catch {
        Log-Message "Failed to set registry value '$ValueName'. Error: $_" "ERROR"
        exit 1
    }
}

function Get-RegistryValue {
    param ([string]$RegistryPath, [string]$ValueName)
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

function Verify-RegistryValue {
    param ([string]$RegistryPath, [string]$ValueName, [int]$ExpectedValue)
    $currentValue = Get-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName
    if ($null -eq $currentValue) {
        Log-Message "Verification failed: Registry value '$ValueName' does not exist." "ERROR"
        return $false
    } elseif ($currentValue -eq $ExpectedValue) {
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

Check-AdminPrivileges

# Define registry path and value
$RegistryPath = "HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
$ValueName = "NoToastApplicationNotificationOnLockScreen"
$DesiredValue = 1  # Enabled

# Ensure the registry path exists
Ensure-RegistryPathExists -RegistryPath $RegistryPath

# Check the current setting
$currentSetting = Get-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName
if ($null -eq $currentSetting) {
    Log-Message "'Turn off toast notifications on the lock screen' is not currently set." "INFO"
} else {
    Log-Message "Current 'Turn off toast notifications on the lock screen' setting is '$currentSetting'." "INFO"
}

# Apply the desired setting
Set-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName -Value $DesiredValue

# Verify the setting
$verification = Verify-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName -ExpectedValue $DesiredValue
if (-not $verification) {
    Log-Message "Failed to apply the 'Turn off toast notifications on the lock screen' policy. Exiting." "ERROR"
    exit 1
}

Log-Message "Configuration of 'Turn off toast notifications on the lock screen' policy completed successfully." "INFO"
