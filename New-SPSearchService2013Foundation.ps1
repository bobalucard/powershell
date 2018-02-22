#Start the search service instance on the server
Start-SPEnterpriseSearchServiceInstance $env:computername 
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $env:computername
 
#Give a unique name to your search service application
$serviceAppName = "Search Service Application"

$appPoolname = Read-Host "appPool name to use"
#Get the application pools to use (make sure you change the value for your environment) 
$svcPool = Get-SPServiceApplicationPool "$appPoolname" 
$adminPool = Get-SPServiceApplicationPool "$appPoolname"
 
#Get the service from the service instance so we can call a method on it
$searchServiceInstance = Get-SPEnterpriseSearchServiceInstance –Local
$searchService = $searchServiceInstance.Service

$dbNameBase = Read-Host "Db name to create"
#Define your unique DB names without the guids
$adminDB = $dbNameBase
$propertyStoreDB = $dbNameBase + "_PropertyStoreDB"
$crawlStoreDB = $dbNameBase + "_CrawlStoreDB"
$analysticsStoreDB = $dbNameBase + "_AnalyticsStoreDB"
$linkStoreDB = $dbNameBase + "_LinkStoreDB"
 
#Since this method takes in the value of object type Microsoft.SharePoint.Administration.SPDatabaseParameters we will create these from our clean DB names
$adminDBParameters = [Microsoft.SharePoint.Administration.SPDatabaseParameters]::CreateParameters($adminDB,"None")
$propertyDBParameters = [Microsoft.SharePoint.Administration.SPDatabaseParameters]::CreateParameters($propertyStoreDB,"None")
$crawlStoreDBParameters = [Microsoft.SharePoint.Administration.SPDatabaseParameters]::CreateParameters($crawlStoreDB,"None")
$analyticsStoreDBParameters = [Microsoft.SharePoint.Administration.SPDatabaseParameters]::CreateParameters($analysticsStoreDB,"None")
$linkStoreDBParameters = [Microsoft.SharePoint.Administration.SPDatabaseParameters]::CreateParameters($linkStoreDB,"None")
 
#Create the search service application by calling the function
$searchServiceApp = $searchService.CreateApplication($serviceAppName, $adminDBParameters, $propertyDBParameters, $crawlStoreDBParameters, $analyticsStoreDBParameters, $linkStoreDBParameters, [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool]$svcPool, [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool]$adminPool)
 
#Create the search service application proxy as usual (luckily PowerShell for this works and is bot blocked)
$searchProxy = New-SPEnterpriseSearchServiceApplicationProxy -Name "$serviceAppName Proxy" -SearchApplication $searchServiceApp
#Provision the search service application 
$searchServiceApp.Provision()

#Get an updated handle on the SearchServiceInstance
$searchServiceInstance = Get-SPEnterpriseSearchServiceInstance –Local
#Now we will call the method to initiate the default topology component creation using reflection
$bindings = @("InvokeMethod", "NonPublic", "Instance")
$types = @([Microsoft.Office.Server.Search.Administration.SearchServiceInstance])
$values = @([Microsoft.Office.Server.Search.Administration.SearchServiceInstance]$searchServiceInstance)
$methodInfo = $searchServiceApp.GetType().GetMethod("InitDefaultTopology", $bindings, $null, $types, $null) 
$searchTopology = $methodInfo.Invoke($searchServiceApp, $values)