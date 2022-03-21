Import-Module ActiveDirectory

##Get-ADUserLastLogon -UserName "spereira"

$Users= Get-ADUser -Filter * -Properties Name, EmailAddress -SearchBase "ou=AKL_Email_Export,ou=AKL,ou=Disabled Accounts,dc=kingstons,dc=local" |Select-Object Name,EmailAddress
Write-Host $Users.count


foreach ($User in $Users)
    {
        $filename=$User.Name
        get-MailboxExportRequest -Mailbox $User.EmailAddress 
    }