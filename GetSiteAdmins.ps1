########################################################### 
#SP_Display-SiteCollectionAdmins1.ps1 -URL <string> 
# 
# 
#Display all site collection admins for all site collections 
# within a web application. 
########################################################### 
 
function GetPerm ($site)
{
    $csv = ".\SiteAdmins.csv"
    #Write-Host "URL: $($site.Url), Site Administrators: $($site.SiteAdministrators), UniquePermissions: $($site.HasUniquePerm)"
    if ($site.HasUniquePerm -and $site.AssociatedOwnerGroup -ne $null )
    {
            Write-Host "Site Owners"
            $own = $site | Select -ExpandProperty AssociatedOwnerGroup | Select -ExpandProperty Users | Select LoginName
    }
    $append = $site.Url+','+$site.SiteAdministrators+','+$site.HasUniquePerm+','+$own
    $append >> $csv
    $site.Dispose()
 }
 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SharePoint') 
 
#DECLARE VARIABLES 
[string]$siteUrl = $args[0] 
 
function GetMissingParameter 
{ 
  $script:siteUrl = Read-Host "Enter Site URL" 
} 
 
############ 
# MAIN 
############ 
 
#IF MISSING PARM FOR SITE URL, ASK FOR INPUT TO FILL http://intranet
if($args.length -eq 0) 
{ 
  GetMissingParameter 
} 
$csv = ".\SiteAdmins.csv"
$rootSite = New-Object Microsoft.SharePoint.SPSite($siteUrl) 
$spWebApp = $rootSite.WebApplication 
 
foreach($site in $spWebApp.Sites) 
{ 
    GetPerm -site $site.RootWeb
    foreach($sub in $site.AllWebs) 
    { 
        GetPerm -site $sub
    }
}
$rootSite.Dispose()

