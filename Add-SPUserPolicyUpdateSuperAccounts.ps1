Add-PSSnapin Microsoft.Sharepoint.Powershell -ErrorAction SilentlyContinue

$userOrGroup = Read-Host "Enter domain\user account"
$displayName = Read-Host "Enter display name"
$wa = Read-Host "Enter Web Application URL or Name"
$webApp = Get-SPWebApplication $wa 


$title = "Choose Super User Role"
$superReader = New-Object System.Management.Automation.Host.ChoiceDescription "&Reader", `
    "Reader"
$superUser = New-Object System.Management.Automation.Host.ChoiceDescription "&User", `
    "User"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($superReader, $superUser)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
switch ($result)
    {
        0 {$userType = "portalsuperreaderaccount"; $policyRole = $webApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)}
        1 {$userType = "portalsuperuseraccount"; $policyRole = $webApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)}
    }





$title = "Add User Policy"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Update User Policy"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retain current User Policy"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
switch ($result)
    {
        0 {$policy = $webApp.Policies.Add($userOrGroup, $displayName); $policy.PolicyRoleBindings.Add($policyRole)}
        1 {Write-Host "User Policy not updated"}
    }




$title = "Update Super Accounts"
$message = "Would you like to update $userType with $userOrGroup ?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Update Super Account"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", 
    "Retain current Super Account"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {$webApp.Properties["$userType"] = "$userOrGroup"}
        1 {Write-Host "Super Account not updated"}
    }

 $webApp.Update()