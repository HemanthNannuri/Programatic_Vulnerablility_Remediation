<#
.SYNOPSIS
    This PowerShell script ensures that the required legal notice must be configured to display before console logon. Failure to display the logon banner prior to a logon attempt will negate legal proceedings resulting from unauthorized access to system resources.

.NOTES
    Author          : Carlton Hurd
    LinkedIn        : linkedin.com/in/carlton-hurd-6069a5120/
    GitHub          : github.com/churd-git
    Date Created    : 2025-01-13
    Last Modified   : 2025-01-13
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN10-SO-000075

.TESTED ON
    Date(s) Tested  : 2025-01-013
    Tested By       : Carlton Hurd
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
    Please download the script and execute as administrator.
    Example syntax:
    PS C:\> .\STIG-ID-WN10-SO-000075-Remediation.ps1 
#>

# -----------------------------
# Function Definitions
# -----------------------------

function Write-Log {
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

function Check-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "This script must be run as an Administrator. Please run PowerShell with elevated privileges." "ERROR"
        exit 1
    } else {
        Write-Log "Administrative privileges verified." "INFO"
    }
}

function Set-InteractiveLogonMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$MessageText,

        [Parameter(Mandatory = $false)]
        [string]$MessageCaption
    )

    # Define the registry path and value names
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $textValueName = "LegalNoticeText"
    $captionValueName = "LegalNoticeCaption"

    try {
        # Check if the registry path exists; if not, create it
        if (-not (Test-Path -Path $registryPath)) {
            Write-Log "Registry path '$registryPath' does not exist. Creating the path..." "WARN"
            New-Item -Path $registryPath -Force | Out-Null
            Write-Log "Registry path '$registryPath' created successfully." "INFO"
        } else {
            Write-Log "Registry path '$registryPath' exists." "INFO"
        }

        # Set the LegalNoticeText value
        if (-not (Get-ItemProperty -Path $registryPath -Name $textValueName -ErrorAction SilentlyContinue)) {
            Write-Log "Registry value '$textValueName' does not exist. Creating and setting it..." "WARN"
            New-ItemProperty -Path $registryPath -Name $textValueName -Value $MessageText -PropertyType String -Force | Out-Null
            Write-Log "Registry value '$textValueName' created and set successfully." "INFO"
        } else {
            Write-Log "Setting registry value '$textValueName' to the specified message." "INFO"
            Set-ItemProperty -Path $registryPath -Name $textValueName -Value $MessageText -Force
            Write-Log "Registry value '$textValueName' set successfully." "INFO"
        }

        # If a caption is provided, set the LegalNoticeCaption value
        if ($MessageCaption) {
            if (-not (Get-ItemProperty -Path $registryPath -Name $captionValueName -ErrorAction SilentlyContinue)) {
                Write-Log "Registry value '$captionValueName' does not exist. Creating and setting it..." "WARN"
                New-ItemProperty -Path $registryPath -Name $captionValueName -Value $MessageCaption -PropertyType String -Force | Out-Null
                Write-Log "Registry value '$captionValueName' created and set successfully." "INFO"
            } else {
                Write-Log "Setting registry value '$captionValueName' to the specified caption." "INFO"
                Set-ItemProperty -Path $registryPath -Name $captionValueName -Value $MessageCaption -Force
                Write-Log "Registry value '$captionValueName' set successfully." "INFO"
            }
        }

        Write-Log "Interactive logon message configured successfully." "INFO"

    } catch {
        Write-Log "An error occurred while configuring the interactive logon message: $_" "ERROR"
        exit 1
    }
}

function Verify-RegistrySettings {
    param (
        [string]$Path,
        [string]$TextName,
        [string]$ExpectedText,
        [string]$CaptionName,
        [string]$ExpectedCaption
    )

    try {
        $currentText = Get-ItemProperty -Path $Path -Name $TextName -ErrorAction SilentlyContinue
        $currentCaption = Get-ItemProperty -Path $Path -Name $CaptionName -ErrorAction SilentlyContinue

        $textMatch = ($currentText.$TextName -eq $ExpectedText)
        $captionMatch = $true

        if ($ExpectedCaption) {
            $captionMatch = ($currentCaption.$CaptionName -eq $ExpectedCaption)
        }

        if ($textMatch -and $captionMatch) {
            Write-Log "Verification successful: Registry settings are correctly applied." "INFO"
            return $true
        } else {
            Write-Log "Verification failed: Registry settings do not match expected values." "ERROR"
            return $false
        }

    } catch {
        Write-Log "An error occurred during verification: $_" "ERROR"
        return $false
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Check for Administrative Privileges
Check-AdminPrivileges

# Step 2: Define the message text and caption
# Use a here-string to handle multi-line text for LegalNoticeText
$messageText = @"
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only. By using this IS (which includes any device attached to this IS), you consent to the following conditions:
-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.
-At any time, the USG may inspect and seize data stored on this IS.
-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.
-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.
-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
"@

$messageCaption = "Security Notice"

Write-Log "Starting configuration of 'Interactive logon: Message text for users attempting to log on' policy." "INFO"

# Step 3: Set the interactive logon message
Set-InteractiveLogonMessage -MessageText $messageText -MessageCaption $messageCaption

# Step 4: Verify the registry settings
$verification = Verify-RegistrySettings -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -TextName "LegalNoticeText" -ExpectedText $messageText `
    -CaptionName "LegalNoticeCaption" -ExpectedCaption $messageCaption

if (-not $verification) {
    Write-Log "Registry settings verification failed. Please check the script and try again." "ERROR"
    exit 1
}

# Step 5: Prompt for system reboot or logoff
Write-Log "A system reboot or user logoff may be required for the changes to take full effect." "INFO"
$rebootChoice = Read-Host "Do you want to restart the system now? (Y/N)"

if ($rebootChoice -eq 'Y' -or $rebootChoice -eq 'y') {
    Write-Log "Restarting the system..." "INFO"
    Restart-Computer -Force
} else {
    Write-Log "Please remember to restart the system later to apply the changes." "WARN"
}

Write-Log "Policy configuration process completed." "INFO"

# -----------------------------
# End of Script
# -----------------------------

