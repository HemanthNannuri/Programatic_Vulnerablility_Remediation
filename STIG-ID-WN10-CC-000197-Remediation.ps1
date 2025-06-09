

# Define the registry key and value for "Turn off Microsoft consumer experiences"
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$RegistryValueName = "DisableWindowsConsumerFeatures"
$RegistryValueData = 1  # 1 = Enabled (turns off Microsoft consumer experiences)

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Turn off Microsoft consumer experiences" policy to Enabled
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Turn off Microsoft consumer experiences' policy has been enabled."
