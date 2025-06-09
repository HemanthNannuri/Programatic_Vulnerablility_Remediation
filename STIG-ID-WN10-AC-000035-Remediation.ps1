
Write-Host "Setting minimum password length to 14 characters..."

# Set minimum password length to 14
net accounts /minpwlen:14

Write-Host "`nValidating current account policy..."
net accounts | Out-Host
