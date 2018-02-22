# Add Wave16 references to SharePoint client assemblies and authenticate to Office 365 site - required for CSOM
Add-Type -Path (Resolve-Path "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll")
Add-Type -Path (Resolve-Path "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll")
Add-Type -Path (Resolve-Path "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.WorkflowServices.dll")
 
# Specify tenant admin and site URL
$SiteUrl = Read-Host -Prompt "Site URL"
$ListName = Read-Host -Prompt "Enter nist name"
$Username = Read-Host -Prompt "Enter username" 
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString


##########################################################################
#specify the workflow template name which you want to start an instance on
$WorkflowName = Read-Host -Prompt "Enter name of workflow" -AsSecureString
##########################################################################

# Connect to site
$ClientContext = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$ClientContext.Credentials = $credentials
$ClientContext.ExecuteQuery()
 
# Get List and List Items
$List = $ClientContext.Web.Lists.GetByTitle($ListName)
$ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
$ClientContext.Load($List)
$ClientContext.Load($ListItems)
$ClientContext.ExecuteQuery()

# Retrieve WorkflowService related objects
$WorkflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager($ClientContext, $ClientContext.Web)
$interopService = $WorkflowServicesManager.GetWorkflowInteropService()
$ClientContext.Load($interopService)
$ClientContext.ExecuteQuery()


 
# Retrieve WorkflowService related objects
$WorkflowAssociations = $List.WorkflowAssociations
$ClientContext.Load($WorkflowAssociations)
$ClientContext.ExecuteQuery()

	Write-Host $WorkflowAssociations.Name "----" $WorkflowAssociations.Id

		# Prepare Start Workflow Payload
		$Dict = New-Object 'System.Collections.Generic.Dictionary[System.String,System.Object]'
		# Loop List Items to Start Workflow
		For ($j=0; $j -lt $ListItems.Count; $j++){
		    $msg = [string]::Format("Starting workflow {0}, on ListItemId {1}", $WorkflowAssociations.Name, $ListItems[$j].Id)
		    Write-Host $msg
		    #Start Workflow on List Item
            $interopService.StartWorkflow($WorkflowAssociations.Name, [guid]::NewGuid(), $List.Id, $ListItems[$j]["GUID"], $Dict)
		    $ClientContext.ExecuteQuery()
		}
