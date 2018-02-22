# This script syncs the mobile number from AzureAD to SharePoint user

Import-Module MSOnline
Import-Module Microsoft.Online.SharePoint.PowerShell

# add SharePoint CSOM libraries
Import-Module 'C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll'
Import-Module 'C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll'
Import-Module 'C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll'

# Defaults
$spoAdminUrl = Read-Host -Prompt "SPO Admin URL"

# Get credentials of account that is AzureAD Admin and SharePoint Online Admin
$credential = Get-Credential

Try {
    # Connect to AzureAD
    Connect-MsolService -Credential $credential

    # Get credentials for SharePointOnline
    $spoCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($credential.GetNetworkCredential().Username, (ConvertTo-SecureString $credential.GetNetworkCredential().Password -AsPlainText -Force))
    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($spoAdminUrl)
    $ctx.Credentials = $spoCredentials
    $spoPeopleManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($ctx)

    # Get all AzureAD Users
    $AzureADUsers = Get-MSolUser -All

    ForEach ($AzureADUser in $AzureADUsers) {

        $mobilePhone = $AzureADUser.MobilePhone
        $targetUPN = $AzureADUser.UserPrincipalName.ToString()
        $targetSPOUserAccount = ("i:0#.f|membership|" + $targetUPN)

        # Check to see if the AzureAD User has a MobilePhone specified
        if (!([string]::IsNullOrEmpty($mobilePhone))) {
            $targetspoUserAccount = ("i:0#.f|membership|" + $AzureADUser.UserPrincipalName.ToString())
            $spoPeopleManager.SetSingleValueProfileProperty($targetspoUserAccount, "CellPhone", $mobilePhone)
            $ctx.ExecuteQuery()
            Write-Host "Updated $targetUPN CellPhone Property to $mobilePhone" -ForegroundColor Green
        }
        else {
            # AzureAD User MobilePhone is empty, nothing to do here
            Write-Host "AzureAD MobilePhone Property is Null or Empty for $targetUPN" -ForegroundColor Yellow
        }
    }
}
Catch {
    [Exception]
}

