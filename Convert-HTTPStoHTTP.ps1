# Converts all web applications from HTTPS to HTTP

$web = Read-Host -Prompt "Site URL" -AsSecureString
$app = Read-Host -Prompt "App name" -AsSecureString
$appAcc = Read-Host -Prompt "App Account (DOMAIN\Username)" -AsSecureString
$allDB = ((Get-SPWebApplication $app).ContentDatabases).Name
$allDB | Dismount-SPContentDatabase

Remove-SPWebApplication "https://$web" -DeleteIISSite

$ap = New-SPAuthenticationProvider
New-SPWebApplication -Name $app -Port 80 -URL "http://$web" -ApplicationPool "$app" -ApplicationPoolAccount (Get-SPManagedAccount $appAcc) -AuthenticationProvider $ap

foreach( $name in $allDB)
{
    Mount-SPContentDatabase -Name $name -WebApplication "http://$web"
}


$usersRead = @(
    @{ name = "NT AUTHORITY\LOCAL SERVICE"
       account = "NT AUTHORITY\LOCAL SERVICE"}, 
    @{ name = "Search Crawling Account"
       account = Read-Host -Prompt "Search Crawling Account (DOMAIN\Username)" },
    @{ name = "Super Reader (Object Cache)"
       account = Read-Host -Prompt "Super Reader Account (DOMAIN\Username)" }
    )

 $usersFull = @(  
    @{ name = "SPFarm"
       account = Read-Host -Prompt "Farm Account (DOMAIN\Username)" },  
    @{ name = "Super User (Object Cache)"
       account = Read-Host -Prompt "Super User Account (DOMAIN\Username)" }
    )

 Get-SPWebApplication  | foreach { 
    $webApp = $_
    foreach( $u in $usersFull) { 
        $policy = $webApp.Policies.Add($u.account, $u.name) 
        $policyRole = $webApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl) 
        $policy.PolicyRoleBindings.Add($policyRole)
        } 
    $webApp.Update() 
} 

 Get-SPWebApplication  | foreach { 
    $webApp = $_
    foreach( $u in $usersRead) { 
        $policy = $webApp.Policies.Add($u.account, $u.name) 
        $policyRole = $webApp.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FUllRead) 
        $policy.PolicyRoleBindings.Add($policyRole)
        } 
    $webApp.Update() 
} 
