#Connect to Office 365
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication  Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService
Write-Host "Connected to Office 365"

#Variables
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$mailbox = [Microsoft.VisualBasic.Interaction]::InputBox("Enter email address", "Change email to a shared account", "Email")

#change mailbox
Get-Mailbox -Identity $mailbox | Set-Mailbox -Type Shared

#disconnect session
Remove-PSSession $Session

Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
