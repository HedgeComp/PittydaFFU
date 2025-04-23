# Script to apply various Windows registry tweaks for HKLM and the Default User profile.
# Combines tweaks from Otto Pilot Braning Script and Set-DefaultUserCustomizations V1 , removes duplicates, and breaks down ContentDeliveryManager settings.

# Script to apply various Windows registry tweaks for HKLM and the Default User profile.
# Combines tweaks, removes duplicates, and breaks down ContentDeliveryManager settings.

#Requires -RunAsAdministrator

Function CheckPath {
    param ($keypath)
    # Check if the registry path exists
    if (-not (Test-Path $keypath)) {
        # Create the registry path if it doesn't exist
        Try {
            New-Item -Path $keypath -Force -ErrorAction Stop | Out-Null
            Write-Host "The registry path $keypath was created." -ForegroundColor Green
        } Catch {
            Write-Error "Failed to create registry path $keypath`: $_"
            # Optionally exit if creation is critical
            # exit 1
        }
    }
}

# --- HKLM Settings ---
Write-Host "Applying HKLM Registry Settings..." -ForegroundColor Cyan

# STEP 1: Disabling Cloud Consumer Content
Write-Host "[HKLM] Disabling Cloud Consumer Content" -ForegroundColor Yellow
$regPath = "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"
CheckPath -keypath $regPath
Set-ItemProperty -Path $regPath -Name "DisableConsumerAccountStateContent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath -Name "DisableCloudOptimizedContent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# STEP 2: Disable Remote Push to Install MS Store
Write-Host "[HKLM] Disable Remote Push to Install MS Store" -ForegroundColor Yellow
$regPath = "HKLM:\Software\Policies\Microsoft\PushToInstall"
CheckPath -keypath $regPath
Set-ItemProperty -Path $regPath -Name "DisablePushToInstall" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# STEP 3: Disable First Time Logon Animations
Write-Host "[HKLM] Disable First Time Logon Animations" -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
CheckPath -keypath $regPath
Set-ItemProperty -Path $regPath -Name "EnableFirstLogonAnimation" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# STEP 4: Exclude LNK and URL files from OneDrive Sync via GPO Key
Write-Host "[HKLM] Excluding .LNK & .URL files from OneDrive Sync via GPO Key" -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO"
CheckPath -keypath $regPath
Set-ItemProperty -Path $regPath -Name "*.lnk" -Value "*.lnk" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath -Name "*.url" -Value "*.url" -Type String -Force -ErrorAction SilentlyContinue

# STEP 5: Prevent Edge Desktop Shortcut Creation
Write-Host "[HKLM] Disabling Edge Shortcut Creation (Policy & Explorer Key)" -ForegroundColor Yellow
# Method 1: Via Edge Update Policy
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
CheckPath -keypath $regPath
Set-ItemProperty -Path $regPath -Name "CreateDesktopShortcutDefault" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
# Method 2: Via Explorer Setting
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
Set-ItemProperty -Path $regPath -Name "DisableEdgeDesktopShortcutCreation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
# Also remove existing public desktop shortcut if present
$PublicDesktopEdgeLink = "C:\Users\Public\Desktop\Microsoft Edge.lnk"
if (Test-Path $PublicDesktopEdgeLink) {
    Write-Host "   Removing existing Public Desktop Edge shortcut." -ForegroundColor Gray
    Remove-Item $PublicDesktopEdgeLink -Force -ErrorAction SilentlyContinue
}

# STEP 6: Disable Network Location Fly-out
Write-Host "[HKLM] Turning off network location fly-out" -ForegroundColor Yellow
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff"
CheckPath -keypath $regPath

# --- Default User Hive Settings (HKU\Default) ---
Write-Host "Applying Default User (HKU\Default) Registry Settings..." -ForegroundColor Cyan

# Load Default User Hive
$DefaultUserHivePath = "C:\Users\Default\NTUSER.DAT"
Write-Host "Loading Default User Hive: $DefaultUserHivePath" -ForegroundColor Gray
reg.exe load HKU\Default $DefaultUserHivePath | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to load Default User Hive. Cannot apply HKU\Default tweaks."
    exit 1
}

# Get the base path for Default User Content Delivery Manager for easier reference
$DefUserCDMPath = "HKU\Default\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
# Ensure the base ContentDeliveryManager key exists
reg.exe add $DefUserCDMPath /f | Out-Null

# STEP 7: Stop Start menu from opening on first logon
Write-Host "[Default User] Stop Start menu from opening on first logon" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f | Out-Null

# STEP 8: Disable Taskbar Chat (Meet Now) and Task View icons
Write-Host "[Default User] Disabling Taskbar Chat and Task View icons" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f | Out-Null
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f | Out-Null

# STEP 9: Disable Tips, Recommendations for new Apps in Start
Write-Host "[Default User] Disabling Start Menu Tips/Recommendations (Start_IrisRecommendations)" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f | Out-Null

# STEP 10: Set Left Start Menu Alignment
Write-Host "[Default User] Set Left Start Menu Alignment" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f | Out-Null

# STEP 11: Configure Explorer RunAs OtherUser)
Write-Host "[Default User] Disabling Bing suggestions & enabling 'Run as different user'" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /f | Out-Null # Ensure path exists
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /v ShowRunAsDifferentUserInStart /t REG_DWORD /d 1 /f | Out-Null
#reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null

# STEP 12: Disable Windows Spotlight Collection on Desktop
Write-Host "[Default User] Disabling Windows Spotlight Collection on Desktop via Policy" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\CloudContent" /f | Out-Null # Ensure path exists
reg.exe add "HKU\Default\Software\Policies\Microsoft\Windows\CloudContent" /v DisableSpotlightCollectionOnDesktop /t REG_DWORD /d 1 /f | Out-Null

