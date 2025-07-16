 Write-Debug "Visual C++ Redistributable is not installed.`n`n"

            # Define the URL and temporary file path for the download
            $VCppRedistributable_Url = "https://aka.ms/vs/17/release/vc_redist.${arch}.exe"
            $VCppRedistributable_Path = New-TemporaryFile2
            Write-Output "Downloading Visual C++ Redistributable..."
            Write-Debug "Downloading Visual C++ Redistributable from $VCppRedistributable_Url to $VCppRedistributable_Path`n`n"
            Invoke-WebRequest -Uri $VCppRedistributable_Url -OutFile $VCppRedistributable_Path

            # Rename file
            $VCppRedistributableExe_Path = $VCppRedistributable_Path + ".exe"
            Rename-Item -Path $VCppRedistributable_Path -NewName $VCppRedistributableExe_Path

            # Install Visual C++ Redistributable
            Write-Output "Installing Visual C++ Redistributable..."
            Write-Debug "Installing Visual C++ Redistributable from $VCppRedistributableExe_Path`n`n"
            Start-Process -FilePath $VCppRedistributableExe_Path -ArgumentList "/install", "/quiet", "/norestart" -Wait

            Write-Debug "Removing temporary file..."
            TryRemove $VCppRedistributableExe_Path





$JBNWinGetResolve = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
$JBNWinGetPathExe = $JBNWinGetResolve[-1].Path

$JBNWinGetPath = Split-Path -Path $JBNWinGetPathExe -Parent
set-location $JBNWinGetPath


# 1. Query GitHub for the latest winget release and pick the .msixbundle URL
$apiUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
$msixUrl = (Invoke-RestMethod -Uri $apiUrl).assets.browser_download_url |
          Where-Object { $_.EndsWith('.msixbundle') }

# 2. Download the bundle to your working directory
Invoke-WebRequest -Uri $msixUrl -OutFile '.\Microsoft.DesktopAppInstaller.msixbundle' -UseBasicParsing

Add-AppxProvisionedPackage -Online -PackagePath '.\Microsoft.DesktopAppInstaller.msixbundle'


# 1. Download the script text
$scriptText = Invoke-RestMethod https://aka.ms/install-powershell.ps1

# 2. Build the full command with parameters
$fullCommand = "& { $scriptText } -UseMSI"

# 3. Invoke it
Invoke-Expression $fullCommand




$ProgressPreference = 'SilentlyContinue'
$msix = "$env:TEMP\DesktopAppInstaller.msixbundle"
Invoke-WebRequest `
  -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.11.400/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' `
  -OutFile $msix

iex "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet -AddToPath"



Add-AppxProvisionedPackage -Online -PackagePath $msix -SkipLicense

& 'C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe' --version

# Registers App Installer so winget.exe becomes a “real” Win32 app available to every account
Add-AppxPackage -Path $msix -Register -DisableDevelopmentMode -AllUsers

$winget_exe = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if ($winget_exe.count -gt 1){
        $winget_exe = $winget_exe[-1].Path
}




# 1. Path to the Winget stub
$wingetExe = 'C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe'

# 2. Start the process with redirected streams
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName               = $wingetExe
$psi.Arguments              = '--version'
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute        = $false

$proc = [System.Diagnostics.Process]::Start($psi)
$proc.WaitForExit()

# 3. Read back whatever was written
$out = $proc.StandardOutput.ReadToEnd()
$err = $proc.StandardError.ReadToEnd()

"`nSTDOUT:`n$out", "`nSTDERR:`n$err" | ForEach-Object { Write-Host $_ }
