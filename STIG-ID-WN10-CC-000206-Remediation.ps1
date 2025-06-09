<#
.SYNOPSIS
    This PowerShell script ensures that Windows Update must not obtain updates from other PCs on the internet. Windows 10 allows Windows Update to obtain updates from additional sources instead of Microsoft. In addition to Microsoft, updates can be obtained from and sent to PCs on the local network as well as on the internet. This is part of the Windows Update trusted process; however, to minimize outside exposure, obtaining updates from or sending to systems on the internet must be prevented.
.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-13
    Last Modified   : 2025-01-13
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-CC-000206

.TESTED ON
    Date(s) Tested  : 2025-01-13
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator. 
    Example syntax:
    PS C:\> .\STIG-ID-WN10-CC-000206-Remediation.ps1
#>

# -----------------------------
# Function Definitions
# -----------------------------

function Check-AdminPrivileges {
    <#
    .SYNOPSIS
        Checks if the script is running with administrative privileges.

    .RETURNS
        Boolean indicating administrative status.
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-DeliveryOptimizationMode {
    <#
    .SYNOPSIS
        Sets the Delivery Optimization download mode.

    .PARAMETER DesiredMode
        The desired mode for Delivery Optimization. Acceptable values are "Off" and "LocalPC".

    .EXAMPLE
        Set-DeliveryOptimizationMode -DesiredMode "Off"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Off", "LocalPC")]
        [string]$DesiredMode
    )

    # Define the registry path and value name
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
    $valueName = "DODownloadMode"

    # Define the desired DWORD value based on the mode
    switch ($DesiredMode) {
        "Off" {
            $desiredValue = 3
            Write-Output "Setting Delivery Optimization mode to 'Off' (Disabled)."
        }
        "LocalPC" {
            $desiredValue = 1
            Write-Output "Setting Delivery Optimization mode to 'PCs on my local network'."
        }
        default {
            Write-Error "Invalid mode selected. Please choose 'Off' or 'LocalPC'."
            exit 1
        }
    }

    try {
        # Check if the registry path exists; if not, create it
        if (-not (Test-Path -Path $registryPath)) {
            Write-Output "Registry path '$registryPath' does not exist. Creating the path..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Output "Registry path '$registryPath' created successfully."
        } else {
            Write-Output "Registry path '$registryPath' exists."
        }

        # Check the current value of DODownloadMode
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue

        if ($null -eq $currentValue) {
            Write-Output "Registry value '$valueName' does not exist. Creating and setting it to $desiredValue."
            New-ItemProperty -Path $registryPath -Name $valueName -PropertyType DWORD -Value $desiredValue -Force | Out-Null
            Write-Output "Registry value '$valueName' created and set to $desiredValue."
        }
        elseif ($currentValue.$valueName -ne $desiredValue) {
            Write-Output "Current value of '$valueName' is $($currentValue.$valueName). Updating it to $desiredValue."
            Set-ItemProperty -Path $registryPath -Name $valueName -Value $desiredValue -Type DWORD -Force
            Write-Output "Registry value '$valueName' updated to $desiredValue."
        }
        else {
            Write-Output "Registry value '$valueName' is already set to $desiredValue. No changes needed."
        }

        Write-Output "Delivery Optimization mode configured successfully to '$DesiredMode'."

    } catch {
        Write-Error "An error occurred while configuring Delivery Optimization mode: $_.Exception.Message"
        exit 1
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Check for Administrative Privileges
if (-not (Check-AdminPrivileges)) {
    Write-Error "This script must be run as an Administrator. Please run PowerShell with elevated privileges."
    exit 1
}

# Prompt the user for the desired mode
$modeOptions = @{
    "1" = "Off"
    "2" = "PCs on my local network"
}

Write-Host "Choose how updates are delivered:" -ForegroundColor Cyan
foreach ($key in $modeOptions.Keys) {
    Write-Host "$key`: $($modeOptions[$key])"
}

$selection = Read-Host "Enter the number corresponding to your choice (1 or 2)"

switch ($selection) {
    "1" {
        $desiredMode = "Off"
    }
    "2" {
        $desiredMode = "LocalPC"
    }
    default {
        Write-Error "Invalid selection. Please run the script again and choose either 1 or 2."
        exit 1
    }
}

# Set the Delivery Optimization mode based on user input
Set-DeliveryOptimizationMode -DesiredMode $desiredMode

# Optional: Recommend a system reboot
Write-Output "A system reboot may be required for the changes to take full effect."
