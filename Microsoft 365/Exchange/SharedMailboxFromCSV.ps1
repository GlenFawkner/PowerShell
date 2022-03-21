$File = Import-CSV C:\Users\Glen.Fawkner\Desktop\shared.csv 

$File | ForEach {
 
    New-Mailbox -Name "" -PrimarySmtpAddress "" -Shared
 
 }