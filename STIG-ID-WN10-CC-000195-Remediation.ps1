# Enable verbose output
$VerbosePreference = "Continue"

# -----------------------------
# Function Definitions
# -----------------------------

function Log-Message {
    param (
        [Parameter(Mandatory = $true)]
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
        Log-Message "This script must be run as an Administrator. Please run PowerShell with elevated privileges." "ERROR"
        exit 1
    } else {
        Log-Message "Administrative privileges verified." "INFO"
    }
}

function Backup-RegistryKey {
    param (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$BackupPath
    )

    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        Log-Message "Registry path cannot be empty or null." "ERROR"
        exit 1
    }

    try {
        if (Test-Path -Path $RegistryPath) {
            reg export $RegistryPath $BackupPath /y | Out-Null
            Log-Message "Registry key '$RegistryPath' backed up to '$BackupPath'." "INFO"
        } else {
            Log-Message "Registry path '$RegistryPath' does not exist. No backup performed." "INFO"
        }
    } catch {
        Log-Message "Failed to backup registry key '$RegistryPath'. Error: $_" "ERROR"
        exit 1
    }
}

function Get-CurrentSetting {
    param (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$ValueName
    )

    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        Log-Message "Registry path cannot be empty or null." "ERROR"
        exit 1
    }

    try {
        if (Test-Path -Path $RegistryPath) {
            $currentValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
            return $currentValue.$ValueName
        } else {
            return $null
        }
    } catch {
        Log-Message "Failed to retrieve current setting. Error: $_" "ERROR"
        exit 1
    }
}

function Set-Setting {
    param (
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$ValueName,
        [Parameter(Mandatory = $true)][int]$DesiredValue
    )

    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        Log-Message "Registry path cannot be empty or null." "ERROR"
        exit 1
    }

    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            Log-Message "Registry path '$RegistryPath' does not exist. Creating the path..." "WARN"
            New-Item -Path $RegistryPath -Force | Out-Null
            Log-Message "Registry path '$RegistryPath' created successfully." "INFO"
        }

        $currentValue = Get-CurrentSetting -RegistryPath $RegistryPath -ValueName $ValueName
        if ($null -eq $currentValue) {
            Log-Message "Registry value '$ValueName' does not exist. Creating and setting it to '$DesiredValue'." "WARN"
            New-ItemProperty -Path $RegistryPath -Name $ValueName -Value $DesiredValue -PropertyType DWORD -Force | Out-Null
            Log-Message "Registry value '$ValueName' created and set to '$DesiredValue'." "INFO"
        } elseif ($currentValue -ne $DesiredValue) {
            Log-Message "Updating '$ValueName' from '$currentValue' to '$DesiredValue'." "INFO"
            Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $DesiredValue -Force
            Log-Message "'$ValueName' updated to '$DesiredValue'." "INFO"
        } else {
            Log-Message "'$ValueName' is already set to '$DesiredValue'. No changes needed." "INFO"
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

# Define registry settings
$registryPath = "HKLM:\Software\Policies\Microsoft\Biometrics\FacialFeatures"
$valueName = "EnhancedAntiSpoofing"
$desiredValue = 1

# Backup registry settings
$backupPath = "$env:TEMP\FacialFeatures_EnhancedAntiSpoofing_Backup.reg"
Backup-RegistryKey -RegistryPath $registryPath -BackupPath $backupPath

# Get current setting
$currentSetting = Get-CurrentSetting -RegistryPath $registryPath -ValueName $valueName
if ($null -eq $currentSetting) {
    Log-Message "'$valueName' is not currently set." "INFO"
} else {
    Log-Message "Current value for '$valueName': $currentSetting" "INFO"
}

# Apply the desired setting
Set-Setting -RegistryPath $registryPath -ValueName $valueName -DesiredValue $desiredValue
