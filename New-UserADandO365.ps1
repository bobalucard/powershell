Write-Host "Create new user in Active Directory and Exchange Online"
$firstName = Read-Host "Enter first name"
$lastName = Read-Host "Enter last name"
$domainName = Read-Host "Enter email domain name"
$newPassword = Read-Host "Enter new password"

New-ADUser -Name "$firstName $lastName" -GivenName $firstName -Surname $lastName -SamAccountName "$firstName.$lastName" -UserPrincipalName "$firstName.$lastName@$domainName" -AccountPassword (ConvertTo-SecureString -String $newPassword -AsPlainText -Force) -PassThru | Enable-ADAccount

Write-Host "Enter admin credentials for Exchange Online"
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

New-Mailbox -Alias "$firstName.$lastName" -Name "$firstName.$lastName" -FirstName $firstName -LastName $lastName -DisplayName "$firstName $lastName" -MicrosoftOnlineServicesID "$firstName.$lastName@$domainName" -Password (ConvertTo-SecureString -String $newPassword -AsPlainText -Force) -ResetPasswordOnNextLogon $true