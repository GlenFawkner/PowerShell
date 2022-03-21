$USERS = Import-Csv c:\temp\accessusers.csv

foreach ($user in $USERS) {

    $user = Add-MailboxPermission -Identity $user.mailbox -User $user.delegate -AccessRights  -InheritanceType All
    $user = Add-RecipientPermission $user.mailbox -AccessRights SendAs -Trustee $user.delegate -Confirm:$false
}
