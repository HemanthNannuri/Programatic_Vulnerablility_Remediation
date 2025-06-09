# Define desired values (adjust if your STIG or policy requires different)
[int]$lockoutThreshold   = 3    # Number of invalid attempts before lockout
[int]$lockoutDuration    = 30   # How many minutes the account stays locked
[int]$lockoutWindow      = 30   # How many minutes before the bad logon counter resets

Write-Host "Current Account Policy Settings:"
net accounts

Write-Host "`nApplying STIG-compliant Account Lockout Settings..."

# Configure the Lockout Threshold
net accounts /lockoutthreshold:$lockoutThreshold

# Configure the Lockout Duration (minutes)
net accounts /lockoutduration:$lockoutDuration

# Configure the timeframe to reset invalid logon attempts (minutes)
net accounts /lockoutwindow:$lockoutWindow

Write-Host "`nAccount Lockout settings updated. Verifying changes..."

# Re-check the current account policy
net accounts | Out-Host
Write-Host "`nSTIG WN10-AC-000010 remediation script completed."
