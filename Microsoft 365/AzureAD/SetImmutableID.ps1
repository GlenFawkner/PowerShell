#Remove duplicate synced user

#Remove-MSOLuser -UserPrincipalName waikato.maintenance@GoldenHomes.local -RemoveFromRecycleBin

#Add ImmutableID from AD user to Cloud user
$guid = (get-Aduser waikato.maintenance).ObjectGuid
$immutableID = [System.Convert]::ToBase64String($guid.tobytearray())

#Connect to AD Azure (Connect-MSOLService when AD Azure Powershell Module is installed).
Set-MSOLuser -UserPrincipalName waikato.maintenance@goldenhomes.co.nz -ImmutableID PzUYMq2gWUm4XErmYQ7ycA==


#empty recycle bin
Get-MsolUser -ReturnDeletedUsers | Remove-MsolUser -RemoveFromRecycleBin -Force