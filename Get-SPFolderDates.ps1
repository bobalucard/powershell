param(
    [string] $StartWeb
     )

function GetWebSizes ($StartWeb)
{
    $web = Get-SPWeb $StartWeb
    GetSubWebSizes -Web $web
    $web.Dispose()
}

function GetSubWebSizes ($Web)
{
    $csvFile = ".\folderDates.csv"

    foreach ($subweb in $Web.GetSubwebsForCurrentUser())
    {
        foreach ($folder in $subweb.Folders)
        {          
            $startdate = GetFolderDate -Folder $folder
            $appendCsv = $folder.ServerRelativeUrl + "`%" + $folder.DocumentLibrary.Title + "`%" + (Get-Date $startdate -Format d)
            $appendCsv >> $csvFile
        }

        GetSubWebSizes -Web $subweb
    }
}

function GetFolderDate ($Folder)
{
    [datetime]$subFolderDate = [datetime]"01/01/1900"

    foreach ($fd in $Folder.SubFolders)
    {
        $folderDate = GetFolderDate -Folder $fd

        if ((Get-Date $folderDate) -gt $subFolderDate)
            {
            $subFolderDate = (Get-Date $folderDate)
            }

        $csvFile = ".\folderDates.csv"
        $appendCsv = $fd.ServerRelativeUrl + "`%" + $fd.DocumentLibrary.Title + "`%" + (Get-Date $subFolderDate -Format d)
        $appendCsv >> $csvFile
    }

    foreach ($file in $Folder.Files)
    {
        if ((Get-Date $file.TimeLastModified) -gt $subFolderDate)
            {
            $subFolderDate = (Get-Date $file.TimeLastModified)
            }
    }


    return $subFolderDate
}

$csvFile = ".\folderDates.csv"
$csvContent = "URL`%Library`%Date"
$csvContent >> $csvFile
GetWebSizes -StartWeb $StartWeb

