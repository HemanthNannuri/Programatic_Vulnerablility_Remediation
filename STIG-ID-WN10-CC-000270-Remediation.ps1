

# Define the registry key and value for the "Do not allow passwords to be saved" policy
$RegistryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$RegistryValueName = "DisablePasswordSaving"
$RegistryValueData = 1  # 1 = Enabled (disables saving passwords)

# Check if the registry key exists, create it if not
if (-not (Test-Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -Force
}

# Set the "Do not allow passwords to be saved" policy to Enabled (1)
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'Do not allow passwords to be saved' policy has been enabled."
