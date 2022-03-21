$USERS = Import-Csv C:\Temp\focusedusers.csv

foreach($user in $USERS) {

 $user = Set-FocusedInbox -Identity $user.Email -FocusedInboxOn $false
}