#Set Execution Policy
Set-ExecutionPolicy Unrestricted

##Create BKPMaster 
$Password = Read-Host 'Enter BKPMaster Admin Password' -AsSecureString
Write-host 'Creating Local BKPMaster'
New-LocalUser "bkpmaster" -Password $Password -FullName "SkyPoint Backup Master" -Description "Local Backup Account 1" -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "bkpmaster"

##Create BKPMaster2 
$Password = Read-Host 'Enter BKPMaster2 Admin Password' -AsSecureString
Write-host 'Creating Local BKPMaster2'
New-LocalUser "bkpmaster2" -Password $Password -FullName "SkyPoint Backup Master 2" -Description "Local Backup Account 2" -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "bkpmaster2"

##Create Client BKPMaster 
$ClientCode = Read-Host 'Enter Client Codein Lower Case'
$Password = Read-Host 'Enter Client Backup Admin Password' -AsSecureString
Write-host 'Creating Local Client Backup Account'
New-LocalUser ($ClientCode + "backup") -Password $Password -FullName "Client Backup Master" -Description "Local Client Backup Account" -PasswordNeverExpires


Pause