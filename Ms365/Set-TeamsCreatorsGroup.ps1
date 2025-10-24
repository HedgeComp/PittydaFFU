<#
.SYNOPSIS
  Disable Users from Creating Teams Sites with out being a member of a specified Entra Security Group

.DESCRIPTION
  - Create a Entra Security Group First, ie: "TeamsCreatorsGroup"
  - Add Users to the group as Memebers ( Not as Owners)
  - Connects to MS Graph (requires Directory.ReadWrite.All, Group.Read.All)
  - Finds the group ID for the "TeamsCreatorsGroup"
  - Modifies the Default Entra MS Group Creation Template:
      • Sets "EnableGroupCreation" value to False
      • Sets "GroupCreationAllowedGroupId" value to Group ID of created "TeamsCreatorsGroup"


.EXAMPLE
  .\Set-TeamsCreatorsGroup.ps1 
#>

Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement 
Import-Module Microsoft.Graph.Beta.Groups

Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All" 
$GroupName = "TeamsCreatorsGroup" #Replace this with the name of the group that contains users who are allowed to create teams or M365 groups.  
$AllowGroupCreation = "False" 
$settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id 
if(!$settingsObjectID){ 
$params = @{ 
        templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b" 
        values = @( 
            @{ 
         name = "EnableMSStandardBlockedWords"      
         value = "true" 
            } 
        ) 
    }
New-MgBetaDirectorySetting -BodyParameter $params 
$settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id 
}

$groupId = (Get-MgBetaGroup | Where-object {$_.displayname -eq $GroupName}).Id 
$groupID
$params = @{ 
    templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b" 
    values = @( 
        @{ 
            name = "EnableGroupCreation" 
            value = $AllowGroupCreation 
        } 
        @{ 
            name = "GroupCreationAllowedGroupId" 
            value = $groupId 
        } 
    ) 
} 
$settingsObjectID
Update-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID -BodyParameter $params 
(Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values
