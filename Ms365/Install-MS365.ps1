#
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

## Remove All Office Products XML End ##

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
