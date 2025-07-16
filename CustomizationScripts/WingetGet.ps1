$JBNWinGetResolve = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
$JBNWinGetPathExe = $JBNWinGetResolve[-1].Path

$JBNWinGetPath = Split-Path -Path $JBNWinGetPathExe -Parent
set-location $JBNWinGetPath


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
