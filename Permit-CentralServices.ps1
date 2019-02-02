# Trust remote farm search and Managed Metadata services

Add-PSSnapin Microsoft.SharePoint.PowerShell

## Set variables
$farmId = Read-Host -Prompt "Enter FarmId" -AsSecureString
$mmsId = (Get-SPServiceApplication | where { $_.DisplayName -eq "Managed Metadata Service" }).Id 
$ssaId = (Get-SPServiceApplication | where { $_.DisplayName -eq "Search Service Application" }).Id 
$claimprovider = (Get-SPClaimProvider System).ClaimProvider
$principal = New-SPClaimsPrincipal -ClaimType "http://schemas.microsoft.com/sharepoint/2009/08/claims/farmid" -ClaimProvider $claimprovider -ClaimValue $farmId

## Give permission for the remote farm to the Application Load Balancing Service
$security = Get-SPTopologyServiceApplication | Get-SPServiceApplicationSecurity
Grant-SPObjectSecurity -Identity $security -Principal $principal -Rights "Full Control"
Get-SPTopologyServiceApplication | Set-SPServiceApplicationSecurity -ObjectSecurity $security

## Give permission for the remote farm to the Managed Metadata Service
$security = Get-SPServiceApplicationSecurity $mmsId
Grant-SPObjectSecurity -Identity $security -Principal $principal -Rights "Full Access to Term Store" 
Set-SPServiceApplicationSecurity $mmsId -ObjectSecurity $security

## Give permission for the remote farm to the Search Service Application
$security = Get-SPServiceApplicationSecurity $ssaId
Grant-SPObjectSecurity -Identity $security -Principal $principal -Rights "Full Control"
Set-SPServiceApplicationSecurity $ssaId -ObjectSecurity $security
