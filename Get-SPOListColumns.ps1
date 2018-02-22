#Credentials to connect to office 365 site collection url 
$url = Read-Host -Prompt "Site URL"
$cred = Get-Credential
$username = $cred.UserName
$Password = $cred.Password
$list = Read-Host -Prompt "List name"

Write-Host "Load CSOM libraries" -foregroundcolor black -backgroundcolor yellow
Set-Location $PSScriptRoot
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Write-Host "CSOM libraries loaded successfully" -foregroundcolor black -backgroundcolor Green 

Write-Host "authenticate to SharePoint Online Tenant site $url and get ClientContext object" -foregroundcolor black -backgroundcolor yellow  
$context = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password) 
$context.Credentials = $credentials 
$web = $context.Web
$site = $context.Site 
$context.Load($web)
$context.Load($site)

$context.ExecuteQuery()

#P.S. You can get site columns with single ExecuteQuery, but keeping the above code to connect to the site so that will be common for all samples
#You can try placing below 37 and 38 lines of below 21st line, it will still get the site columns by making single request to the server
#Get all site columns
Write-Host "Getting all site columns" -foregroundcolor black -backgroundcolor yellow  

$web = $context.Web
$site = $context.Site 
$list = $web.Lists.GetByTitle($list);
$fields = $list.Fields;
$context.Load($web)
$context.Load($site)
$context.Load($list)
$context.Load($fields)
$context.ExecuteQuery()

try
{
$context.ExecuteQuery()
Write-Host "Successfully retrived all site columns" -foregroundcolor black -backgroundcolor green  

}
catch
{
Write-Host "Error while retriving site columns" -foregroundcolor black -backgroundcolor Red  

}
$csvFile = ".\Columns.csv"
#Display Site columns 
Write-Host "Displaying site columns with in the site started....." -foregroundcolor black -backgroundcolor yellow  
foreach($field in $fields)
{
Write-Host $field.Title "," $field.StaticName "," $field.InternalName


$csvContent = $field.Title + "," + $field.StaticName + "," + $field.InternalName
$csvContent >> $csvFile

}
Write-Host "Displaying site columns Completed" -foregroundcolor black -backgroundcolor Green  