Import-Module ActiveDirectory


 
$Resetpassword = Import-Csv -Path c:\temp\users.csv
 
foreach ($Account in $Resetpassword) {
    $Account.sAMAccountName
    $Account.Password
        Set-ADAccountPassword -Identity $Account.sAMAccountName -NewPassword (ConvertTo-SecureString $Account.Password -AsPlainText -force) -Reset
}