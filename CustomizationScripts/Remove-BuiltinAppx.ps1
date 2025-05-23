#Add Microsoft Apps you want to remove before Sysprep
$AppsList = @(
'Microsoft.3DBuilder',
'Microsoft.BingFinance',
'Microsoft.BingNews',
'Microsoft.BingSports',
'Microsoft.BingWeather'
'Microsoft.MicrosoftSolitaireCollection',
'Microsoft.People',
'Microsoft.Windows.Photos',
'microsoft.windowscommunicationsapps',
'Microsoft.WindowsPhone',
'Microsoft.WindowsSoundRecorder',
'Microsoft.XboxApp',
'Microsoft.ZuneMusic',
'Microsoft.ZuneVideo',
'Microsoft.Getstarted',
'Microsoft.WindowsFeedbackHub',
'Microsoft.XboxIdentityProvider',
'Microsoft.MicrosoftOfficeHub',
'Microsoft.BingSearch',
'Clipchamp.Clipchamp',
'Microsoft.WindowsMaps',
'Microsoft.XboxGamingOverlay',
'Microsoft.XboxGameOverlay',
'Microsoft.Windows.Cortana',
'Microsoft.XboxSpeechToTextOverlay',
'MSTEAMS',
'Microsoft.Xbox.TCUI',
'Microsoft.OutlookForWindows',
'MicrosoftCorporationII.QuickAssist',
'Microsoft.GetHelp',
'Microsoft.GamingApp',
'Microsoft.PowerAutomateDesktop',
'Microsoft.Todos',
'Microsoft.YourPhone',
'Microsoft.Whiteboard',
'Microsoft.MicrosoftStickyNotes',
'Microsoft.MicrosoftJournal',
'Microsoft.MixedReality.Portal',
'MicrosoftCorporationII.MicrosoftFamily',
'Microsoft.549981C3F5F10',
'Microsoft.Windows.DevHome'
)


#will remove each app from both the current logged in account and the provisioned package for
ForEach ($App in $AppsList){
$PackageFullName = (Get-AppxPackage $App).PackageFullName
$ProPackageFullName = (Get-AppxProvisionedPackage -online | Where-Object {$_.Displayname -eq $App}).PackageName
#Debug look for the Package Names below
#write-host $PackageFullName
#Write-Host $ProPackageFullName
if ($PackageFullName){
Write-Host "Removing Package: $App" -ForegroundColor Green
remove-AppxPackage -package $PackageFullName | Out-Null
}
else{
Write-Host "Unable to find package: $App" -ForegroundColor DarkMagenta
}
if ($ProPackageFullName){
Write-Host "Removing Provisioned Package: $ProPackageFullName" -ForegroundColor Yellow
Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName | Out-Null
}
else{
Write-Host "Unable to find provisioned package: $App" -ForegroundColor DarkMagenta
}
}
Get-AppxPackage -Name *AdobeNotificationClient* -Allusers | Remove-AppxPackage -Allusers
#$inputChoice = Read-Host "Waiting for a key press so I can check the Appx Removal above"
#Start-Sleep -s 5
