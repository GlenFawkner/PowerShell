#check Dirsync Status 
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled

#Enable Dirsync 
#Set-MsolDirSyncEnabled -EnableDirSync $true

#Disable Dirsync 
#Set-MsolDirSyncEnabled -EnableDirSync $false