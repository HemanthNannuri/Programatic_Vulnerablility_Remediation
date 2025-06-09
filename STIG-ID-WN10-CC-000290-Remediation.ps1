

# Define the registry key and values for "Set client connection encryption level"
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$RegistryValueName = "MinEncryptionLevel"
$RegistryValueData = 3  # 3 = High Level encryption

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Set client connection encryption level" policy to Enabled and High Level (3)
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Set client connection encryption level' has been enabled and set to High Level."
