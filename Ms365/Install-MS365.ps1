<#
.SYNOPSIS
.Installs MS 365 via ODT by downloading thge latest verions via Evergreen Link
.DESCRIPTION
.Removes AppX Packages
.Disables Cortana
.Removes McAfee
.Removes HP Bloat
.Removes Dell Bloat
.Removes Lenovo Bloat
.Windows 10 and Windows 11 Compatible
.Removes any unwanted installed applications
.Removes unwanted services and tasks
.Removes Edge Surf Game

.INPUTS
.OUTPUTS
C:\ProgramData\Debloat\Debloat.log
.NOTES
  Version:        5.1.22
  Author:         Scott McDonnell
  Twitter:        @Centit
  Creation Date:  08/03/2022
  Purpose/Change: Initial script development
  Change: 12/08/2022 - Added additional HP applications
  Change 23/09/2022 - Added Clipchamp (new in W11 22H2)
  Change 28/10/2022 - Fixed issue with Dell apps
  Change 23/11/2022 - Added Teams Machine wide to exceptions
  Change 27/11/2022 - Added Dell apps
  Change 07/12/2022 - Whitelisted Dell Audio and Firmware
  Change 19/12/2022 - Added Windows 11 start menu support
  Change 20/12/2022 - Removed Gaming Menu from Settings
  Change 18/01/2023 - Fixed Scheduled task error and cleared up $null posistioning
  Change 22/01/2023 - Re-enabled Telemetry for Endpoint Analytics
  Change 30/01/2023 - Added Microsoft Family to removal list
  Change 31/01/2023 - Fixed Dell loop
  Change 08/02/2023 - Fixed HP apps (thanks to http://gerryhampsoncm.blogspot.com/2023/02/remove-pre-installed-hp-software-during.html?m=1)
  Change 08/02/2023 - Removed reg keys for Teams Chat
  Change 14/02/2023 - Added HP Sure Apps#

#>


# Begin Config XML creation. Setup your own settings by following the MS learn article here: https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options
# Or cheat abit and use the MS wizard here: https://config.office.com/deploymentsettings

$xml = @"
<Configuration ID="fc78d2f9-59e9-4c0b-85e6-e75bfd6c5d79">
<Info Description=""/>
<Add OfficeClientEdition="64" Channel="Current" MigrateArch="TRUE">
<Product ID="O365BusinessRetail">
<Language ID="en-us"/>
<Language ID="MatchPreviousMSI"/>
<ExcludeApp ID="Access"/>
<ExcludeApp ID="Groove"/>
<ExcludeApp ID="Lync"/>
<ExcludeApp ID="OneDrive"/>
<ExcludeApp ID="OneNote"/>
<ExcludeApp ID="OutlookForWindows"/>
<ExcludeApp ID="Publisher"/>
</Product>
</Add>
<Property Name="SharedComputerLicensing" Value="0"/>
<Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
<Property Name="DeviceBasedLicensing" Value="0"/>
<Property Name="SCLCacheOverride" Value="0"/>
<Updates Enabled="TRUE"/>
<RemoveMSI/>
<AppSettings>
<Setup Name="Company" Value="Blythwood Homes"/>
<User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas"/>
<User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas"/>
<User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas"/>
</AppSettings>
<Display Level="None" AcceptEULA="TRUE"/>
</Configuration>
"@

## Install Office Products Config XML End ##

# Define temp folder and file paths
$tempFolder     = $env:TEMP
$xmlPath        = Join-Path $tempFolder 'Inst365.xml'
$odtPath        = Join-Path $tempFolder 'setup.exe'

# Write XML to temp folder
$xml | Out-File -FilePath $xmlPath -Encoding UTF8
Write-Output "Downloading lastet ODT"
# Download the Latest ODT into temp folder
$odtUrl = 'https://officecdn.microsoft.com/pr/wsus/setup.exe'
Invoke-WebRequest -Uri $odtUrl `
                  -OutFile $odtPath `
                  -UseBasicParsing

Write-Output "Running ODT"
# Run the ODT from temp, pointing at the XML also in temp
$proc = Start-Process -FilePath $odtPath `
              -ArgumentList "/configure `"$xmlPath`"" `
              -WindowStyle Hidden `
              -Wait `
              -PassThru
$proc | Wait-Process          
              
Write-Output "MS 365 Installed"
