Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

$Url = Read-Host -Prompt "SPO Site URL"
$ListTitle = Read-Host -Prompt "List Title"
$cred = Get-Credential
$Username = $cred.UserName
$AdminPassword = $cred.Password

$ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)
$password = ConvertTo-SecureString -string $AdminPassword -AsPlainText -Force
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)
$ctx.RequestTimeout = 16384000
$ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


for($z=4680;$z -lt 4700 ;$z++)
  {
$count = $z * 1
$toCount = ($z + 1) * 1
write-host "Updating items" $count.ToString() " to " $toCount.ToString()
$spQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
$spQuery.ViewXml ="<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' Ascending='True'/></OrderBy><Where><And><Geq><FieldRef Name='ID'/><Value Type='Number'>" + $count.ToString() + "</Value></Geq><Leq><FieldRef Name='ID'/><Value Type='Number'>" + $toCount.ToString() + "</Value></Leq></And></Where></Query></View>";
  $itemki=$ll.GetItems($spQuery)
  $ctx.RequestTimeout = 163840000
  $ctx.Load($itemki)
  $ctx.ExecuteQuery()

for($j=0;$j -lt $itemki.Count ;$j++)
  {
            
            
      $itemki[$j].ResetRoleInheritance()
    # write-host "Reset item; " $j
  }
  $ctx.RequestTimeout = 163840000
  $ctx.ExecuteQuery()
 }