$DGName = "DDH Sub Contractors"
Get-DistributionGroupMember -Identity $DGName -ResultSize Unlimited | Select Name, PrimarySMTPAddress, RecipientType |
Export-CSV "C:\temp\0365.csv" -NoTypeInformation -Encoding UTF8