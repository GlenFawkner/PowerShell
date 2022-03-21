#Check Password Expiring
#Get-MSOLUser | Select UserPrincipalName, PasswordNeverExpires


#Set Password never to expire
#Get-MsolUser | Set-MsolUser –PasswordNeverExpires $true