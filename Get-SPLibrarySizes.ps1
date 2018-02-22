Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue

$siteURL = Read-Host "Enter Site URL:"
$csvFile = Read-Host "Enter CSV save location:" 
$site = new-object Microsoft.SharePoint.SPSite($siteURL)
$csvContent = "Web,Library Name,Size"


foreach ($web in $site.AllWebs)
{
 foreach ($list in $web.Lists)
{

        if($list.BaseType -eq "DocumentLibrary")   
      {
    $listSize = 0
   foreach ($item in $list.items) 
        { 
          $listSize += ($item.file).length
        }
     $csvContent += $web.Title+","+$list.Title+","+[Math]::Round(($listSize/1KB),2)+"KB`n"   
}
}
}

$csvContent >> $csvFile