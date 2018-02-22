<#
.SYNOPSIS
   FindObjectByGuid.ps1
.DESCRIPTION
   This script attempts to locate a SharePoint object by its unique ID (GUID) within
   a site collection. The script first attempts to locate a match by examining webs;
   following webs, lists/libraries are examined. Finally, individual items within
   lists and libraries are examined. If an object with the ID is found, information 
   about the object is reported back.
.NOTES
   Author: Sean McDonough
   Last Revision: 27-July-2012
.PARAMETER SiteUrl
   The URL of the site collection that will be searched
.PARAMETER ObjectGuid
   The GUID that identifies the object to be located
.EXAMPLE
   FindObjectByGuid -SiteUrl http://mysitecollection.com -ObjectGuid 91ce5bbf-eebb-4988-9964-79905576969c
#>
param
(
    [string]$SiteUrl = "$(Read-Host 'The URL of the site collection to search [e.g. http://mysitecollection.com]')",
    #[Guid]$ObjectGuid = "$(Read-Host 'The GUID of the object you are trying to find [e.g. 91ce5bbf-eebb-4988-9964-79905576969c]')",
    [string]$csvFile = ".\input.csv"
)
 
function FindObject($startingUrl, $targetGuid)
{
    # To work with SP2007, we need to go directly against the object model
    #Add-Type -AssemblyName "Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
 
    # Grab the site collection and all webs associated with it to start
    $targetSite = Get-SPWeb $startingUrl #New-Object Microsoft.SharePoint.SPSite($startingUrl)
    $matchObject = $false
    $itemsTotal = 0
    $listsTotal = 0
    $searchStart = Get-Date
    $csvOut = ".\CorruptedFiles.csv"

    Write-Host ("INITIATING SEARCH FOR GUID: {0}" -f $targetGuid)
     
 
            $allLists = $targetSite.Lists
            foreach ($spList in $allLists)
            {
                try
                { 
                    $listItem = $spList.GetItemByUniqueId($targetGuid)
                }
                catch
                {
                    $listItem = $null
                }
                if ($listItem -ne $null)
                {
                    Write-Host "`nMATCH FOUND: List/Library Item"
                    Write-Host ("-                    Item Name: {0}" -f $listItem.Name)
                    Write-Host ("-                    Item Type: {0}" -f $listItem.FileSystemObjectType)
                    Write-Host ("-       Site-Relative Item URL: {0}" -f $listItem.Url)
                    Write-Host ("-            Parent List Title: {0}" -f $spList.Title)
                    Write-Host ("- Parent List Default View URL: {0}" -f $spList.DefaultViewUrl)
                    Write-Host ("-             Parent Web Title: {0}" -f $spWeb.Title)
                    Write-Host ("-               Parent Web URL: {0}" -f $spWeb.Url)
                    $appendCsv = $listItem.Name + "`%" + $listItem.FileSystemObjectType + "`%" + $listItem.Url + "`%" + $spList.Title + "`%" + $spList.DefaultViewUrl
                    $appendCsv >> $csvOut
                    $matchObject = $true
                    
                }
            }

}
 
 $csvOut = "CorruptedFiles.csv"
 $table = Import-Csv $csvFile
 $appendCsv = "Item Name" + "`%" + "Item Type" + "`%" + "Site-Relative Item-URL" + "`%" + "List Title" + "`%" + "Parent List URL"
 $appendCsv >> $csvOut
# Launch script
#Iterate through all given rows in .csv and delete associated libraries
foreach ($row in $table)
{
    try {
    FindObject $SiteUrl $row.id
    }
    catch{
        Write-Host "Error searching for GUID" -ForegroundColor Yellow

    }
}
