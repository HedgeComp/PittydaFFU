#credit for this script goes to Albert-Jan Scholt at cloudappoe.nl
# found the option to set the icon of the profile by chaning 
# avater_index value after much trial and error
# may create icon index map in next version
# set local username as the ProfileName for Edge Profile 

Param(
    [Parameter(Mandatory = $false)]
    [string]
    $customerName,
    [Parameter(Mandatory = $false)]
    [bool]
    $createBackup = $true
)

$customerName = $env:USERNAME
Write-Output "Creating Edge profile for $customerName"


$profilePath = "profile-" + $customerName.replace(' ', '-')
$proc = Start-Process -FilePath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "--start-minimized --profile-directory=$profilePath --no-first-run --no-default-browser-check --flag-switches-begin --flag-switches-end --site-per-process" -PassThru  -WindowStyle Minimized

Write-Output "Profile $customerName created, wait 15 seconds before closing Edge"

Start-Sleep -Seconds 15 #it takes roughly 15 seconds to prepare the profile and write all files to disk.
Stop-Process -Name "msedge"

# Edit profile name
$localStateFile = "$Env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
Set-Content -Path "$Env:LOCALAPPDATA\Microsoft\Edge\User Data\EdgeProfile.ps1.tag" -Value "Installed"

if ($createBackup) {
    $localStateBackUp = "$Env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State Backup"
    Copy-Item $localStateFile -Destination $localStateBackUp
}

$state = Get-Content -Raw $localStateFile
$json = $state | ConvertFrom-Json

#$json | ConvertTo-Json -Depth 10 | Set-Content -Path "C:\Temp\preferences.json" -Encoding utf8

$edgeProfile = $json.profile.info_cache.$profilePath

Write-Output "Found profile $profilePath"
Write-Output "Old profile name: $($edgeProfile.name)"
write-output $edgeProfile.avatar_icon

$edgeProfile.name = $customerName
$edgeProfile.avatar_icon = "chrome://theme/IDR_PROFILE_AVATAR_29"

Write-Output "Write profile name to local state: $($edgeProfile.name)"

# Only uncomment the next line if you know what you're doing!!
$json | ConvertTo-Json -Compress -Depth 100 | Out-File $localStateFile -Encoding UTF8

Write-Output "Write profile name to registry: $($edgeProfile.name)"
Push-Location
Set-Location HKCU:\Software\Microsoft\Edge\Profiles\$profilePath
Set-ItemProperty . ShortcutName "$customerName"
Pop-Location

$preferenceSettings = "$Env:LOCALAPPDATA\Microsoft\Edge\User Data\$profilePath\Preferences"

if ($createBackup) {
    $preferenceSettingsBackup = "$Env:LOCALAPPDATA\Microsoft\Edge\User Data\$profilePath\Preferences Backup"
    Copy-Item $preferenceSettings -Destination $preferenceSettingsBackup
}

$preferences = Get-Content -Raw $preferenceSettings
$preferenceJson = $preferences | ConvertFrom-Json
#$preferenceJson | ConvertTo-Json -Depth 10 | Set-Content -Path "C:\Temp\preferences.json" -Encoding utf8


if ($null -eq $preferenceJson.browser.show_hub_apps_tower) {
    Write-Output "show_hub_apps_tower is not set and turned on by default, lets disable it"

    $preferenceJson.browser | add-member -Name "show_hub_apps_tower" -value $false -MemberType NoteProperty
}
else {
    $sideBarToggle = $preferenceJson.browser.show_hub_apps_tower
    Write-Output "show_hub_apps_tower is set to: $sideBarToggle lets make it false"
    $preferenceJson.browser.show_hub_apps_tower = $false #disable side bar
}

if ($null -eq $preferenceJson.browser.show_hub_apps_tower_pinned) {
    Write-Output "show_hub_apps_tower_pinned is not set and turned on by default, lets disable it"
    $preferenceJson.browser | add-member -Name "show_hub_apps_tower_pinned" -value $false -MemberType NoteProperty
}
else {
    $sideBarToggle = $preferenceJson.browser.show_hub_apps_tower_pinned
    Write-Output "show_hub_apps_tower_pinned is set to: $sideBarToggle lets make it false"
    $preferenceJson.browser.show_hub_apps_tower_pinned = $false #disable side bar
}

