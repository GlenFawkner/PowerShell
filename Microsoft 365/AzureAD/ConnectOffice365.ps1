$acctName="spt365@agtechnz.com"
$orgName="agtechnz.com"
#Azure Active Directory
Connect-MsolService
#SharePoint Online
#Connect-SPOService -Url https://$orgName-admin.sharepoint.com
#Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $acctName -ShowProgress $true
#Security & Compliance Center
Connect-IPPSSession -UserPrincipalName $acctName
#Teams and Skype for Business Online
