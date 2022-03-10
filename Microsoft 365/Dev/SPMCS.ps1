#Install required modules
Install-module AzureADPreview -f
Install-module MSOnline -f
Install-module ExchangeOnlineManagement -f
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -f
Import-module  SPModule

##Connect to Microsoft services
$orgName = Read-Host -Prompt 'Enter Admin SharePoint URL'
#Azure Active Directory
Connect-MsolService
#SharePoint Online
Connect-SPOService -Url $orgName
#Exchange Online
Connect-ExchangeOnline 
#Connect to AzureAD 
Connect-AzureAD

#Create temp directory
mkdir c:\temp

#Change directory
cd c:\temp

#Run reports
Get-GuestUsersLastSigIn
Get-MFAReport
Get-ForwardingReport
Get-SigninFailures 
Get-MailboxStorageReport
Get-MailboxPermissionsReport
Get-ExternalForwardingReport
Get-AdminRoles
Get-Externalusers
Get-spostoragereportusage