# Enable verbose output
$VerbosePreference = "Continue"

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

# Function to verify administrative privileges
function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "This script must be run as an Administrator. Exiting." "ERROR"
        exit 1
    }
}

# Function to get current policy configuration
function Get-CurrentPolicy {
    param ([string]$PolicyName)
    try {
        Log-Message "Retrieving current policy settings for '$PolicyName'..." "INFO"
        $policyOutput = secedit /export /areas USER_RIGHTS /cfg "$env:TEMP\SecurityConfig.inf" | Out-Null
        $policyLines = Get-Content "$env:TEMP\SecurityConfig.inf"
        $policySetting = $policyLines | Where-Object { $_ -match "^$PolicyName\s*=" } | ForEach-Object { ($_ -split "=")[1].Trim() }
        Remove-Item "$env:TEMP\SecurityConfig.inf" -Force
        return $policySetting
    } catch {
        Log-Message "Failed to retrieve current policy configuration. Error: $_" "ERROR"
        exit 1
    }
}

# Function to set the policy
function Set-Policy {
    param (
        [string]$PolicyName,
        [string]$Accounts
    )
    try {
        Log-Message "Configuring policy '$PolicyName' to include: $Accounts..." "INFO"
        $tempInf = "$env:TEMP\UpdatedSecurityConfig.inf"
        $tempSdb = "$env:TEMP\Security.sdb"

        # Export current settings
        secedit /export /areas USER_RIGHTS /cfg $tempInf | Out-Null

        # Modify the policy in the INF file
        (Get-Content $tempInf) -replace "($PolicyName\s*=).*", "`$1 $Accounts" | Set-Content $tempInf

        # Apply the updated policy
        secedit /configure /db $tempSdb /cfg $tempInf /areas USER_RIGHTS | Out-Null

        # Clean up temporary files
        Remove-Item $tempInf, $tempSdb -Force
        Log-Message "Policy '$PolicyName' updated successfully." "INFO"
    } catch {
        Log-Message "Failed to update policy '$PolicyName'. Error: $_" "ERROR"
        exit 1
    }
}

# Function to verify the updated policy
function Verify-Policy {
    param (
        [string]$PolicyName,
        [string]$ExpectedAccounts
    )
    $currentPolicy = Get-CurrentPolicy -PolicyName $PolicyName
    if ($currentPolicy -eq $ExpectedAccounts) {
        Log-Message "Verification successful: '$PolicyName' is correctly set to '$ExpectedAccounts'." "INFO"
        return $true
    } else {
        Log-Message "Verification failed: '$PolicyName' is set to '$currentPolicy', expected '$ExpectedAccounts'." "ERROR"
        return $false
    }
}

# Main Script Execution
Check-AdminPrivileges

$PolicyName = "SeRestorePrivilege"  # Internal name for "Restore files and directories"
$Accounts = "*S-1-5-32-544"         # SID for the Administrators group

# Step 1: Retrieve current policy settings
$currentPolicy = Get-CurrentPolicy -PolicyName $PolicyName

if ($null -eq $currentPolicy) {
    Log-Message "'Restore files and directories' policy is not currently set." "WARN"
} else {
    Log-Message "Current 'Restore files and directories' policy: $currentPolicy" "INFO"
}

# Step 2: Set the policy
Set-Policy -PolicyName $PolicyName -Accounts $Accounts

# Step 3: Verify the updated policy
if (-not (Verify-Policy -PolicyName $PolicyName -ExpectedAccounts $Accounts)) {
    Log-Message "Failed to verify updated policy. Exiting." "ERROR"
    exit 1
}

Log-Message "Policy configuration process completed successfully." "INFO"
