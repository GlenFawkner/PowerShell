$USERS = Import-Csv C:\Support\elusers.csv

foreach ($user in $USERS) {

    $user = New-MsolUser -UserPrincipalName $user.Emailaddress  -DisplayName ($user.Firstname + $user.Lastname) -FirstName $user.Firstname -LastName $user.Lastname -StreetAddress $user.StreetAddress -Department $user.Department -Password $user.password

}