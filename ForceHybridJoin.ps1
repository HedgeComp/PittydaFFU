# This script attempts to force a hybrid Azure AD join on a Windows 11 machine.
# It does the following:
# 1. Checks the current device registration status.
# 2. Forces the device to leave any existing registration state (if stuck).
# 3. Tries to re-join the device to Azure AD Hybrid Join.
# 4. Runs the Automatic-Device-Join scheduled task to finalize the process.
# 5. Verifies the join status at the end.

Write-Host "*****************************************************"
Write-Host "Starting Azure AD Hybrid Join Force Script"
Write-Host "*****************************************************`n"

Write-Host "Checking current device registration status..."
dsregcmd /status

Write-Host "`nAttempting to leave any current AAD device registration state..."
dsregcmd /leave
Write-Host "Left current device state. Waiting a few seconds..."
Start-Sleep -Seconds 5

Write-Host "`nAttempting to force hybrid join..."
# The /debug switch provides verbose output which can be helpful for troubleshooting
dsregcmd /debug /join
Write-Host "Join attempt triggered. Waiting a few seconds..."
Start-Sleep -Seconds 10

Write-Host "`nRunning the Automatic-Device-Join scheduled task to finalize..."
Schtasks /Run /TN "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"
Write-Host "Scheduled task triggered. Waiting for the task to complete..."
Start-Sleep -Seconds 30

Write-Host "`nChecking device registration status again..."
dsregcmd /status

Write-Host "`nIf the device is successfully hybrid joined, you should see TenantId and DeviceId under 'AzureAdJoined : YES'."
Write-Host "*****************************************************"
Write-Host "Script completed."
Write-Host "*****************************************************"
