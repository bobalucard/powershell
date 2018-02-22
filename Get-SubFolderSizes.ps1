Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
# Function to calculate Library size
Function GetLibrarySize($Folder)
{
    $FolderSize = 0
    foreach ($File in $Folder.Files)
    {
        #Get File Size
        $FolderSize += $File.TotalLength;
        
        #Get the Versions Size
        foreach ($FileVersion in $File.Versions)
        {
            $FolderSize += $FileVersion.Size
        }
    }
 
      #Get Files in Sub Folders
        foreach ($SubFolder in $Folder.SubFolders)
        {
           if($SubFolder.Name -ne "Forms") #Leave "Forms" Folder which has List default Aspx Pages.
             {
                 $subFolderSize = GetSubFolderSize($SubFolder)
                 Write-Host "Folder " $SubFolder " size" ([Math]::Round(($subFolderSize/1MB),2)) "MB"
                 $FolderSize += $subFolderSize
             }
        }
 
       return [Math]::Round(($FolderSize/1MB),2)
}

Function GetSubFolderSize($Folder)
{
    $FolderSize = 0
    foreach ($File in $Folder.Files)
    {
        #Get File Size
        $FolderSize += $File.TotalLength;
 
        #Get the Versions Size
        foreach ($FileVersion in $File.Versions)
        {
            $FolderSize += $FileVersion.Size
        }
    }
 
      #Get Files in Sub Folders
       foreach ($SubFolder in $Folder.SubFolders)
        {
           if($SubFolder.Name -ne "Forms") #Leave "Forms" Folder which has List default Aspx Pages.
             {
                 $FolderSize += GetLibrarySize($SubFolder)
             }
       }
 
       return [Math]::Round(($FolderSize/1MB),2)
}
$url = Read-Host -Prompt "Site URL"
$Web = Get-SPWeb $url
$list = Read-Host -Prompt "List Name"
 
#Get the Library's Root Folder
$Library =  $Web.Lists[$list].RootFolder
 
#Call the function to Calculate Size
$LibrarySize=GetLibrarySize($Library)
 
Write-Host "Library Size:" $LibrarySize "MB"