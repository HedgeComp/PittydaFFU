# This script attempts to force an enrollment into MS Intune on a Windows 11 Hybrid Joined machine.
# It does the following:
# 1. Checks the for the TenatInfo Key.'t exist will exit, as it may be stuck PENDING or not yet synced to Entra
# 2. Checks for the MdmEnrollmentUrl
# 3. Creates MdmEnrollmentUrls if missing
# 4. Tries to Run the deviceenroller.exe 

#Some Trouble Shooting Tips. 
#If the script exits with 1001, then your device may not be completly Hybrid ADjoined. Use dsregcmd /status to check AzureADjoin
#Also look to see if your Device is in a status of Pending in Entra.
#Exit 1002 means the key is missing for your Entra Tenant ID
#Exit code 1003 means the deviceenroller.exe had an issue running.
#exit code 1004 you weren't able to set the required Regkeys , so check your permissions.


Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Checking TenantInfo..."

$key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'

try {
    $keyinfo = Get-Item "HKLM:\$key"
    Write-Host "Tenant ID is found!"
}
catch {
    Write-Host "Tenant ID is not found!"
    exit 1001
}

# Extract the last part of the registry key name (Tenant ID)
$url = ($keyinfo.name).Split("\")[-1]
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

if (!(Test-Path $path)) {
    Write-Host "KEY $path not found!"
    exit 1002
}

$keysSet = $false
try {
    # Check if MdmEnrollmentUrl exists
    Get-ItemProperty -Path $path -Name MdmEnrollmentUrl
    Write-Host "MDM Enrollment registry key found."
    $keysSet = $true
}
catch {
    Write-Host "MDM Enrollment registry keys not found. Registering now..."
    # Create MDM Enrollment Properties
    New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force
    New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force
    New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force
    $keysSet = $true
}
finally {
    if ($keysSet) {
        try {
            Write-Host "Attempting MDM enrollment..."
            C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM
            Write-Host "Device is performing the MDM enrollment!"
            exit 0
        } catch {
            Write-Host "Failed to run deviceenroller.exe"
            exit 1003
        }
    } else {
        Write-Host "Required keys not set, skipping enrollment."
        exit 1004
    }
}

exit 0
