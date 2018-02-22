#####################################################################################################
#
#Get CSV file with columns titled FromURL, ToURL, ObjectOrSite and Title:
param (
[string]$CsvFile = "$(Read-Host 'Settings CSV location [e.g. C:\sitestomigrate.csv]')"
)
#####################################################################################################


#
function CreateLibrary ($LibType, $Title, $SiteUrl)
{
$SPWeb = Get-SPWeb -Identity $SiteUrl
$ListUrl = $Title
$listTemplate = $SPWeb.ListTemplates[$LibType]
$SPWeb.Lists.Add($ListUrl, "$Title",$listTemplate)
$list = $SPWeb.Lists[$ListUrl]
$list.Title = $Title
$list.Update()
$SPWeb.Dispose()
}

#load the CSV file into a table
$table = Import-Csv $CsvFile


Write-Host "Started at: " + Get-Date

foreach ($row in $table)
    {
    # Create SharePoint Site
    if ($row.ObjectOrSite -eq "Site")
        {
            New-SPWeb -Url $row.ToSite -Template "STS#1" -Name "$row.Title"
        }
    #Create SharePoint Document library or list
    elseif ($row.ObjectOrSite -eq "Object")
        {
            CreateLibrary -LibType "Document Library"  -Title $row.Title -SiteUrl $row.ToSite
        }
    }

Write-Host "Finished at: " + Get-Date