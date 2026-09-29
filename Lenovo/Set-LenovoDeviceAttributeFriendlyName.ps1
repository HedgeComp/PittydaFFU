<#PSScriptInfo
.SYNOPSIS
   Retrieves Lenovo devices in MS Entra using the Microsoft Graph API and updates a specified extensionAttribute with a friendly name based on the model.

.DESCRIPTION
    This script connects to the Microsoft Graph API to query managed Lenovo devices.
    It retrieves each device's model, maps it to a friendly name using Lenovo's MTM reference data,
    and updates a specified extension attribute with the friendly name if it differs from the current value.
    The script provides a summary of updates made, skipped devices, and those that required no changes.   

 .EXAMPLE    
    Lenovo Model 21HQ0007US would set the Entra Device extensionAttribute1: ThinkPad X1 Yoga 8th Gen
    
.VERSION
    1.5

.AUTHOR
    Scott McDonnell
#>
#requires -Module Microsoft.Graph.Authentication
# NOTE: this script PATCHes /devices, which is a DIRECTORY object - that needs Device.ReadWrite.All.
# Directory.Read.All alone is read-only, and DeviceManagementManagedDevices.* is the Intune surface,
# which this script never calls.
Connect-MgGraph -Scopes Device.ReadWrite.All, Directory.Read.All

# Define constants
$endpoint = "https://graph.microsoft.com"
$version = "beta"
$resource = "devices"

$TargetAttribute = "extensionAttribute1" # Change this to your desired extensoionAttribute (extensionAttribute1 through 15)
$updatedCount = 0 #  track how many devices were updated
$skippedCount = 0 #  track how many models are missing from your mapping table
$failedCount = 0  #  track how many devices errored, so they are not miscounted as "no change"

$headers = @{
    "ConsistencyLevel" = "eventual"
}

# Query Lenovo devices using $search.
# Directory collections page at 100 items, so follow @odata.nextLink until it is gone -
# otherwise everything past the first page is silently never processed.
$managedDevices = [System.Collections.Generic.List[object]]::new()
$nextUri = "$($endpoint)/$($version)/$($resource)?`$search=""manufacturer:LENOVO"""

try
{
    while ($nextUri)
    {
        $page = Invoke-MgGraphRequest -Uri $nextUri -Method GET -Headers $headers
        foreach ($d in $page.value) { $managedDevices.Add($d) }
        $nextUri = $page.'@odata.nextLink'
    }
}
catch
{
    Write-Error "Failed to retrieve managed devices: $($_.Exception.Message)"
    return
}

<#
Build the MTM -> Friendly Name lookup from two Lenovo sources.

  PRIMARY  : allModels.json   - names formatted "Friendly Name (MTM1,MTM2,...)".
                                Better coverage and disambiguates variants
                                (e.g. 'ThinkPad P14s AMD' vs 'ThinkPad P14s').
  FALLBACK : bios.txt         - lines formatted "Name Type <mtms> = <MTM> = <code>".
                                Still carries some models the JSON omits.

Neither source is complete on its own, so the JSON is consulted first and
bios.txt fills the gaps. Original bios.txt reference:
https://github.com/damienvanrobaeys/Lenovo_Models_Reference/blob/main/MTM_to_FriendlyName.ps1
#>
$JsonURL = "https://download.lenovo.com/bsco/public/allModels.json"
$BiosURL = "https://download.lenovo.com/luc/bios.txt#"

# PowerShell's @{} is case-insensitive, so MTM casing from Entra does not matter.
$JsonMtmMap = @{}
$BiosMtmMap = @{}

try
{
    $allModels = (Invoke-WebRequest -Uri $JsonURL -UseBasicParsing).Content | ConvertFrom-Json
    foreach ($entry in $allModels)
    {
        if ($entry.name -match '^(?<n>.+?)\s*\((?<m>[A-Za-z0-9]{4}(?:\s*,\s*[A-Za-z0-9]{4})*)\)\s*$')
        {
            $friendly = $Matches['n'].Trim()
            foreach ($mtm in ($Matches['m'] -split ','))
            {
                $key = $mtm.Trim()
                if (-not $JsonMtmMap.ContainsKey($key)) { $JsonMtmMap[$key] = $friendly }
            }
        }
    }
    Write-Host "Loaded $($JsonMtmMap.Count) MTMs from allModels.json" -ForegroundColor DarkGray
}
catch
{
    Write-Warning "Could not load allModels.json: $($_.Exception.Message)"
}

