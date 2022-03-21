#Set password never to expire
Get-MsolUser | Set-MsolUser –PasswordNeverExpires $true

#View password expiration status
Get-MSOLUser | Select UserPrincipalName, PasswordNeverExpires