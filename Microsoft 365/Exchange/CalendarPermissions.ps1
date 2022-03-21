Get-Mailbox | ForEach-Object {add-MailboxFolderPermission $_”:\calendar” -User "CalendarAccess" -AccessRights Reviewer}

add-MailboxFolderPermission -Identity accounts@ngaiterangi.org.nz:\calendar -user "CalendarAccess" -AccessRights Reviewer

Get-MailboxFolderPermission -Identity accounts@ngaiterangi.org.nz:\calendar

New-DistributionGroup -Type Security -Name “Calendar Permissions” -Alias “CalendarAccess”