try
{
    foreach ($line in ((Invoke-WebRequest -Uri $BiosURL -UseBasicParsing).Content -split "`r`n"))
    {
        # Split on '=' so the MTM is matched exactly against the middle field,
        # rather than by a substring scan that can hit the wrong line.
        $parts = $line -split '='
        if ($parts.Count -ge 2)
        {
            $key = $parts[1].Trim()
            if ($key -and -not $BiosMtmMap.ContainsKey($key))
            {
                $BiosMtmMap[$key] = ($parts[0].Trim() -split '\s+Type\s+')[0].Trim()
            }
        }
    }
    Write-Host "Loaded $($BiosMtmMap.Count) MTMs from bios.txt (fallback)" -ForegroundColor DarkGray
}
catch
{
    Write-Warning "Could not load bios.txt fallback: $($_.Exception.Message)"
}

if ($JsonMtmMap.Count -eq 0 -and $BiosMtmMap.Count -eq 0)
{
    Write-Error "No Lenovo model reference data could be loaded from either source. Exiting."
    return
}


$totalDevices = $managedDevices.Count

foreach ($device in $managedDevices)
{   
    $modelString = [string]$device.model
    if ([string]::IsNullOrWhiteSpace($modelString))
    {
        Write-Host "Skipping: device has no model value (Device: $($device.DisplayName))" -ForegroundColor Cyan
        $skippedCount++
        continue
    }

    $Mtm = if ($modelString.Length -ge 4) { $modelString.Substring(0, 4).Trim() } else { $modelString.Trim() }

    # Look up the friendly name: JSON first, then the bios.txt fallback.
    [string]$FamilyName = ''
    [string]$NameSource = ''
    if ($JsonMtmMap.ContainsKey($Mtm))
    {
        $FamilyName = $JsonMtmMap[$Mtm]
        $NameSource = 'JSON'
    }
    elseif ($BiosMtmMap.ContainsKey($Mtm))
    {
        $FamilyName = $BiosMtmMap[$Mtm]
        $NameSource = 'bios.txt'
    }

# If we didn't find a Friendly Name, skip the Graph calls entirely
if ([string]::IsNullOrWhiteSpace($FamilyName)) 
{
    Write-Host "Skipping: No Friendly Name found for MTM '$Mtm' (Device: $($device.DisplayName))" -ForegroundColor Cyan
    $skippedCount++ 
    continue         # Moves immediately to the next device in the foreach loop
}

# If the code reaches this point, we know $FamilyName Has a value.
Write-Host "Processing: $($device.DisplayName) | Family: $FamilyName | MTM: $Mtm | Source: $NameSource"


    # Retrieve Device's current extensionAttributes values
    $deviceDetailsRequest = @{
        Uri    = "$($endpoint)/$($version)/$($resource)/$($device.id)?`$select=extensionAttributes"
        Method = "GET"
    }

    try
    {
        $deviceDetails = Invoke-MgGraphRequest @deviceDetailsRequest
         $currentValue = $deviceDetails.extensionAttributes.$TargetAttribute
    }
    catch
    {
        Write-Error "Failed to retrieve device details for device ID $($device.id): $($_.Exception.Message)"
        $failedCount++
        continue
    }


    
if ($currentValue -ne $FamilyName) 
{
    
   $updateBody = @{ 
        extensionAttributes = @{ 
            $TargetAttribute = $FamilyName 
        } 
    }

    $updateRequest = @{
        Uri    = "$($endpoint)/$($version)/$($resource)/$($device.id)"
        Method = "PATCH"
        Body   = ($updateBody | ConvertTo-Json -Compress)
    }

    try 
    {
        # Determine the log message based on whether it was empty or different
        $logAction = if ([string]::IsNullOrEmpty($currentValue)) { "to '$FamilyName'" } else { "from '$currentValue' to '$FamilyName'" }

        # Perform the actual update once
        Invoke-MgGraphRequest @updateRequest -ErrorAction Stop
        
        Write-Host "Updated $TargetAttribute for $($device.DisplayName) (ID: $($device.id)) $logAction" -ForegroundColor Green
        $updatedCount++
    }
    catch 
    {
        Write-Error "Failed to update $TargetAttribute for device ID $($device.id): $($_.Exception.Message)"
        $failedCount++
    }
}
else 
{
    # This is the "Pre-Check" result
    Write-Host "No update needed for device $($device.DisplayName) - $TargetAttribute already set to '$FamilyName'" -ForegroundColor Yellow
}

}

Write-Host ("`n" + ("-" * 30))
Write-Host "Update Summary"
Write-Host "Total Lenovo devices found: $totalDevices"
Write-Host "Successfully updated: $updatedCount" -ForegroundColor Green
Write-Host "Skipped (No mapping found): $skippedCount" -ForegroundColor Cyan
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host "No change needed: $($totalDevices - $updatedCount - $skippedCount - $failedCount)" -ForegroundColor Yellow
Write-Host ("-" * 30)
