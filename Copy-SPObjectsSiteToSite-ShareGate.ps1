#####################################################################################################
# if no parameters are provided application will request manual entry
#Get CSV file with columns titled FromURL, ToURL, ObjectOrSite, ObjectName and VersionLimit:
param (
[string]$csvFile = "$(Read-Host 'Settings CSV location [e.g. C:\sitestomigrate.csv]')",
[string]$FromUser = "$(Read-Host 'Source user account')",
[string]$FromPassword = "$(Read-Host 'Source password')",
[string]$ToUser = "$(Read-Host 'Destination user account')",
[string]$ToPassword = "$(Read-Host 'Destination password')"
)
#####################################################################################################


#load the CSV file into a table
$table = Import-Csv $csvFile

#Convert password strings into secure strings
$SecPassFrom = ConvertTo-SecureString $FromPassword -AsPlainText -Force
$SecPassTo = ConvertTo-SecureString $ToPassword -AsPlainText -Force


$reportNum = 1

Write-Host "Started at: " + Get-Date

foreach ($row in $table)
{
    $srcSite = Connect-Site -Url $row.FromURL -Username $FromUser -Password $SecPassFrom
    $dstSite = Connect-Site -Url $row.ToURL -Username $ToUser -Password $SecPassTo

    #set the amount of versions to be copied
    if ($row.VersionLimit -gt 0)
        {$versions = $row.VersionLimit}
    else {$versions = 1000}

    #Copy SharePoint Document library or list
    if ($row.ObjectOrSite -eq "Object")
    {
        $result = Copy-List -Name $row.ObjectName -SourceSite $srcSite -DestinationSite $dstSite -VersionLimit $versions -NoCustomPermissions -NoWorkflows -NoNintexWorkflowHistory -InsaneMode
    }
    # Copy SharePoint Site
    elseif ($row.ObjectOrSite -eq "Site")
    {
        $result = Copy-Site -Site $srcSite -DestinationSite $dstSite -Merge -Subsites -VersionLimit $versions -NoCustomPermissions -NoWorkflows -NoNintexWorkflowHistory -InsaneMode
    }
    # Copy individual files/folders
    elseif ($row.ObjectOrSite -eq "Content")
    {
        $srcList = Get-List -Name $row.ObjectName -Site $srcSite 
        $dstList = Get-List -Name $row.ToList -Site $dstSite 
        if($row.FromFolder -ne "")
        {
            $result = Copy-Content -SourceList $srcList -DestinationList $dstList -SourceFolder $row.FromFolder -InsaneMode
        }
        elseif($row.ToFolder -ne "") 
        {
            $result = Copy-Content -SourceList $srcList -DestinationList $dstList -DestinationFolder $row.ToFolder -InsaneMode
        }
        else 
        {
            $result = Copy-Content -SourceList $srcList -DestinationList $dstList -InsaneMode
        }
    }

    Export-Report $result -Path ".\CopyContentReports$reportNum.xlsx"
    $reportNum += 1
}

Write-Host "Finished at: " + Get-Date