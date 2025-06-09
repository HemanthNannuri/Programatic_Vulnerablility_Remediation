
# Define the registry key and value for "User Account Control: Admin Approval Mode for the Built-in Administrator account"
$RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "FilterAdministratorToken"
$RegistryValueData = 1  # 1 = Enabled (Admin Approval Mode enabled for Built-in Administrator account)

# Set the registry value to enable Admin Approval Mode for the Built-in Administrator account
Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value $RegistryValueData

Write-Host "'User Account Control: Admin Approval Mode for the Built-in Administrator account' has been enabled."
