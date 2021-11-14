$acctName= Read-Host -Prompt 'Input admin account name'
$orgName=Read-Host -Prompt 'Input tennat name (Optional for SharePoint module use)'
#Azure Active Directory
Connect-MsolService
#SharePoint Online
#Connect-SPOService -Url https://$orgName-admin.sharepoint.com
#Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $acctName -ShowProgress $true
#Security & Compliance Center
Connect-IPPSSession -UserPrincipalName $acctName
