# Get all room mailboxes
$Rooms = Get-Mailbox -ResultSize unlimited -Filter "RecipientTypeDetails -eq 'RoomMailbox'"

foreach ($Room in $Rooms) {
    Write-Host "Configuring Room: $($Room.DisplayName)" -ForegroundColor Cyan
    
    Set-CalendarProcessing -Identity $Room.Identity `
        -AutomateProcessing AutoAccept `
        -AllowConflicts $false `
        -DeleteSubject $false `
        -AddOrganizerToSubject $false `
        -RemovePrivateProperty $false `
        -OrganizerInfo $true `
        -AddAdditionalResponse $true `
        -AdditionalResponse "DECLINED: This room is already booked for the requested time. Please check the calendar for an alternative slot."
}
