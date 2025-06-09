

# -----------------------------
# Configuration Parameters
# -----------------------------

# Define the transcript output directory
# Replace the path below with your Central Log Server path or another secure location
$transcriptOutputDir = "\\CentralLogServer\PowerShellTranscripts"

# Define the registry path and values for PowerShell Transcription
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
$enableTranscriptingName = "EnableTranscripting"
$enableTranscriptingValue = 1  # 1 = Enabled, 0 = Disabled

$outputDirectoryName = "OutputDirectory"
$outputDirectoryValue = $transcriptOutputDir

$includeInvocationHeaderName = "IncludeInvocationHeader"
$includeInvocationHeaderValue = 1  # 1 = Enabled, 0 = Disabled

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

# Function to create the transcript output directory with restricted permissions
function Create-TranscriptDirectory {
    param (
        [string]$DirectoryPath
    )

    try {
        # Check if the directory is a UNC path
        if ($DirectoryPath -like "\\*") {
            # Verify network path accessibility
            if (-not (Test-Path -Path $DirectoryPath)) {
                Log-Message "Transcript output directory '$DirectoryPath' does not exist or is inaccessible." "ERROR"
                Log-Message "Please ensure the network path is correct and accessible, and that you have the necessary permissions." "ERROR"
                exit 1
            } else {
                Log-Message "Transcript output directory '$DirectoryPath' is accessible." "INFO"
            }

            # Attempt to set permissions
            Log-Message "Setting permissions on '$DirectoryPath' to restrict user access..." "INFO"
            
            # Define the security descriptor
            $acl = Get-Acl -Path $DirectoryPath

            # Define the rule: Allow Administrators full control
            $adminGroup = [System.Security.Principal.NTAccount]"BUILTIN\Administrators"
            $ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($ruleAdmin)

            # Define the rule: Allow SYSTEM full control
            $systemAccount = [System.Security.Principal.NTAccount]"NT AUTHORITY\SYSTEM"
            $ruleSystem = New-Object System.Security.AccessControl.FileSystemAccessRule($systemAccount, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($ruleSystem)

            # Remove existing rules except for Administrators and SYSTEM
            $acl.Access | Where-Object {
                $_.IdentityReference -notmatch "BUILTIN\\Administrators" -and
                $_.IdentityReference -notmatch "NT AUTHORITY\\SYSTEM"
            } | ForEach-Object {
                $acl.RemoveAccessRule($_)
            }

            # Apply the new ACL
            Set-Acl -Path $DirectoryPath -AclObject $acl
            Log-Message "Permissions set successfully on '$DirectoryPath'." "INFO"

        } else {
            # Local directory handling
            if (-not (Test-Path -Path $DirectoryPath)) {
                Log-Message "Transcript output directory '$DirectoryPath' does not exist. Creating..." "WARN"
                New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
                Log-Message "Transcript output directory '$DirectoryPath' created successfully." "INFO"
            } else {
                Log-Message "Transcript output directory '$DirectoryPath' already exists." "INFO"
            }

            # Set permissions to restrict user access
            Log-Message "Setting permissions on '$DirectoryPath' to restrict user access..." "INFO"
            
            # Define the security descriptor
            $acl = Get-Acl -Path $DirectoryPath

            # Define the rule: Allow Administrators full control
            $adminGroup = [System.Security.Principal.NTAccount]"BUILTIN\Administrators"
            $ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($ruleAdmin)

            # Define the rule: Allow SYSTEM full control
            $systemAccount = [System.Security.Principal.NTAccount]"NT AUTHORITY\SYSTEM"
            $ruleSystem = New-Object System.Security.AccessControl.FileSystemAccessRule($systemAccount, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($ruleSystem)

            # Remove existing rules except for Administrators and SYSTEM
            $acl.Access | Where-Object {
                $_.IdentityReference -notmatch "BUILTIN\\Administrators" -and
                $_.IdentityReference -notmatch "NT AUTHORITY\\SYSTEM"
            } | ForEach-Object {
                $acl.RemoveAccessRule($_)
            }

            # Apply the new ACL
            Set-Acl -Path $DirectoryPath -AclObject $acl
            Log-Message "Permissions set successfully on '$DirectoryPath'." "INFO"
        }
    } catch {
        Log-Message "Failed to create or set permissions on directory '$DirectoryPath'. Error: $_" "ERROR"
        exit 1
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for administrative privileges
Check-AdminPrivileges

# Step 2: Check PowerShell bitness
Check-PowerShellBitness

# Step 3: Define registry settings
Log-Message "Starting configuration of 'Turn on PowerShell Transcription' policy." "INFO"

# Step 4: Enable PowerShell Transcription
Set-RegistryValue -Path $registryPath -Name $enableTranscriptingName -Value $enableTranscriptingValue -Type "DWORD"

# Step 5: Specify Transcript Output Directory
Set-RegistryValue -Path $registryPath -Name $outputDirectoryName -Value $outputDirectoryValue -Type "String"

# Step 6: Enable IncludeInvocationHeader (optional, for detailed logs)
Set-RegistryValue -Path $registryPath -Name $includeInvocationHeaderName -Value $includeInvocationHeaderValue -Type "DWORD"

# Step 7: Verify registry settings
$verifyTranscripting = Verify-RegistrySetting -Path $registryPath -Name $enableTranscriptingName -ExpectedValue $enableTranscriptingValue
$verifyOutputDir = Verify-RegistrySetting -Path $registryPath -Name $outputDirectoryName -ExpectedValue $outputDirectoryValue
$verifyIncludeHeader = Verify-RegistrySetting -Path $registryPath -Name $includeInvocationHeaderName -ExpectedValue $includeInvocationHeaderValue

if ($verifyTranscripting -and $verifyOutputDir -and $verifyIncludeHeader) {
    Log-Message "All registry settings have been configured correctly." "INFO"
} else {
    Log-Message "One or more registry settings failed to configure correctly." "ERROR"
    exit 1
}

# Step 8: Create the Transcript Output Directory with restricted permissions
Create-TranscriptDirectory -DirectoryPath $outputDirectoryValue

# Step 9: Optionally, force Group Policy update
try {
    Log-Message "Forcing Group Policy update..." "INFO"
    gpupdate /force | Out-Null
    Log-Message "Group Policy update completed." "INFO"
} catch {
    Log-Message "Failed to update Group Policy: $_" "WARN"
}

# Step 10: Prompt for system reboot or user logoff
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
