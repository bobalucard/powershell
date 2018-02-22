
param (
[string]$webUrl,
[string]$listUrl,
[string]$csvFile
)

# Replace siteurl with actual web url
$web = Get-SPWeb -Identity $webUrl
# Replace docurl with document library url
$list = $web.GetList($listUrl)

#load the CSV file into a table

$table = Import-Csv $csvFile

#Iterate through all given rows in .csv and delete associated libraries
foreach ($row in $table)
{
    try {
        $toDeleteUrl = $webUrl + $row.URL
        $folder = $web.GetFolder($toDeleteUrl)
        Write-Host "Deleting" $folder.Name
        $folder.Delete()
        Write-Host "Deleted Successfully" -ForegroundColor Green
    }
    catch{
        Write-Host "Folder does not exist or could not be deleted error to follow" -ForegroundColor Yellow
        Write-Host "Error Name - " + $_.Exception.ItemName
        Write-Host "Error Message: " + $_.Exception.Message
        # Deletion of parent folder already deleted this folder
    }
}