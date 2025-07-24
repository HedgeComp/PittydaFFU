<#
.SYNOPSIS
.Removes MS 365 via ODT by downloading the latest verions via Evergreen Link
.DESCRIPTION
.Downloads Latest ODT
.Cofngiures XML install File
.Runs Odt.exe against created xml

.INPUTS
.OUTPUTS
.NOTES
  Version:        1.1
  Author:         Scott McDonnell
  Twitter:        @Centit
  Creation Date:  05/04/2025
  Purpose/Change: Initial script development
  Change: 07/24/25 - Added Comments.
 #>




## Remove All Office Products XML Start ##
## The XML below will Remove All Microsoft C2Rs ( Click-to-Runs), regardless of Product ID and Languages. To remove All Comment out or remove the XML block between Start and End above. Then Uncomment the XML below.

$xml = @"
<Configuration>
  <Display Level="None" AcceptEULA="True" />
  <Property Name="FORCEAPPSHUTDOWN" Value="True" />
  <Remove All="TRUE">
  </Remove>
  <RemoveMSI />
</Configuration>
"@

## Remove All Office Products XML End ##

# Define temp folder and file paths
$tempFolder     = $env:TEMP
$xmlPath        = Join-Path $tempFolder 'o365.xml'
$odtPath        = Join-Path $tempFolder 'setup.exe'

# Write XML to temp folder
$xml | Out-File -FilePath $xmlPath -Encoding UTF8
Write-Output "Downloading lastet ODT"
# Download the Latest ODT into temp folder. URI obtained from Stealthpuppy's Evergreen Project
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
Write-Output "C2Rs Removed"
