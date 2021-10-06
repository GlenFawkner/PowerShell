#Install ORCA - Office 365 Recommended Configuration Analyzer
Install-Module ORCA

#Connect to Exchange Online 
Connect-ExchangeOnline

#Run ORCA report
Get-ORCAReport
#This will be exported into the appdata/local/Microsoft/ORCA folder
