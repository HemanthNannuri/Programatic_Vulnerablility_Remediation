

# Enable verbose output
$VerbosePreference = "Continue"

# -----------------------------
# Function Definitions
# -----------------------------

function Log-Message {
    param (
        [Parameter(Mandatory=$true)]
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

function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "This script must be run as an Administrator. Exiting." "ERROR"
        exit 1
    } else {
        Log-Message "Administrative privileges verified." "INFO"
    }
}

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

function Restart-WinRMService {
    try {
        Log-Message "Restarting the WinRM service to apply changes..." "INFO"
        Restart-Service -Name WinRM -Force -ErrorAction Stop
        Log-Message "WinRM service restarted successfully." "INFO"
    } catch {
        Log-Message "Failed to restart the WinRM service. Error: $_" "WARN"
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for administrative privileges
Check-AdminPrivileges

# Step 2: Define registry settings
$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client"
$ValueName = "AllowUnencryptedTraffic"
$DesiredValue = 0  # 0 = Disabled

# Step 3: Check current setting
$currentValue = Get-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName
if ($null -eq $currentValue) {
    Log-Message "'Allow unencrypted traffic' is not currently set." "INFO"
} else {
    Log-Message "Current 'Allow unencrypted traffic' setting: '$currentValue'." "INFO"
}

# Step 4: Apply the desired setting
Set-RegistryValue -RegistryPath $RegistryPath -ValueName $ValueName -Value $DesiredValue -PropertyType "DWORD"

# Step 5: Verify the setting
$verificationResult = Verify-RegistrySetting -RegistryPath $RegistryPath -ValueName $ValueName -ExpectedValue $DesiredValue
if (-not $verificationResult) {
    Log-Message "Failed to configure 'Allow unencrypted traffic'. Exiting." "ERROR"
    exit 1
}

# Step 6: Restart the WinRM service
Restart-WinRMService

# Step 7: Log success
Log-Message "'Allow unencrypted traffic' policy has been configured successfully." "INFO"
