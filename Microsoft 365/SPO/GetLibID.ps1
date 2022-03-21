$tenant = 'New Zealand Food Innovation Waikato' #Tenant name at the start of URL
$tenantId = 'dfa29462-0289-4240-96c1-ee490e1e0342' #Tenant ID, can be found in azure AD
$siteName = 'ds' #Sharepoint site name
$docLib = 'Formulas Archive' #Sharepoint Document Library

#Connection
##$cred = Get-Credential -UserName $username -Message "Password: $username"
##Connect-PnPOnline https://ruakuradairies-admin.sharepoint.com/ -SPOManagementShell

#Convert Tenant ID
$tenantId = $tenantId -replace '-','%2D'

#Convert Site ID
$PnPSite = Get-PnPSite -Includes Id | select id
$PnPSite = $PnPSite.Id -replace '-','%2D'
$PnPSite = '%7B' + $PnPSite + '%7D'

#Convert Web ID
$PnPWeb = Get-PnPWeb -Includes Id | select id
$PnPWeb = $PnPWeb.Id -replace '-','%2D'
$PnPWeb = '%7B' + $PnPWeb + '%7D'

#Convert List ID
$PnPList = Get-PnPList $docLib -Includes Id | select id
$PnPList = $PnPList.Id -replace '-','%2D'
$PnPList = '%7B' + $PnPList + '%7D'
$PnPList = $PnPList.toUpper()

$FULLURL = 'tenantId=' + $tenantId + '&siteId=' + $PnPSite + '&webId=' + $PnPWeb + '&listId=' + $PnPList + '&webUrl=https%3A%2F%2F' + $tenant + '%2Esharepoint%2Ecom%2Fsites%2F' + $siteName + '&version=1'

Write-Output 'List ID: ' $FULLURL