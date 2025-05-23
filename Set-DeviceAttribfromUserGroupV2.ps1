<# This script will take the members of a User Group (defined by $TargetGroupName) and Search for Entra Devices where the member is assigned as the Primary User.
Once the Device Objects are found, it will then check for a Customm Extension value in device.extensionAttribute1 property.
If the Device is Corporate owned and in MDM (intune) it will set the custom attribute value to a specified value( $ExtensionValue) if not set.
if the Value is already defined then it will skip. A Device Group can now be created and use a Dynamic Membership device.extensionAttribute1 -eq `"$ExtensionValue`"

Use Case:  Users in a a group who are allowed to sign tino VPN via SAML. USers require the VPN on their devices. Once they are in the Allowed VPN group, you can run the script `
and automaticcly add their devices to a Group in Entra that can be used in Intune to deploy the VPN software to a Device Group for the required VPN software.

 #>

###############################################################################
# 1) Install and Import Microsoft Graph PowerShell Modules
###############################################################################
# If you haven't already installed the Microsoft Graph module, uncomment:
# Install-Module Microsoft.Graph -Scope CurrentUser


# Uncomment and Import relevant sub-modules if not loaded. (this also imports Microsoft.Graph.Authentication)
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DeviceManagement

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
# whose user membership drives the adding to device attribute1 logic.
$TargetGroupName = "VendorClient_EntraID"

# CHANGE THIS to the value you want to store in extensionAttribute1
# This will be used in an Entra dynamic device group rule: device.extensionAttribute1 -eq "<Value>"
$ExtensionValue = "VendorClientVPN_Required"

###############################################################################
# 4) Get the Target Group
###############################################################################
Write-Host "Retrieving group '$TargetGroupName' ..."


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
try {
    # Attempt to get devices. -ErrorAction Stop makes errors terminating for this cmdlet.
    $devicesForUser = Get-MgUserManagedDevice -UserId $member.Id -All -ErrorAction Stop
}
catch {
    # This block executes if Get-MgUserManagedDevice throws a terminating error.
    Write-Warning "   - Failed to retrieve devices for user $userPrincipalName (ID: $($member.Id)). Error: $($_.Exception.Message)"
    # $devicesForUser will remain $null (or whatever it was before the try block).
    # The script will then hit the 'if' condition below and 'continue'.
}


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
            $intuneAadID = $device.azureADDeviceId  # If this property is available
            if (!$intuneAadID) {
                Write-Warning "   - No azureADDeviceId found; using $($device.Id) as fallback."
                $intuneAadID = $device.Id
            }

            # Prepare the extension attributes
            $Attributes = @{
                "ExtensionAttributes" = @{
                    "extensionAttribute1" = $ExtensionValue
                }
            } | ConvertTo-Json

            Write-Host "   Updating AAD device ID '$intuneAadID' with extensionAttribute1=`"$ExtensionValue`"..."
            
            #the orgianal below returns the single value for .id of the Entra Object. We now want to check other properties so change to the full .value
            #you can switch back the graph call to V1.0 if you want, juse a preference for /beta
            $entraObjectID = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/devices?`$filter=deviceId eq '$($intuneAadID)'").value

            $currentExtValue = $entraObjectID.extensionAttributes.extensionAttribute1
            Write-Host "Current Value of extensionAttribute1 is $currentExtValue"


            try {
                if (($currentExtValue -ne $ExtensionValue) -or ($null -eq $currentExtValue)) {
                
                Update-MgDevice -DeviceId $entraObjectID.id -BodyParameter $Attributes
                Write-Host "   - Successfully updated extensionAttribute1 for '$($device.DeviceName)'." -ForegroundColor Green
                }
                else {
                Write-Host "Not updating $($device.DeviceName) extensionAttribute1 alredy set." -ForegroundColor Yellow
                }
            }
            
            catch {
                Write-Warning "   - Failed to update device '$($device.DeviceName)' (AAD ID: $intuneAadID): $_"
            }
        }
        else {
            Write-Host "   Skipped device '$($device.DeviceName)' because it’s not MDM + company-owned."
        }
    }
}

Write-Host "`nWe're all done ya'll! ` `nThe Intune Devices where primary users are in the Entra User Group '$TargetGroupName' should now have extensionAttribute1 set to '$ExtensionValue'."
Write-Host "You can now create or update a Device Group Dynamic membership with the following rule syntax:"
Write-Host "`n   (device.extensionAttribute1 -eq `"$ExtensionValue`")"
Write-Host "`n" ` "`n" ` "Good-Luck!"
