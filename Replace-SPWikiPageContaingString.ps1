param(
    [string] $url,
    [string] $search,
    [string] $replace 
     )

Add-PSSnapin Microsoft.Sharepoint.Powershell -ErrorAction SilentlyContinue

$web = Get-SPWeb $url
$list = $web.GetList(($web.ServerRelativeUrl.TrimEnd("/") + "/Wiki%20Pages"))

foreach ($item in $list.items)
{
 write-host $item.Url " updating page..." -ForegroundColor green

  $item.file.CheckOut();
  do {write-host -NoNewline .;Start-Sleep 1;} while ($item.file.CheckOutStatus -eq "None")
  
  $item["ows_WikiField"] = $item["ows_WikiField"].replace($search ,$replace );
  $item.update();
  
  sleep 1
  $item.file.CheckIn("checked in by administrator");
  
  write-host $item.name " has been modified" -foregroundcolor red

}
 