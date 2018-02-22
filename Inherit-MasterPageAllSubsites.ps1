Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Start-SPAssignment -Global
$site = Get-SPSite Read-Host -Prompt "Site URL"
$topWeb = Get-SPWeb $site.Url
$site | Get-SPWeb -limit all | ForEach-Object {$_.CustomMasterUrl = $topWeb.CustomMasterUrl;$_.AllProperties["__InheritsCustomMasterUrl"] = "True";$_.MasterUrl = $topWeb.MasterUrl;$_.AllProperties["__InheritsMasterUrl"] = "True";$_.AlternateCssUrl = $topWeb.AlternateCssUrl;$_.AllProperties["__InheritsAlternateCssUrl"] = "True";$_.Update();}
Stop-SPAssignment -Global