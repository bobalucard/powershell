Add-PSSnapin Microsoft.SharePoint.PowerShell

$featureIds = @('IDs of Features to remove')
$siteIds = @('IDs of Sites to remove from')

foreach ( $id in $siteIds )
{
    $site = Get-SPSite -Limit all | where { $_.Id -eq $id }
    Write-Host "Found site: " $site -ForegroundColor Green
    Write-Host "Searching web: " $web -ForegroundColor Green 
    foreach ( $featureId in $featureIds )
    {
        try
        {
            $webFeature = $site.Features[$featureId]
            $site.Features.Remove($webFeature.DefinitionId, $true)
            Write-Host "Feature removed: " $featureId -ForegroundColor DarkGreen
        }
        catch
        {
            Write-Host "Feature not found: " $featureId -ForegroundColor Yellow
        }
    }

    $webs = $site | Get-SPWeb -Limit all
    foreach ( $web in $webs )
    {
        Write-Host "Searching web: " $web -ForegroundColor Green 
        foreach ( $featureId in $featureIds )
        {
            try
            {
                $webFeature = $web.Features[$featureId]
                $web.Features.Remove($webFeature.DefinitionId, $true)
                Write-Host "Feature removed: " $featureId -ForegroundColor DarkGreen
            }
            catch
            {
                Write-Host "Feature not found: " $featureId -ForegroundColor Yellow
            }
        }
    }
}