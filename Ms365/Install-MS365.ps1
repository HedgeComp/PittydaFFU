<#
.SYNOPSIS
.Installs MS 365 via ODT by downloading thge latest verions via Evergreen Link
.DESCRIPTION
.Downloads Latest ODT
.Cofngiures XML install File
.Runs Odt.exe against created xml

.INPUTS
.OUTPUTS
.NOTES
  Version:        1.3
  Author:         Scott McDonnell
  Twitter:        @Centit
  Creation Date:  05/04/2025
  Purpose/Change: Initial script development
  Change: 05/29/25 - Added Comments.
  Change: 10/24/25 - Set Default Generic Company Name. Fix XML Comments
 #>


## Begin Config XML creation. Setup your own settings by following the MS learn article here: https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options
## Or Youc can use the MS wizard here: https://config.office.com/deploymentsettings . Save your XMl File and copy the contents between the opening @" and closing "@

$xml = @"
<!-- START : Paste your Deployment XML Config below this line -->
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
<Setup Name="Company" Value="MyCompany Name Here"/>
<User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas"/>
<User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas"/>
<User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas"/>
</AppSettings>
<Display Level="None" AcceptEULA="TRUE"/>
</Configuration>
<!-- END : Paste your Deployment XML Config above this line -->
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
