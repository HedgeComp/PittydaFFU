## Remove All Office Products XML Start ##

$xml = @"
<Configuration>
  <Display Level="None" AcceptEULA="True" />
  <Property Name="FORCEAPPSHUTDOWN" Value="True" />
  <Remove All="TRUE">
  </Remove>
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
Write-Output "C2Rs Removed"
