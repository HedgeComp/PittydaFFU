$ProgressPreference = 'SilentlyContinue'
$msix = "$env:TEMP\DesktopAppInstaller.msixbundle"
Invoke-WebRequest `
  -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.11.400/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' `
  -OutFile $msix



  Add-AppxProvisionedPackage `
  -Online `
  -PackagePath "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle" `
  -SkipLicense

# Registers App Installer so winget.exe becomes a “real” Win32 app available to every account
Add-AppxPackage -Path $msix -Register -DisableDevelopmentMode -AllUsers
