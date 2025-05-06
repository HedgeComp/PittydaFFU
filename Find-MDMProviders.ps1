# Define the root registry path
$rootPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

Write-Host "Searching for ProviderID values under $rootPath..." -ForegroundColor Cyan

try {
    # Get all subkeys under the root path
    $subkeys = Get-ChildItem -Path $rootPath -ErrorAction Stop

    # Initialize a counter for ProviderID entries
    $providerIDCount = 0

    # Iterate through each subkey
    foreach ($subkey in $subkeys) {
        # Get the full path of the subkey
        $subkeyPath = $subkey.PSPath

        # Attempt to retrieve the ProviderID value
        $providerID = Get-ItemProperty -Path $subkeyPath -Name "ProviderID" -ErrorAction SilentlyContinue

        if ($null -ne $providerID) {
            $providerIDCount++

            # Write the found ProviderID, its path, and value
            Write-Host "`nProviderID Found:" -ForegroundColor Green
            Write-Host "Path: $subkeyPath" -ForegroundColor Yellow
            Write-Host "Value: $($providerID.ProviderID)" -ForegroundColor White
        }
    }

    if ($providerIDCount -eq 0) {
        Write-Host "`nNo ProviderID values found under $rootPath." -ForegroundColor Red
    } else {
        Write-Host "`nTotal ProviderID values found: $providerIDCount" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "An error occurred while searching for ProviderID values: $_"
}
