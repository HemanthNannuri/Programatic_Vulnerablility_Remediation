# Enable verbose output
$VerbosePreference = "Continue"

# -----------------------------
# Function Definitions
# -----------------------------

# Function to log messages with different severity levels
function Log-Message {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    
    switch ($Level) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN" { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

# Function to verify administrative privileges
function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "This script must be run as an Administrator. Please run PowerShell with elevated privileges." "ERROR"
        exit 1
    } else {
        Log-Message "Administrative privileges verified." "INFO"
    }
}

# Function to check PowerShell bitness (64-bit)
function Check-PowerShellBitness {
    if ([IntPtr]::Size -eq 8) {
        Log-Message "Running in 64-bit PowerShell." "INFO"
    } else {
        Log-Message "WARNING: Running in 32-bit PowerShell. Please run the script in a 64-bit PowerShell session to modify the correct registry hive." "WARN"
        # Optionally, exit the script if 64-bit is required
        # exit 1
    }
}

# Function to get current registry value
function Get-RegistryValue {
    param (
        [string]$Path,
        [string]$Name
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $value.$Name
    } catch {
        return $null
    }
}

# Function to set a registry value
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type
    )

    try {
        # Check if the registry path exists; if not, create it
        if (-not (Test-Path -Path $Path)) {
            Log-Message "Registry path '$Path' does not exist. Creating the path..." "WARN"
            New-Item -Path $Path -Force | Out-Null
            Log-Message "Registry path '$Path' created successfully." "INFO"
        } else {
            Log-Message "Registry path '$Path' exists." "INFO"
        }

        # Get current value
        $currentValue = Get-RegistryValue -Path $Path -Name $Name

        if ($null -eq $currentValue) {
            Log-Message "Registry value '$Name' does not exist. Creating and setting it to '$Value'." "WARN"
            # Use New-ItemProperty to create the registry value with the specified type
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
            Log-Message "Registry value '$Name' created and set to '$Value'." "INFO"
        }
        elseif ($currentValue -ne $Value) {
            Log-Message "Current value of '$Name' is '$currentValue'. Updating it to '$Value'." "INFO"
            # Use Set-ItemProperty without the -Type parameter
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
            Log-Message "Registry value '$Name' updated to '$Value'." "INFO"
        }
        else {
            Log-Message "Registry value '$Name' is already set to '$Value'. No changes needed." "INFO"
        }
    } catch {
        Log-Message "Failed to set registry value '$Name' at path '$Path'. Error: $_" "ERROR"
        exit 1
    }
}

# Function to verify registry settings
function Verify-RegistrySetting {
    param (
        [string]$Path,
        [string]$Name,
        [object]$ExpectedValue
    )
    
    try {
        $currentValue = Get-RegistryValue -Path $Path -Name $Name

        if ($null -eq $currentValue) {
            Log-Message "Verification failed: Registry value '$Name' does not exist." "ERROR"
            return $false
        }

        if ($currentValue -eq $ExpectedValue) {
            Log-Message "Verification successful: '$Name' is set to '$ExpectedValue'." "INFO"
            return $true
        } else {
            Log-Message "Verification failed: '$Name' is set to '$currentValue', expected '$ExpectedValue'." "ERROR"
            return $false
        }
    } catch {
        Log-Message "Failed to verify registry value '$Name': $_" "ERROR"
        return $false
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for administrative privileges
Check-AdminPrivileges

# Step 2: Check PowerShell bitness
Check-PowerShellBitness

# Define registry settings
$registryPath1 = "HKLM:\Software\Policies\Microsoft\Windows\GameDVR"
$valueName1 = "AllowGameDVR"
$desiredValue1 = 0  # 0 = Disabled
$valueType1 = "DWORD"

$registryPath2 = "HKLM:\Software\Policies\Microsoft\Windows\Gaming\GameBar"
$valueName2 = "AllowAutoGameMode"
$desiredValue2 = 0  # 0 = Disabled
$valueType2 = "DWORD"

# Additional setting to disable Game Bar itself
$valueName3 = "AllowGameBar"
$desiredValue3 = 0  # 0 = Disabled

# Log the start of configuration
Log-Message "Starting configuration of 'Enables or disables Windows Game Recording and Broadcasting' policy." "INFO"

# Step 3: Configure AllowGameDVR
Set-RegistryValue -Path $registryPath1 -Name $valueName1 -Value $desiredValue1 -Type $valueType1

# Step 4: Configure AllowAutoGameMode
Set-RegistryValue -Path $registryPath2 -Name $valueName2 -Value $desiredValue2 -Type $valueType2

# Step 5: Disable Game Bar
Set-RegistryValue -Path $registryPath2 -Name $valueName3 -Value $desiredValue3 -Type $valueType1

# Step 6: Verify registry settings
$verifyGameDVR = Verify-RegistrySetting -Path $registryPath1 -Name $valueName1 -ExpectedValue $desiredValue1
$verifyAutoGameMode = Verify-RegistrySetting -Path $registryPath2 -Name $valueName2 -ExpectedValue $desiredValue2
$verifyGameBar = Verify-RegistrySetting -Path $registryPath2 -Name $valueName3 -ExpectedValue $desiredValue3

if ($verifyGameDVR -and $verifyAutoGameMode -and $verifyGameBar) {
    Log-Message "All registry settings have been configured correctly." "INFO"
} else {
    Log-Message "One or more registry settings failed to configure correctly." "ERROR"
    exit 1
}

# Step 7: Optional - Force Group Policy update
try {
    Log-Message "Forcing Group Policy update..." "INFO"
    gpupdate /force | Out-Null
    Log-Message "Group Policy update completed." "INFO"
} catch {
    Log-Message "Failed to update Group Policy: $_" "WARN"
}

# Step 8: Prompt for system reboot or user logoff
Log-Message "A system reboot or user logoff may be required for the changes to take full effect." "WARN"
$rebootChoice = Read-Host "Do you want to restart the system now to ensure changes take effect? (Y/N)"

if ($rebootChoice -match '^[Yy]$') {
    Log-Message "Restarting the system..." "INFO"
    Restart-Computer -Force
} else {
    Log-Message "Please remember to restart the system later to apply the changes." "WARN"
}

Log-Message "Policy configuration process completed." "INFO"

# -----------------------------
# End of Script
# -----------------------------
