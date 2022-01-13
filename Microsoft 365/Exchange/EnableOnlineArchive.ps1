#Enabled single mailbox archive
#Enable-Mailbox -Identity "<user>" -Archive

#Enable archive for all mailboxes
#Get-Mailbox -Filter {ArchiveStatus -Eq "None" -AND RecipientTypeDetails -eq "UserMailbox"} | Enable-Mailbox -Archive