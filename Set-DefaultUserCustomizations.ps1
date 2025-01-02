<#Use this Script as part of the Sysprep Process in buidling a standard set of defaults for all Users on a new PC
Can run this as a stand alone script or insert it as an app to be installed as part of the Install Apps phase of
https://github.com/rbalsleyMSFT/FFU

example:

Create a Scripts Folder under .\FFUDevelopment\Apps\

Then REM Out a description and place the script as a powershell command as follows:

REM Run DEfault User Customization Script
PowerShell -NoProfile -ExecutionPolicy Bypass -File "d:\scripts\Set-DefaultUserCustomizations.ps1"

Note: Always use 'd:\' as the root drive letter as it is teh ISO thats mounted during FFU build.

#>


<#Function Checks for the existence of the registery Path and will create if doesn't exisit#>
Function CheckPath {
    param ($keypath)
    
    # Check if the registry path exists
    if (-not (Test-Path $keypath)) {
        # Create the registry path if it doesn't exist
        New-Item -Path $keypath -Force | out-Null
        Write-Output "The registry path $keypath was created."
    }
}

# Define the registry path
$regPath = "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"

# Disabling Cloud App content from returning or reinstalling
Write-Host "Disabling Cloud Consumer Content" -ForegroundColor Yellow
CheckPath -keypath $regpath
Set-ItemProperty -Path $regPath -Name "DisableConsumerAccountStateContent" -Value 1
Set-ItemProperty -Path $regPath -Name "DisableCloudOptimizedContent" -Value 1
Set-ItemProperty -Path $regPath -Name "DisableWindowsConsumerFeatures" -Value 0

#Disable the remote Windows Store Push intstall
Write-Host "Disable Remote Push to Install MS Store" -ForegroundColor Yellow
$regPath = "HKLM:\Software\Policies\Microsoft\PushToInstall"
CheckPath -keypath $regpath
Set-ItemProperty -Path $regPath -Name "DisablePushToInstall" -Value 1 -Type DWord

#Disable the Animations when loggin new " Please wait, We're almost done..."
Write-Host "Disable First Time Logon Animations" -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
CheckPath -keypath $regpath
Set-ItemProperty -Path $regPath -Name EnableFirstLogonAnimation -Value 0 -type DWord

reg load HKU\Default C:\Users\Default\NTUSER.DAT
# Adding the Default User Hive registry key Tweaks..
#Disable the Start Menu from AUto launching on Startup
Write-Host  "Stop Start menu from opening on first logon" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f |Out-Null

#Write-Host "Disabling Chat Icon" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f

#disable Tips , Recommendations for new Apps
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f


#Remove Bing from Start Menu
Write-Host "Disabling bing in Start Menu:" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /f |Out-Null
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /v ShowRunAsDifferentUserInStart /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null
#Disable SPonsered Apps like Spotify or the Candy Crushes from coming back or silently installing
Write-Host "Disabling Sponsored Apps:" -ForegroundColor Yellow
reg.exe add "HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'OemPreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'PreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SilentInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'ContentDeliveryAllowed' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'FeatureManagementEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'OemPreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'PreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'PreInstalledAppsEverEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SilentInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SoftLandingEnabled' /t REG_DWORD /d 0 /f | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContentEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-310093Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-338388Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-338389Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-338393Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-353694Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContent-353696Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SubscribedContentEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v 'SystemPaneSuggestionsEnabled' /t REG_DWORD /d 0 /f  | Out-Null

reg.exe delete "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f  | Out-Null
#reg.exe delete "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps" /f  | Out-Null Doesnt appear to exisit any longer

#Hide "Learn more about this picture" from the desktop
Write-Host "Disabling about this picture" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 1 /f | Out-Host

#Show Search Icon only , Old Way below no longer works as first login resets the Full Seachbox
#reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Search" /v 'SearchBoxTaskbarMode' /t REG_DWORD /d 1 /f

##Remove Searchbar for all users new Way as of Win 11 23h2 thanks to SweJorgen and Woody over on GetRUbix Discord for pointing me to this. Create a run once to set the SearchTaskbarMode, recommend 0 or 1
Write-Host "Setting Searchbar Icon and Remvoing Widget" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\RunOnce" /f | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v 'RemoveSearch' /t REG_SZ /d "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Search /t REG_DWORD /v SearchboxTaskbarMode /d 1 /f" /f

#Disabling Edge Desktop SHortcut Creation on Update
Write-Host "Disabling Edge Shortcut Creation" -ForegroundColor Yellow
if (Test-Path "C:\Users\Public\Desktop\Microsoft Edge.lnk") { Remove-Item "C:\Users\Public\Desktop\Microsoft Edge.lnk" -Force }
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64 | Out-Null

#Disabling  Network Flyout for new networks found.
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f | Out-Null
reg unload HKU\Default

#Remove Widgets New Work around October 2024, Tested with Win 11 24H2
Write-Host "Disabling Widgets and Task Buttons" -ForegroundColor Yellow
copy-item (Get-Command reg).Source .\reg1.exe
.\reg1.exe load HKU\Default C:\Users\Default\NTUSER.DAT
.\reg1.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
.\reg1.exe unload HKU\Default
remove-item .\reg1.exe

#remove comment below to Debug
$inputChoice = Read-Host "Waiting for a key press so I can check the Reg adds above"
