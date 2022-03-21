Param( 
  [Parameter(Mandatory=$True, 
             HelpMessage="`nEnter a local or remote hostname for the ComputerName parameter.`n  
Usage:  .\Get-TerminalServerLogins.ps1 -ComputerName localhost`n")] 
  [string]$ComputerName 
) 
 
$colEvents = Get-WinEvent -ComputerName $ComputerName -LogName "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" |  
Where {$_.ID -eq "21"} |  
Select -Property TimeCreated, Message 
Write-Host "Login Time,Username" 
Foreach ($Event in $colEvents) 
{ 
  $EventTimeCreated = $Event.TimeCreated 
  $EventMessage = $Event.Message -split "`n" | Select-Object -Index "2" 
  $EventMessageUser = $EventMessage.Substring(6) 
  Write-Host "$EventTimeCreated,$EventMessageUser" 
}