# -- Content Delivery Manager Tweaks Start --

# STEP 13: Disable Preinstalled / OEM / Silently Installed Apps Features
Write-Host "[Default User] Disabling Preinstalled/OEM/Silent App Features (ContentDelivery)" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'OemPreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'PreInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'PreInstalledAppsEverEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'SilentInstalledAppsEnabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 14: Disable General Content Delivery & Feature Management
Write-Host "[Default User] Disabling General Content Delivery & Feature Management" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'ContentDeliveryAllowed' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'FeatureManagementEnabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 15: Disable Lock Screen Spotlight Overlay / "Like what you see?"
Write-Host "[Default User] Disabling Lock Screen Spotlight Overlay & Tips" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'RotatingLockScreenOverlayEnabled' /t REG_DWORD /d 0 /f | Out-Null
reg.exe add $DefUserCDMPath /v 'SubscribedContent-338387Enabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 16: Disable Windows Welcome Experience
Write-Host "[Default User] Disabling Windows Welcome Experience (ContentDelivery)" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'SubscribedContent-310093Enabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 17: Disable Ads for Apps in Start Menu
Write-Host "[Default User] Disabling Suggested Apps in Start Menu (ContentDelivery)" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'SubscribedContent-338388Enabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 18: Disable "Get tips, tricks, and suggestions as you use Windows"
Write-Host '[Default User] Disabling "Get tips, tricks, and suggestions..."' -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'SubscribedContent-338389Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'SoftLandingEnabled' /t REG_DWORD /d 0 /f | Out-Null

# STEP 19: Disable Suggested Content in Settings App
Write-Host "[Default User] Disabling Suggested Content in Settings App" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'SubscribedContent-338393Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'SubscribedContent-353694Enabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'SubscribedContent-353696Enabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 20: Disable General Subscribed Content & Taskbar Suggestions
Write-Host "[Default User] Disabling General Subscribed Content & Taskbar Suggestions" -ForegroundColor Yellow
reg.exe add $DefUserCDMPath /v 'SubscribedContentEnabled' /t REG_DWORD /d 0 /f  | Out-Null
reg.exe add $DefUserCDMPath /v 'SystemPaneSuggestionsEnabled' /t REG_DWORD /d 0 /f  | Out-Null

# STEP 21: Remove Content Delivery Subscriptions Key
Write-Host "[Default User] Removing Content Delivery Subscriptions key" -ForegroundColor Gray
reg.exe delete "$DefUserCDMPath\Subscriptions" /f | Out-Null

# -- Content Delivery Manager Tweaks End --

# STEP 22: Hide "Learn more about this picture" from the desktop context menu
Write-Host "[Default User] Disabling 'Learn more about this picture'" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 1 /f | Out-Null

# STEP 23: Set Search Bar to Icon Only via RunOnce
Write-Host "[Default User] Setting Searchbar Icon via RunOnce" -ForegroundColor Yellow
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\RunOnce" /f | Out-Null # Ensure path exists
$RunOnceCommand = 'reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Search /t REG_DWORD /v SearchboxTaskbarMode /d 1 /f'
reg.exe add "HKU\Default\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v 'SetSearchIconOnly' /t REG_SZ /d $RunOnceCommand /f | Out-Null

# Unload Default User Hive
Write-Host "Unloading Default User Hive" -ForegroundColor Gray
reg.exe unload HKU\Default | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to unload Default User Hive. It might be in use."
}

# --- Widget Removal Workaround (Requires separate hive load/unload) ---
# This needs to run after the main unload because it uses its own load/unload cycle.
Write-Host "Applying Widget removal workaround (TaskbarDa)..." -ForegroundColor Yellow
$regExePath = (Get-Command reg.exe).Source
$tempRegExe = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "reg1.exe" # Use Temp path

# Define paths and arguments
$loadArgs = "load HKU\Default `"$DefaultUserHivePath`""
$addArgs = 'add HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v "TaskbarDa" /t REG_DWORD /d 0 /f'
$unloadArgs = "unload HKU\Default"

Try {
    Copy-Item -Path $regExePath -Destination $tempRegExe -Force -ErrorAction Stop

    # Load Hive using copied reg.exe
    Write-Host "  Loading hive via $tempRegExe..." -ForegroundColor Gray
    Start-Process -FilePath $tempRegExe -ArgumentList $loadArgs -Wait -NoNewWindow -ErrorAction Stop
    # Add a small delay after loading, sometimes needed
    Start-Sleep -Seconds 1

    # Add TaskbarDa key using copied reg.exe
    Write-Host "  Adding TaskbarDa=0 via $tempRegExe..." -ForegroundColor Gray
    Start-Process -FilePath $tempRegExe -ArgumentList $addArgs -Wait -NoNewWindow -ErrorAction Stop

    # Unload Hive using copied reg.exe
    Write-Host "  Unloading hive via $tempRegExe..." -ForegroundColor Gray
    Start-Process -FilePath $tempRegExe -ArgumentList $unloadArgs -Wait -NoNewWindow -ErrorAction Stop

    Write-Host "  Widget removal workaround applied successfully." -ForegroundColor Green
} Catch {
    Write-Error "Widget removal workaround failed: $_"
} Finally {
    if (Test-Path $tempRegExe) {
        Write-Host "  Removing temporary $tempRegExe..." -ForegroundColor Gray
        Remove-Item $tempRegExe -Force -ErrorAction SilentlyContinue
    }
    # Verify unload, just in case
    if (Test-Path HKU:\Default) {
        Write-Warning "HKU\Default hive might still be loaded after workaround attempt."
        reg.exe unload HKU\Default | Out-Null
    }
}


Write-Host "Script finished applying registry tweaks." -ForegroundColor Green