if ($null -eq $preferenceJson.browser.show_toolbar_learning_toolkit_button) {
    Write-Output "show_toolbar_learning_toolkit_button is not set and turned on by default, lets disable it"
    $preferenceJson.browser | add-member -Name "show_toolbar_learning_toolkit_button" -value $false -MemberType NoteProperty
}
else {
    $sideBarToggle = $preferenceJson.browser.show_toolbar_learning_toolkit_button
    Write-Output "show_toolbar_learning_toolkit_button is set to: $sideBarToggle lets make it false"
    $preferenceJson.browser.show_toolbar_learning_toolkit_button = $false #disable side bar
}

if ($null -eq $preferenceJson.edge) {
    Write-Output "Set vertical tabs"
    $blockvalue = @"
    {
        "perf_center":{
           "performance_detector":false
        },
        "vertical_tabs":{
           "collapsed":true,
           "feedback_do_not_show":true,
           "first_opened2":true,
           "opened":true
        }
     }
"@

    $preferenceJson | add-member -Name "edge" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty
}
else {
    Write-Output "Set vertical tabs (force overwrite)"

    $blockvalue = @"
    {
        "perf_center":{
           "performance_detector":false
        },
        "vertical_tabs":{
           "collapsed":true,
           "feedback_do_not_show":true,
           "first_opened2":true,
           "opened":true
        }
     }
"@

    $preferenceJson | add-member -Name "edge" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty -Force
}

if ($null -eq $preferenceJson.local_browser_data_share.enabled) {
    Write-Output "Disable data share between profiles"
    $blockvalue = @"
    {
        "enabled": false,
        "index_last_cleaned_time": "0"
    }
"@

    $preferenceJson | add-member -Name "local_browser_data_share" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty
}
else {
    Write-Output "Disable data share between profiles"

    $preferenceJson.local_browser_data_share.enabled = $false; #disable sharing data between profiles
}

if ($null -eq $preferenceJson.edge_share) {
    Write-Output "Disable enhanced copy paste"
    $blockvalue = @"
    {
        "enhanced_copy_paste": {
            "default_url_format": 1,
            "enable_secondary_ecp": true
        }
    }
"@

    $preferenceJson | add-member -Name "edge_share" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty
}
else {
    Write-Output "Disable enhanced copy paste"

    $preferenceJson.edge_share.enhanced_copy_paste.default_url_format = 1; #disable enhanced copy paste
}

if ($null -eq $preferenceJson.ntp) {
    Write-Output "Disable start page"

    $blockvalue = @"
    {
      "background_image_type":"imageAndVideo",
      "hide_default_top_sites":false,
      "layout_mode":3,
      "news_feed_display":"off",
      "num_personal_suggestions":1,
      "prerender_contents_height":823,
      "prerender_contents_width":1185,
      "quick_links_options":0
   }
"@

    $preferenceJson | add-member -Name "ntp" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty
}
else {
    Write-Output "Disable start page (force overwrite)"

    $blockvalue = @"
    {
      "background_image_type":"imageAndVideo",
      "hide_default_top_sites":false,
      "layout_mode":3,
      "news_feed_display":"off",
      "num_personal_suggestions":1,
      "prerender_contents_height":823,
      "prerender_contents_width":1185,
      "quick_links_options":0
   }
"@

    $preferenceJson | add-member -Name "ntp" -value (Convertfrom-Json $blockvalue) -MemberType NoteProperty -Force
}

#$preferenceJson.profile.avatar_index = 41
Write-Output "Write new settings to $($profilePath)"

# Only uncomment the next line if you know what you're doing!!
$preferenceJson | ConvertTo-Json -Compress -Depth 100 | Out-File $preferenceSettings -Encoding UTF8

Write-Output "Done, you can start browsing with your new profile"
