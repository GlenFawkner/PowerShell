#Install SharePoint Powershell Module
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

#Enter Admin SharePoint URL 
$spadminURL = "https://skypointnz-admin.sharepoint.com"

#Connect to SharePoint Online
Connect-SPOService -Url $spadminURL

#Enter SharePoint site URL that will become the home site
$sphomesiteURL = "https://skypointnz.sharepoint.com"

#Set SharePoint home site
Set-SPOHomeSite -HomeSiteUrl $sphomesiteURL

