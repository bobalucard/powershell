param(
    [string] $User,
    [string] $Url
     )

#Download and install ther latest version of the SharePoint Server 2013 Client Components SDK, this can be downloaded from here: http://www.microsoft.com/en-us/download/details.aspx?id=35585
#Load the CSOM assemblies required to manage SharePoint online.
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"


#Load a context - Used to load the SharePoint online site 
$SPOPassword = Read-Host -Prompt "Please enter password for $User" -AsSecureString
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($User,$SPOPassword)
$Context.RequestTimeout = 16384000
$Context.Credentials = $Credentials
$Context.ExecuteQuery()


# Load the web application from the context defined above
$Web = $Context.Web
$Context.Load($Web)
$Context.ExecuteQuery()

# Get SharePoint Online document library
$SPODocLibName = "Documents"
$SPOList = $Web.Lists.GetByTitle($SPODocLibName)
$Context.Load($SPOList.RootFolder)
$Context.ExecuteQuery()
$SPOList.RootFolder
# Create a new folder in list
$SPOFolder = $SPOList.RootFolder
$FolderName = $LocalFolder.Name
$NewFolder = $SPOFolder.Folders.Add($FolderName)
$Web.Context.Load($NewFolder)
$Web.Context.ExecuteQuery()
