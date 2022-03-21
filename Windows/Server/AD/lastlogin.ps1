﻿Get-ADUser -Filter * -SearchBase "dc=<domain>,dc=<local>" -ResultPageSize 0 -Prop CN,samaccountname,lastLogonTimestamp | Select CN,samaccountname,@{n="lastLogonDate";e={[datetime]::FromFileTime  
($_.lastLogonTimestamp)}} | Export-CSV -NoType <filepath>\<filename.csv>