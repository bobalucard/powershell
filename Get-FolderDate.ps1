param(
    [string] $StartWeb
     )

function GetWebSizes ($StartWeb)
{
    Get-SPWeb $StartWeb
    GetSubWebSizes -Web $web
    $web.Dispose()
}

function GetWebSize ($Web)
{
    $csvFile = ".\folderDates.csv"

    foreach ($folder in $Web.Folders)
    {
        $startdate = GetFolderDate -Folder $folder
        $appendCsv = $folder.ServerRelativeUrl + "`%" + $folder.DocumentLibrary.Title + "`%" + $startdate
        $appendCsv >> $csvFile
    }
}

function GetSubWebSizes ($Web)
{
    $csvFile = ".\folderDates.csv"

    foreach ($subweb in $Web.GetSubwebsForCurrentUser())
    {
        foreach ($folder in $subweb.Folders)
        {          
            $startdate = GetFolderDate -Folder $folder
            $appendCsv = $folder.ServerRelativeUrl + "`%" + $folder.DocumentLibrary.Title + "`%" + $startdate
            $appendCsv >> $csvFile
        }

        $subtotal = GetSubWebSizes -Web $subweb
    }
    return $subtotal
}

function GetFolderDate ($Folder)
{
    [datetime]$startdate = [datetime]"01/01/1900"

    foreach ($file in $Folder.Files)
    {
        if ((Get-Date $file.TimeLastModified) -gt $startdate)
            {
            $startdate = (Get-Date $file.TimeLastModified)
            }
    }

    foreach ($fd in $Folder.SubFolders)
    {

        $folderDate = GetFolderDate -Folder $fd
        $csvFile = ".\folderDates.csv"
        $appendCsv = $fd.ServerRelativeUrl + "`%" + $fd.DocumentLibrary.Title + "`%" + $startdate
        $appendCsv >> $csvFile

        if ((Get-Date $folderDate) -gt $startdate)
            {
            $startdate = (Get-Date $folderDate)
            }
    }


    return $startdate
}

$csvFile = ".\folderDates.csv"
$csvContent = "URL`%Library`%Date"
$csvContent >> $csvFile
GetWebSizes -StartWeb $StartWeb

