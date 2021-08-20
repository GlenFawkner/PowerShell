## Use this script to block sign-in for shared mailboxes
## You must connect to Exchange Online and Azure AD using Connect-EXOPSSession and Connect-MsolService before running this script


$SharedMailboxes = Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -Eq "SharedMailbox"}

Foreach ($user in $SharedMailboxes) {

Set-MsolUser -UserPrincipalName $user.UserPrincipalName -BlockCredential $true 

}


## End of script