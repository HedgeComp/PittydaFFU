###############################################################################
# 1) Install and Import Microsoft Graph PowerShell Modules
###############################################################################
# If you haven't already installed the Microsoft Graph module, uncomment:
# Install-Module Microsoft.Graph -Scope CurrentUser


# Uncomment and Import relevant sub-modules if not loaded. (this also imports Microsoft.Graph.Authentication)
#Import-Module Microsoft.Graph.Users
#Import-Module Microsoft.Graph.Groups
#Import-Module Microsoft.Graph.DeviceManagement
#Import-Module Microsoft.Graph.Identity.DirectoryManagement
#Import-Module Microsoft.Graph.Applications

###############################################################################
# 2) Connect to Microsoft Graph
###############################################################################
# You need Directory permissions to read users, groups, and devices, 
# plus write permissions to update devices (Device.ReadWrite.All).
# Adjust scopes as necessary for your environment.
###############################################################################
#Connect-MgGraph -Scopes "Group.Read.All","User.Read.All","Device.ReadWrite.All","DeviceManagementManagedDevices.Read.All"
Connect-MgGraph -Scopes "Group.Read.All","Device.ReadWrite.All","DeviceManagementManagedDevices.Read.All"

# Confirm you are connected (optional)
#Get-MgContext

###############################################################################
# 3) Define Variables
###############################################################################
# CHANGE THIS to the display name (or any other criteria) of the Security Group 
# whose user membership drives your device attribute logic.
$TargetGroupName = "FortiClient_EntraID"

# CHANGE THIS to the value you want to store in extensionAttribute1
# This will be used in the dynamic device group rule: device.extensionAttribute1 -eq "<Value>"
$ExtensionValue = "FortiClientVPN_Required"

###############################################################################
# 4) Get the Target Group
###############################################################################
Write-Host "Retrieving group '$TargetGroupName' ..."
#$targetGroups = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/groups/?`$filter=dispalyName eq '$($TargetGroupName)'"

$targetGroups = Get-MgGroup -Filter "displayName eq '$TargetGroupName'" -All
$targetGroup = $targetGroups | Select-Object -First 1

if (-not $targetGroup) {
    Write-Host "ERROR: Group '$TargetGroupName' not found. Exiting."
    return
}

Write-Host "Found group: $($targetGroup.DisplayName) (ObjectId: $($targetGroup.Id))"

###############################################################################
# 5) Retrieve Group Members (Users)
###############################################################################
Write-Host "Retrieving members of group '$($targetGroup.DisplayName)' ..."
$groupMembers = Get-MgGroupMember -GroupId $targetGroup.Id -All

# Filter out only user objects (in case the group contains service principals/devices/etc.)
#$userMembers = $groupMembers | Where-Object { $_.'[@odata.type]' -eq '#microsoft.graph.user' }

$userMembers = $groupMembers | Where-Object {
    $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.user'
}


if (-not $userMembers) {
    Write-Host "No user members found in group. Exiting."
    return
}

Write-Host "Found $($userMembers.Count) user(s) in the group."

###############################################################################
# 6) For Each User, Find Their Owned Devices & Update Extension Attribute
###############################################################################
foreach ($member in $userMembers) {
    Write-Host "`nChecking devices for user: $($member.AdditionalProperties.displayName) ($($member.UserPrincipalName)) ..."

    # Retrieve the user’s Intune-managed devices directly
    $devicesForUser = Get-MgBetaUserManagedDevice -UserId $member.Id -All

    if (!$devicesForUser -or $devicesForUser.Count -eq 0) {
        Write-Host " - No Intune-managed devices found for user $($member.UserPrincipalName)."
        continue
    }

    Write-Host " - Found $($devicesForUser.Count) device(s) for user."

    foreach ($device in $devicesForUser) {
        # Show the relevant properties
        Write-Host "   DeviceName: $($device.DeviceName)"
        Write-Host "   ManagementAgent: $($device.ManagementAgent)"
        Write-Host "   ManagedDeviceOwnerType: $($device.ManagedDeviceOwnerType)"

        # E.g., 'mdm' or 'MDM'? 'company' or 'Company'? Adjust as needed.
        if (($device.ManagementAgent -eq 'mdm') -and ($device.ManagedDeviceOwnerType -eq 'company')) {

            # Confirm this property references the Azure AD device objectId
            $azureADDeviceId = $device.azureADDeviceId  # If this property is available
            if (!$azureADDeviceId) {
                Write-Warning "   - No azureADDeviceId found; using $($device.Id) as fallback."
                $azureADDeviceId = $device.Id
            }

            # Prepare the extension attributes
            ## you can edit or add additional extensionAttribute numbers here in the JSON
            $Attributes = @{
                "ExtensionAttributes" = @{
                    "extensionAttribute1" = $ExtensionValue
                }
            } | ConvertTo-Json

            Write-Host "   Updating AAD device ID '$azureADDeviceId' with extensionAttribute1=$ExtensionValue..."
           
            # Make sure the device object is real in AAD
                      
            $entraObjectID = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/devices?`$filter=deviceId eq '$($azureADDeviceId)'").value

            $currentExtValue = $entraObjectID.extensionAttributes.extensionAttribute1
            Write-Host "Current Value of Ext1 is $currentExtValue"


            try {
                if (($currentExtValue -ne $ExtensionValue) -or ($null -eq $currentExtValue)) {
                
                Update-MgBetaDevice -DeviceId $entraObjectID.id -BodyParameter $Attributes
                Write-Host "   - Successfully updated extensionAttribute1 for '$($device.DeviceName)'." -ForegroundColor Green
                }
                else {
                Write-Host " Not updating $($device.DeviceName) extensionAttribute1 alredy set." -ForegroundColor Yellow
                }
            }
            
            catch {
                Write-Warning "   - Failed to update device '$($device.DeviceName)' (AAD ID: $azureADDeviceId): $_"
            }
        }
        else {
            Write-Host "   Skipped device '$($device.DeviceName)' because it’s not MDM + company-owned."
        }
    }
}


###############################################################################
# 7) (Optional) Clear the Attribute on Devices Whose Primary User is No Longer in the Group
###############################################################################
# If you'd like to ensure that devices get removed when the user is no longer in the group,
# you'd do a second pass here. For example:
#
#   1. Get all devices that currently have extensionAttribute1 = "SecGroupPrimaryUser"
#   2. For each such device, check if the primary owner is still in the group
#   3. If not, clear extensionAttribute1
#
# This step is left out for brevity but is recommended to maintain accurate membership.

Write-Host "`nAll done! The devices where primary users are in '$TargetGroupName' should now have extensionAttribute1 set to '$ExtensionValue'."
Write-Host "You can now create or update a dynamic device group with the rule:"
Write-Host "    device.extensionAttribute1 -eq `"$ExtensionValue`""

