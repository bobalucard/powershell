Add-PSSnapin Microsoft.SharePoint.PowerShell
$webUrl = Read-Host -Prompt "Enter WebUrl"
$web = Get-SPWeb $webUrl

###### Create the new groups

# Owner Group
$web.SiteGroups.Add(“$web Owners”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people full control permissions to the $web site”)
$ownerGroup = $web.SiteGroups["$web Owners"]
$ownerGroup.AllowMembersEditMembership = $true
$ownerGroup.Update()

# Members Group
$web.SiteGroups.Add(“$web Members”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people contribute permissions to the $web site”)
$membersGroup = $web.SiteGroups["$web Members"]
$membersGroup.AllowMembersEditMembership = $true
$membersGroup.Update()

# Visitors Group
$web.SiteGroups.Add(“$web Visitors”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people read permissions to the $web site”)
$visitorsGroup = $web.SiteGroups["$web Visitors"]
$visitorsGroup.AllowMembersEditMembership = $true
$visitorsGroup.Update()

###### Add users to group as required

$o = Read-Host -Prompt "Add user to owner group (DOMAIN\Username)"
$m = Read-Host -Prompt "SAdd user to member group (DOMAIN\Username)"

$user1 = $web.Site.RootWeb.EnsureUser($o)
$ownerGroup.AddUser($user1)
$user2 = $web.Site.RootWeb.EnsureUser($m)
$membersGroup.AddUser($user2)

###### Create a new assignment (group and permission level pair) which will be added to the web object

$ownerGroupAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($ownerGroup)
$membersGroupAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($membersGroup)
$visitorsGroupAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($visitorsGroup)

###### Get the permission levels to apply to the new groups

$ownerRoleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]
$membersRoleDefinition = $web.Site.RootWeb.RoleDefinitions["Contribute"]
$visitorsRoleDefinition = $web.Site.RootWeb.RoleDefinitions["Read"]

###### Assign the groups the appropriate permission level

$ownerGroupAssignment.RoleDefinitionBindings.Add($ownerRoleDefinition)
$membersGroupAssignment.RoleDefinitionBindings.Add($membersRoleDefinition)
$visitorsGroupAssignment.RoleDefinitionBindings.Add($visitorsRoleDefinition)

###### Add the groups with the permission level to the site

$web.RoleAssignments.Add($ownerGroupAssignment)
$web.RoleAssignments.Add($membersGroupAssignment)
$web.RoleAssignments.Add($visitorsGroupAssignment)

$web.Update()
$web.Dispose()