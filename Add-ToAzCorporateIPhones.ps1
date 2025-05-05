<#
.SYNOPSIS
  Bulk-add users (by UPN) to the Azure AD group "azCorporate iPhones" via MS Graph SDK.

.DESCRIPTION
  - Reads a CSV with header: UserPrincipalName
  - Connects to MS Graph (requires GroupMember.ReadWrite.All, User.Read.All)
  - Finds the group "azCorporate iPhones" and caches its ID
  - For each UPN:
      • GET user object ID
      • Add that user to the group
      • Silently skip if already a member

.PARAMETER CsvPath
  Path to the CSV file with a column named UserPrincipalName.

.EXAMPLE
  .\Add-ToAzCorporateIPhones.ps1 -CsvPath .\users.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath
)

# 1. Ensure Graph modules are available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft.Graph module…" -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

# 2. Connect to Graph
Write-Host "Connecting to Microsoft Graph…" -ForegroundColor Cyan
Connect-MgGraph -Scopes @(
    "GroupMember.ReadWrite.All",
    "User.Read.All"
)

# 3. Resolve the target group
$groupName = "azCorporate iPhones"
Write-Host "Locating group '$groupName'…" -NoNewline
$group = Get-MgGroup -Filter "displayName eq '$groupName'" -Select Id -ErrorAction Stop

if (-not $group) {
    Write-Error "`nGroup '$groupName' not found."
    exit 1
}

$groupId = $group.Id
Write-Host " Found (ID: $groupId)." -ForegroundColor Green

# 4. Load the CSV
try {
    $users = Import-Csv -Path $CsvPath
    if ($users.Count -eq 0) { throw "CSV is empty." }
}
catch {
    Write-Error "Failed to load CSV at '$CsvPath': $_"
    exit 1
}

# 5. Process each UPN
foreach ($row in $users) {
    $upn = $row.UserPrincipalName.Trim()
    Write-Host "Adding $upn to group…" -NoNewline

    # 5a. Resolve the user's object ID
    try {
        $user = Get-MgUser -UserId $upn -Select Id -ErrorAction Stop
    }
    catch {
        Write-Warning "`n  → Could not resolve user '$upn'. Skipping."
        continue
    }

    # 5b. Attempt to add to group
    try {
        New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id -ErrorAction Stop
        Write-Host " Done." -ForegroundColor Green
    }
    catch [Microsoft.Graph.PowerShell.Authentication.ConflictException] {
        Write-Host " Already a member." -ForegroundColor Yellow
    }
    catch {
        Write-Warning "`n  → Failed to add '$upn': $_"
    }
}

Write-Host "Script complete. All entries processed." -ForegroundColor Cyan
