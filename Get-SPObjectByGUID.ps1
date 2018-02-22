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
    [Guid]$ObjectGuid = "$(Read-Host 'The GUID of the object you are trying to find [e.g. 91ce5bbf-eebb-4988-9964-79905576969c]')"
)
 
 $startingUrl = $SiteUrl
 $targetGuid = $ObjectGuid
#function FindObject($startingUrl, $targetGuid)
#{
    # To work with SP2007, we need to go directly against the object model
    #Add-Type -AssemblyName "Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
 
    # Grab the site collection and all webs associated with it to start
    $targetSite = Get-SPSite $startingUrl #New-Object Microsoft.SharePoint.SPSite($startingUrl)
    $matchObject = $false
    $itemsTotal = 0
    $listsTotal = 0
    $searchStart = Get-Date
 
    Clear-Host
    Write-Host ("INITIATING SEARCH FOR GUID: {0}" -f $targetGuid)
 
    # Step 1: see if we can find a matching web.
    $allWebs = $targetSite.AllWebs
    Write-Host ("`nPhase 1: Examining all webs ({0} total)" -f $allWebs.Count)
    foreach ($spWeb in $allWebs)
    {
        $listsTotal += $spWeb.Lists.Count
        if ($spWeb.ID -eq $targetGuid)
        {
            Write-Host "`nMATCH FOUND: Web"
            Write-Host ("- Web Title: {0}" -f $spWeb.Title)
            Write-Host ("-   Web URL: {0}" -f $spWeb.Url)
            $matchObject = $true
            break
        }
        $spWeb.Dispose()
    }
     
    # If we don't yet have match, we'll continue with list iteration
    if ($matchObject -eq $false)
    {
        Write-Host ("Phase 2: Examining all lists and libraries ({0} total)" -f $listsTotal)
        $allWebs = $targetSite.AllWebs
        foreach ($spWeb in $allWebs)
        {
            $allLists = $spWeb.Lists
            foreach ($spList in $allLists)
            {
                $itemsTotal += $spList.Items.Count
                if ($spList.ID -eq $targetGuid)
                {
                    Write-Host "`nMATCH FOUND: List/Library"
                    Write-Host ("-            List Title: {0}" -f $spList.Title)
                    Write-Host ("- List Default View URL: {0}" -f $spList.DefaultViewUrl)
                    Write-Host ("-      Parent Web Title: {0}" -f $spWeb.Title)
                    Write-Host ("-        Parent Web URL: {0}" -f $spWeb.Url)
                    $matchObject = $true
                    break
                }
            }
            if ($matchObject -eq $true)
            {
                break
            }
 
        }
        $spWeb.Dispose()
    }
     
    # No match yet? Look at list items (which includes folders)
    if ($matchObject -eq $false)
    {
        Write-Host ("Phase 3: Examining all list and library items ({0} total)" -f $itemsTotal)
        $allWebs = $targetSite.AllWebs
        foreach ($spWeb in $allWebs)
        {
            $allLists = $spWeb.Lists
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
                    $matchObject = $true
                    break
                }
            }
            if ($matchObject -eq $true)
            {
                break
            }
 
        }
        $spWeb.Dispose()
    }
     
    # No match yet? Too bad; we're done.
    if ($matchObject -eq $false)
    {
        Write-Host ("`nNO MATCH FOUND FOR GUID: {0}" -f $targetGuid)
    }
     
    # Dispose of the site collection
    $targetSite.Dispose()
    Write-Host ("`nTotal seconds to execute search: {0}`n" -f ((Get-Date) - $searchStart).TotalSeconds)
     
    # Abort script processing in the event an exception occurs.
    trap
    {
        Write-Warning "`n*** Script execution aborting. See below for problem encountered during execution. ***"
        $_.Message
        break
    }
#}
 
# Launch script
#FindObject $SiteUrl $ObjectGuid