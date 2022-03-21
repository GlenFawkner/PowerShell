#Azure Active Directory
Connect-MsolService
#SharePoint Online
#Connect-SPOService -Url https://$orgName-admin.sharepoint.com
#Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline 
#Security & Compliance Center
Connect-IPPSSession
