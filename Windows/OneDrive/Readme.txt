We need to prepare following informations first:

1, AZure AD Tenant ID, put it in ComputerSetup.ps1
2, Library ID for a SharePoint Site (How-to: https://docs.microsoft.com/en-us/onedrive/use-group-policy#AutoMountTeamSites) , fill it in UserSetup.ps1

To setup please do following
1, Extract files to c:\support\onedrive and keep current structure.
2, Run ComputerSetup.bat in admin mode. It will import REG key for SilentAccountConfig,  KFMSilentOptIn (Folder Redirection) and FilesOnDemandEnabled. This batch file will also copy UserSetup.bat to Startup folder so it will load when user logs in.
3, During user login, UserSetup.bat will run to check OneDrive version, load team site, import monitoring job and create a shortcut on desktop.

