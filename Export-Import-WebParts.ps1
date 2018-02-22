Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
function EnsureDirectory($exportFolderPath)
{
    if ( -not (Test-Path $exportFolderPath) ) {New-Item $exportFolderPath -Type Directory | Out-Null}
}
 
#example usage ./ExportWebParts.ps1 http://spdevel.portal.com/ Pages/default.aspx C:\temp\Export
function ExportAllWebParts($siteUrl,$pageUrl,$exportFolderPath)
{
    $web = Get-SPWeb $siteUrl
    $wpm = $web.GetLimitedWebPartManager($pageUrl, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
 
    EnsureDirectory $exportFolderPath
 
    foreach($wp in $wpm.WebParts)
    {
        $wp.ExportMode="All";
        $exportPath = $exportFolderPath + "\" + $wp.Title + ".xml"
        $xwTmp = new-object System.Xml.XmlTextWriter($exportPath,$null);
        $xwTmp.Formatting = 1;#Indent
        $wpm.ExportWebPart($wp, $xwTmp);
        $xwTmp.Flush();
        $xwTmp.Close();
    }
}


# AddWebParts takes the following items $webUrl="URL of Site", $webpartfile="Name of WebPart file i.e. Content_Editor_Right.dwp", $wpZoneName="Name of WebPart zone on the page", $saveFolder="Folder on local disk that WebPart file is saved to"
function AddWebParts ($webUrl, $webpartfile, $wpZoneName, $saveFolder, $projNum, $projName)
{
$web = Get-SPWeb $webURL

$fileDWP = $saveFolder + $webpartfile
$tmpFileDWP = $saveFolder + "tmp_" + $webpartfile
write-output "DWP File"  $fileDWP

(Get-Content $fileDWP) -replace '_ProjectFile_', "P$projNum" | Set-Content $tmpFileDWP
(Get-Content $tmpFileDWP) -replace '_ProjectName_', "$projNum - $projName" | Set-Content $tmpFileDWP

$fileDWP = $tmpFileDWP

[Microsoft.SharePoint.Publishing.PublishingWeb]$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web);  
$allowunsafeupdates = $web.AllowUnsafeUpdates  
$web.AllowUnsafeUpdates = $true

$page = $web.GetFile($webUrl + "/default.aspx")  
if ($page.CheckOutStatus -ne "None")    {  
#Check to ensure the page is checked out by same user, and if so, check it in  
    if ($page.CheckedOutBy.UserLogin -eq $web.CurrentUser.UserLogin)  
    {  
        $page.CheckIn("Page checked in automatically by PowerShell script")  
        Write-Output $page.Title"("$page.Name") has been checked in"  
    }  
}  
if ($page.CheckOutStatus -eq "None"){  
$page.CheckOut()  
#Get the webpart manager  
$webpartmanager = $web.GetLimitedWebPartManager($page.URL, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)  
}
 
#Getting the webpart gallery  
[Microsoft.SharePoint.SPList]$wpList = $web.Site.GetCatalog([Microsoft.SharePoint.SPListTemplateType]::WebPartCatalog)  
$fileStream = ([System.IO.FileInfo](Get-Item $fileDWP)).OpenRead()  
[Microsoft.SharePoint.SPFolder]$wpFolder = $wpList.RootFolder  
[Microsoft.SharePoint.SPFile]$wpFile = $wpFolder.Files.Add($webpartfile, $fileStream, $true)  
Write-host $wpFile  
 [System.Xml.XmlReader]$xmlReader = [System.Xml.XmlReader]::Create($wpFile.OpenBinaryStream())  
#Import the webpart  
$myCustomWP = $webpartmanager.ImportWebPart($xmlReader,[ref]"Error")  
Write-Output "My custom WebPart" $myCustomWP.title  
#If this webpart is not available on page then add it  
if(! $webpartmanager.WebParts.Contains($myCustomWP)){  
   $webpartmanager.AddWebPart($myCustomWP, $wpZoneName, "1")  
}

$page.CheckIn("Page checked in automatically by PowerShell script")   
$web.AllowUnsafeUpdates = $allowunsafeupdates  
$xmlReader.Close()  
$pubWeb.Close()  
$web.Dispose()

}