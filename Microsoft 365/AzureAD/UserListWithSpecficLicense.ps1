#Get license SKUs
Get-MsolAccountSku

#Get Users with specfic license (adjust for required SKU) and export to CSV
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "INTUNE_A"} | Out-file C:\temp\intuneuser.csv
