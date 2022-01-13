##Connect to Microsoft services
$orgName = Read-Host -Prompt 'Enter Admin SharePoint URL'
#Azure Active Directory
Connect-MsolService
#SharePoint Online
Connect-SPOService -Url $orgName
#Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline 
#Security & Compliance Center
Connect-IPPSSession


#Import Modules
Import-Module getadminroles
Import-Module GetMFAReport
Import-Module GetForwardingReport
#Import-Module getexternalusers

#Export admin roles report
Get-AdminRoles

#Export MFA report
Get-MFAReport

#Export forwarding report
get-forwardingreport



