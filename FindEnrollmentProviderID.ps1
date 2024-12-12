# This script attempts to find the keys that contain a REG_SZ named ProviderID under the Microsoft Enrollments Registry Path
# It does the following:
# 1. Checks for the Enrollment Path
# 2. Searches all Subkeys for 'ProviderID'
# 3. Displays the names of all Subkeys and the Value of ProviderID



# Define the base registry path
$basePath = "HKLM:\Software\Microsoft\Enrollments"

# Check if the key exists
if (-not (Test-Path $basePath)) {
    Write-Host "The specified registry path does not exist: $basePath"
    exit 1
}

# Get all the subkey paths under the base registry key
$subkeys = Get-ChildItem -Path $basePath

# Iterate through each subkey and look for ProviderID
foreach ($subkey in $subkeys) {
    # Attempt to get the ProviderID value
    $providerID = (Get-ItemProperty -Path $subkey.PSPath -Name ProviderID -ErrorAction SilentlyContinue).ProviderID

    if ($providerID) {
        Write-Host "Key Name: $($subkey.PSChildName)"
        Write-Host "ProviderID: $providerID"
        Write-Host "-----------------------------------"
    }
}
