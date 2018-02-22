<# Parameters available -Csv #>

params (
[Parameter(Mandatory=$true)]
[string]$Csv
)

$table = Import-Csv $Csv

foreach ($row in $table)
{
$rac = Read-Host -Prompt "Enter Domain name"
$Url = $row.Url
$GroupName = $row.Name
$Owner = $rac + '\' + $row.Owner
$Member = $rac + '\' + $row.Member
$Visitor =  $rac + '\' + $row.Visitor

###### Get the web object that requires the new groups

$web = Get-SPWeb $url

###### If the web object is currently inheriting permission then break the inheritance

if ($web.HasUniquePerm -eq $false)
{
$web.BreakRoleInheritance($true, $true)
}

###### Remove unnecessary groups/users from the site permissions
for ($i = $web.RoleAssignments.Count – 1; $i -ge 0; $i–-)
{
$web.RoleAssignments.Remove($i)
}

###### Create the new groups

# Owner Group
$web.SiteGroups.Add(“$GroupName Owners”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people full control permissions to the $GroupName site”)
$ownerGroup = $web.SiteGroups["$web Owners"]
$ownerGroup.AllowMembersEditMembership = $true
$ownerGroup.Update()

# Members Group
$web.SiteGroups.Add(“$GroupName Members”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people contribute permissions to the $GroupName site”)
$membersGroup = $web.SiteGroups["$web Members"]
$membersGroup.AllowMembersEditMembership = $true
$membersGroup.Update()

# Visitors Group
$web.SiteGroups.Add(“$GroupName Visitors”, $web.Site.Owner, $web.Site.Owner, “Use this group to grant people read permissions to the $GroupName site”)
$visitorsGroup = $web.SiteGroups["$web Visitors"]
$visitorsGroup.AllowMembersEditMembership = $true
$visitorsGroup.Update()

###### Add users to group as required

$user1 = $web.Site.RootWeb.EnsureUser(“$Owner”)
$ownerGroup.AddUser($user1)

$user2 = $web.Site.RootWeb.EnsureUser(“$Member”)
$membersGroup.AddUser($user2)

$user3 = $web.Site.RootWeb.EnsureUser(“$Visitor”)
$visitorsGroup.AddUser($user3)

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
}