function Trust-CentralFarm($primaryServer)
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell


    if (!(Get-SPTrustedRootAuthority "$primaryServer DMS Farm" -ErrorAction SilentlyContinue))
    {
        ## Export certificates from the local server and copy to central
        $rootCert = (Get-SPCertificateAuthority).RootCertificate
        $rootCert.Export("Cert") | Set-Content \\$primaryServer\c$\Installs\ConsumingFarmRoot.cer -Encoding byte

        $stsCert = (Get-SPSecurityTokenServiceConfig).LocalLoginProvider.SigningCertificate
        $stsCert.Export("Cert") | Set-Content \\$primaryServer\c$\Installs\ConsumingFarmSTS.cer -Encoding byte

        ## Export the certificates from the primary server to local and install
        $local = "C:\Installs\PublishingFarmRoot.cer"
        $remoteFunction = "function Export-Certs { Add-PSSnapin Microsoft.SharePoint.PowerShell;
        ((Get-SPCertificateAuthority).RootCertificate).Export(`"Cert`") | Set-Content $local -Encoding byte;
        [Void](New-SPTrustedRootAuthority `"$env:COMPUTERNAME Remote Root`" -Certificate (Get-PfxCertificate C:\Installs\ConsumingFarmRoot.cer));
        [Void](New-SPTrustedServiceTokenIssuer `"$env:COMPUTERNAME Remote STS`" -Certificate (Get-PfxCertificate C:\Installs\ConsumingFarmSTS.cer));
        };Export-Certs"

        invoke-command -ComputerName $primaryServer -ScriptBlock {Invoke-Expression -Command  "$args"} -ArgumentList $remoteFunction
        Write-Host "Completed installation of local certificates on $primaryServer" -ForegroundColor Yellow
        
        ## Copy central certificate back and trust locally
        Copy-Item -Path \\$primaryServer\c$\Installs\PublishingFarmRoot.cer -Destination .\PublishingFarmRoot.cer
        [Void](New-SPTrustedRootAuthority "$primaryServer DMS Farm" -Certificate (Get-PfxCertificate .\PublishingFarmRoot.cer))
        Write-Host "Completed installation of central certificates on $env:COMPUTERNAME" -ForegroundColor Yellow
    }
    else 
    {
        Write-Host "$primaryServer DMS Farm has already been trusted" -ForegroundColor Yellow
    }
    
    Write-Host "Trust complete" -ForegroundColor Green
}

function Publish-CentralServices($primaryServer)
{
    $remoteFunction = "Function Publish-CentralServices {
        Publish-SPServiceApplication -Identity (Get-SPServiceApplication | where { `$_.DisplayName -eq `"Managed Metadata Service`" }).Id
        Publish-SPServiceApplication -Identity (Get-SPServiceApplication | where { `$_.DisplayName -eq `"Search Service Application`" }).Id
        };
        Publish-CentralServices;"

        Invoke-Command -ComputerName $primaryServer -ScriptBlock {Invoke-Expression -Command  "$args"} -ArgumentList $remoteFunction
        Write-Host "Published central services for $primaryServer farm" -ForegroundColor Green

}

function Permit-CentralServices($primaryServer)
{
    ## Set variables
    $farmId = (Get-SPFarm).Id

    $remoteFunction = "Function Subscribe-CentralServices {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    `$mmsId = (Get-SPServiceApplication | where { `$_.DisplayName -eq `"Managed Metadata Service`" }).Id; 
    `$ssaId = (Get-SPServiceApplication | where { `$_.DisplayName -eq `"Search Service Application`" }).Id; 
    
    ## Give permission for the remote farm to the Application Load Balancing Service
    `$security = Get-SPTopologyServiceApplication | Get-SPServiceApplicationSecurity;
    `$claimprovider = (Get-SPClaimProvider System).ClaimProvider;`
    `$principal = New-SPClaimsPrincipal -ClaimType `"http://schemas.microsoft.com/sharepoint/2009/08/claims/farmid`" -ClaimProvider `$claimprovider -ClaimValue $farmId;
    Grant-SPObjectSecurity -Identity `$security -Principal `$principal -Rights `"Full Control`";
    Get-SPTopologyServiceApplication | Set-SPServiceApplicationSecurity -ObjectSecurity `$security;

    ## Give permission for the remote farm to the Managed Metadata Service
    `$security = Get-SPServiceApplicationSecurity `$mmsId;
    `$claimprovider = (Get-SPClaimProvider System).ClaimProvider;
    `$principal = New-SPClaimsPrincipal -ClaimType `"http://schemas.microsoft.com/sharepoint/2009/08/claims/farmid`" -ClaimProvider `$claimprovider -ClaimValue $farmId;
    Grant-SPObjectSecurity -Identity `$security -Principal `$principal -Rights `"Full Access to Term Store`"; 
    Set-SPServiceApplicationSecurity `$mmsId -ObjectSecurity `$security;

    ## Give permission for the remote farm to the Search Service Application;
    `$security = Get-SPServiceApplicationSecurity `$ssaId;
    `$claimprovider = (Get-SPClaimProvider System).ClaimProvider;
    `$principal = New-SPClaimsPrincipal -ClaimType `"http://schemas.microsoft.com/sharepoint/2009/08/claims/farmid`" -ClaimProvider `$claimprovider -ClaimValue $farmId;
    Grant-SPObjectSecurity -Identity `$security -Principal `$principal -Rights `"Full Control`";
    Set-SPServiceApplicationSecurity `$mmsId -ObjectSecurity `$security;
    };
    Subscribe-CentralServices;"

    Invoke-Command -ComputerName $primaryServer -ScriptBlock {Invoke-Expression -Command "$args"} -ArgumentList $remoteFunction
    Write-Host "Permissions for central services added for remote farm" -ForegroundColor Green
}


function Subscribe-CentralServices($primaryServer) {
    $topUrl = "https://" + $primaryServer + ":32844/Topology/topology.svc"
    Receive-SPServiceApplicationConnectionInfo -FarmUrl $topUrl
    New-SPMetadataServiceApplicationProxy -Name "Remote Managed Metadata Proxy" -Uri ((Receive-SPServiceApplicationConnectionInfo -FarmUrl $topUrl | where { $_.Name -eq "Managed Metadata Service"}).Uri).AbsoluteUri
    New-SPEnterpriseSearchServiceApplicationProxy -Name "Remote Search Service Proxy" -Uri ((Receive-SPServiceApplicationConnectionInfo -FarmUrl $topUrl | where { $_.Name -eq "Search Service Application"}).Uri).AbsoluteUri
}

$primaryServer = Read-Host "Enter hostname of central farm"

Trust-CentralFarm $primaryServer

Publish-CentralServices $primaryServer

Permit-CentralServices $primaryServer

Subscribe-CentralServices $primaryServer