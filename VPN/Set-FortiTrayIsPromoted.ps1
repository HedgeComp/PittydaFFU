<#
.SYNOPSIS
  Searches subkeys of HKCU:\Control Panel\NotifyIconSettings and sets IsPromoted = 1
  if ExecutablePath contains "FortiTray.exe".

.DESCRIPTION
  This script is meant to be run under the user context. It loops through all subkeys
  of HKEY_CURRENT_USER\Control Panel\NotifyIconSettings, checks for the "ExecutablePath"
  value containing "FortiTray.exe", and sets a DWORD value "IsPromoted" = 1 in that subkey.

.EXAMPLE
  .\Set-FortiTrayIsPromoted.ps1

.NOTES
  Run in user context to properly access the user's HKCU registry.
#>

Write-Host "Starting registry check for FortiTray.exe under HKCU:\Control Panel\NotifyIconSettings..."

try {
    # Root registry path
    $rootPath = "HKCU:\Control Panel\NotifyIconSettings"

    # Get all subkeys under NotifyIconSettings
    $subkeys = Get-ChildItem -Path $rootPath -ErrorAction SilentlyContinue
    
    foreach ($subkey in $subkeys) {
        # Attempt to read "ExecutablePath" (REG_SZ) from the subkey
        $executablePath = (Get-ItemProperty -Path $subkey.PSPath -Name 'ExecutablePath' -ErrorAction SilentlyContinue).ExecutablePath
        
        if ($null -ne $executablePath) {
            # Check if it contains "FortiTray.exe"
            if ($executablePath -like '*FortiTray.exe*') {
                Write-Host "Found FortiTray.exe in subkey: $($subkey.PSChildName). Setting IsPromoted=1..."
                
                # Set or create the DWORD "IsPromoted" with value 1
                Set-ItemProperty -Path $subkey.PSPath -Name 'IsPromoted' -Value 1 -Type DWord -ErrorAction SilentlyContinue

                Write-Host "IsPromoted set successfully in subkey: $($subkey.PSChildName)"
            }
        }
    }
    
    Write-Host "Registry update complete."
}
catch {
    Write-Error "An error occurred while updating the registry. Details: $_"
    exit 1
}

