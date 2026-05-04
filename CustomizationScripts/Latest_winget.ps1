# 1. Setup Environment
$repo = "microsoft/winget-cli"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$tempDir = Join-Path $env:TEMP "WinGetDependencies"
$zipPath = Join-Path $tempDir "Dependencies.zip"
$wingetPath = Join-Path $tempDir "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$extractPath = Join-Path $tempDir "Extracted"
$tempDir
# Ensure a clean workspace
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

# 2. Identify and Download the Dependency Zip
$release = Invoke-RestMethod -Uri $apiUrl
$asset = $release.assets | Where-Object { $_.name -eq "DesktopAppInstaller_Dependencies.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Error "Could not find 'DesktopAppInstaller_Dependencies.zip' in the latest release."
    return
}

# Invoke the web request
$release = Invoke-RestMethod -Uri $apiUrl

# Get the tag name (e.g., v1.7.10861)
$latestVersion = $release.tag_name
Write-Host "Latest Version: $latestVersion"
Write-Host $wingetPath
Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

# 3. Extract Contents
Write-Host "Extracting dependencies..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# 4. Target Architecture and Installation
# We filter for the system's architecture (usually x64) to avoid unnecessary errors
$arch = $env:PROCESSOR_ARCHITECTURE # Returns 'AMD64' for x64 systems
if ($arch -eq "AMD64") { $arch = "x64" }

Write-Host "System Architecture detected: $arch" -ForegroundColor Yellow

# Find all Appx/Msix files, prioritizing the specific architecture folder if it exists
$filesToInstall = Get-ChildItem -Path $extractPath -Recurse -Include *.appx, *.msix, *.appxbundle, *.msixbundle | 
    Where-Object { $_.FullName -match $arch -or $_.FullName -notmatch "x86|arm|arm64" }

# 5. Execute Installation
foreach ($file in $filesToInstall) {
    Write-Host "Installing: $($file.Name)" -ForegroundColor Green
    try {
        # Using -ForceApplicationShutdown to ensure busy frameworks update correctly
        Add-AppxPackage -Path $file.FullName -ForceApplicationShutdown -ErrorAction Stop
    }
    catch {
        Write-Warning "Skipped or failed: $($file.Name). It may already be installed."
    }
}

Write-Host "Downloading Latest winget-cli release.."
Invoke-WebRequest "https://aka.ms/getwinget" -OutFile $wingetPath
Write-Host "Installing Latest Winget-cli"
Add-AppxPackage -path $wingetPath
$wingetVer = & "winget.exe" --version
Write-Host "Winget version is: $wingetVer"

# Clean up


Remove-Item $tempDir -Recurse -Force
Write-Host "Dependency installation attempt complete." -ForegroundColor Cyan
