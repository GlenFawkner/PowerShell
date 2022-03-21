#Disable mailbox
Get-User | Disable-Mailbox
Get-Mailbox -Arbitration | Disable-Mailbox -Arbitration -DisableLastArbitrationMailboxAllowed
Get-Mailbox -Monitoring | Disable-Mailbox

#Remove restore mailbox for disconnected or soft-deleted mailbox
Get-Mailbox | Get-MailboxStatistics | Where {$_.DisconnectReason -eq “Disabled” } |foreach {Remove-StoreMailbox -Database $_.database -Identity $_.mailboxguid -MailboxState Disabled}
Get-Mailbox | Get-MailboxStatistics | where {$_.DisconnectReason -eq “SoftDeleted”} |foreach {Remove-StoreMailbox -Database $_.database -Identity $_.mailboxguid -MailboxState SoftDeleted}

#Remove database:
Get-MailboxDatabase | Remove-MailboxDatabase

#Remove partner application configuration:
Get-PartnerApplication| Remove-PartnerApplication

#Confirm 
Get-Mailbox
Get-Mailbox -Arbitration
Get-Mailbox -Monitoring

#Uninstall Exchange
Setup /Mode:Uninstall /iacceptexchangeserverlicenseterms