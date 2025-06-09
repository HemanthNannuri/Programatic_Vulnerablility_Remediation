

# Enable verbose output
$VerbosePreference = "Continue"

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

function Get-CurrentSetting {
    param (
        [string]$RegistryPath,
        [string]$ValueName
    )
    try {
        if (Test-Path -Path $RegistryPath) {
            $currentValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
            return $currentValue.$ValueName
        } else {
            return $null
        }
    } catch {
        Log-Message "Failed to retrieve current setting: $_" "ERROR"
        return $null
    }
}

function Set-Setting {
    param (
        [string]$RegistryPath,
        [string]$ValueName,
        [int]$DesiredValue
    )
    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            Log-Message "Registry path '$RegistryPath' does not exist. Creating it..." "WARN"
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        $currentValue = Get-CurrentSetting -RegistryPath $RegistryPath -ValueName $ValueName
        if ($null -eq $currentValue) {
            Log-Message "Setting '$ValueName' not found. Creating and setting to '$DesiredValue'." "WARN"
            New-ItemProperty -Path $RegistryPath -Name $ValueName -Value $DesiredValue -PropertyType DWORD -Force | Out-Null
        } elseif ($currentValue -ne $DesiredValue) {
            Log-Message "Updating '$ValueName' from '$currentValue' to '$DesiredValue'." "INFO"
            Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $DesiredValue -Force
        } else {
            Log-Message "Setting '$ValueName' is already set to '$currentValue'. No changes needed." "INFO"
        }
    } catch {
        Log-Message "Failed to set '$ValueName'. Error: $_" "ERROR"
        exit 1
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

Check-AdminPrivileges

# Define the registry settings
$registryPath = "HKLM:\Software\Policies\Microsoft\PassportForWork\PINComplexity"
$valueName = "MinimumPINLength"
$desiredValue = 6

# Backup registry settings
$backupPath = "$env:TEMP\MinimumPINLength_Backup.reg"
if (Test-Path -Path $registryPath) {
    try {
        reg export $registryPath $backupPath /y | Out-Null
        Log-Message "Backup of registry key '$registryPath' completed at '$backupPath'." "INFO"
    } catch {
        Log-Message "Failed to back up registry key: $_" "WARN"
    }
}

# Get current setting
$currentSetting = Get-CurrentSetting -RegistryPath $registryPath -ValueName $valueName
if ($null -eq $currentSetting) {
    Log-Message "No current setting for 'Minimum PIN length' found." "INFO"
} else {
    Log-Message "Current 'Minimum PIN length' is '$currentSetting'." "INFO"
}

# Apply the new setting
Set-Setting -RegistryPath $registryPath -ValueName $valueName -DesiredValue $desiredValue

# Force Group Policy update
Log-Message "Forcing Group Policy update..." "INFO"
gpupdate /force | Out-Null
Log-Message "Group Policy updated." "INFO"
