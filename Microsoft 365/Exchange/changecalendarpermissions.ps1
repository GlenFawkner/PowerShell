$LiveCred = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange-ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection


Import-PSSession $Session

Get-MailboxFolderPermission ConlinxxVisitorVan@nexuslogistics.nz:\Calendar

Set-MailboxFolderPermission -Identity "ConlinxxVisitorVan@nexuslogistics.nz:\Calendar" -User default -AccessRights PublishingAuthor

Set-CalendarProcessing -Identity "ConlinxxVisitorVan@nexuslogistics.nz" -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false

