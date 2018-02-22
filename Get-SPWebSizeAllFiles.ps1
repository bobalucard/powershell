param(
    [string] $StartWeb
     )

function GetWebSizes ($StartWeb)
{
    $web = Get-SPWeb $StartWeb
    [long]$total = 0
    $total += GetWebSize -Web $web
    $total += GetSubWebSizes -Web $web
    $totalInMb = ($total/1024)/1024
    $totalInMb = "{0:N2}" -f $totalInMb
    $totalInGb = (($total/1024)/1024)/1024
    $totalInGb = "{0:N2}" -f $totalInGb
    write-host "Total size of all sites below" $StartWeb "is" $total "Bytes,"
    write-host "which is" $totalInMb "MB or" $totalInGb "GB"
    $web.Dispose()
}

function GetWebSize ($Web)
{
    write-host "Getting size for - Site" $Web.Title
    [long]$subtotal = 0
    foreach ($folder in $Web.Folders)
    {
        $folderSize = GetFolderSize -Folder $folder
        write-host "Size of folder" $folder " is " (($folderSize/1024)/1024) "MB"
        $subtotal += $folderSize
    }
    write-host "Site" $Web.Title "is" $subtotal "KB"
    return $subtotal
}

function GetSubWebSizes ($Web)
{
    $csvFile = ".\webSizes.csv"
    $csvContent = "URL`%Folder Name`%Size`%Date"
    [long]$subtotal = 0
    foreach ($subweb in $Web.GetSubwebsForCurrentUser())
    {
        write-host "Getting size for - Sub Site" $subweb.Title
        [long]$webtotal = 0
        foreach ($folder in $subweb.Folders)
        {          
            $folderSize = GetFolderSize -Folder $folder
            write-host "Size of folder" $folder.Title " is " $folderSize "Bytes"
            "Size of folder" + $folder.Title + " is " + $folderSize + "Bytes" >> $csvFile
            $webtotal += $folderSize
        }
        write-host "Site" $subweb.Title "is" $webtotal "Bytes"

        "Site" + $subweb.Title + "is" + $webtotal + "Bytes" >> $csvFile
        $subtotal += $webtotal
        $subtotal += GetSubWebSizes -Web $subweb
    }
    return $subtotal
}

function GetFolderSize ($Folder)
{
    [long]$folderSize = 0
    [datetime]$startdate = [datetime]"01/01/1900"
    foreach ($file in $Folder.Files)
    {
        if ((Get-Date $file.TimeLastModified) -gt $startdate){$startdate = (Get-Date $file.TimeLastModified)}
            #Get file size
            $fileSize =  $file.TotalLength;
        
            #Get the Versions Size
            foreach ($FileVersion in $file.Versions)
            {
                $fileSize += $FileVersion.Size
            }
    $csvFile = ".\webSizesAllFiles.csv"
    $appendCsv = $file.ServerRelativeUrl + "`%" + ($fileSize/1024) + "`%" + $file.TimeLastModified
    $appendCsv >> $csvFile
    }

    foreach ($fd in $Folder.SubFolders)
    {
        if($fd.Name -ne "Forms") #Leave "Forms" Folder which has List default Aspx Pages.
        {
            $folderSize += GetFolderSize -Folder $fd
        }
    }


    return $folderSize
}



$csvFile = ".\webSizesAllFiles.csv"
$csvContent = "URL`%Size`%Date"
$csvContent >> $csvFile
GetWebSizes -StartWeb $StartWeb



    
#    foreach ($file in $Folder.Files)
#    {
#        if ((Get-Date $file.TimeLastModified) -gt (Get-Date).adddays(-365))
#       {
#####            $fileSizeNew = $file.TotalLength;
#        
##        #Get the Versions Size
#        foreach ($FileVersion in $file.Versions)
#        {
#            $fileSizeNew += $FileVersion.Size
#        }

        #$lastMod = Get-Date $file.TimeLastModified -Format d
        #Write-Host $file " size is " $file.Length
        #if ($lastMod -gt $mostRecent){$mostRecent = $lastMod}
#        }
#    }