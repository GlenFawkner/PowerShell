$FriendlyNameHash=Get-Content -Raw -Path C:\Temp\LicenseFriendlyName.txt -ErrorAction Stop | ConvertFrom-StringData

Function Get_License_FriendlyName
{
 $FriendlyName=@()
 $LicensePlan=@()    
 #Convert license plan to friendly name 
 foreach($License in $Licenses) 
 {   
  $LicenseItem= $License -Split ":" | Select-Object -Last 1  
  $EasyName=$FriendlyNameHash[$LicenseItem]  
  if(!($EasyName))  
  {$NamePrint=$LicenseItem}  
  else  
  {$NamePrint=$EasyName} 
  $FriendlyName=$FriendlyName+$NamePrint
  $LicensePlan=$LicensePlan+$LicenseItem
 }
 $global:LicensePlans=$LicensePlan -join ","
 $global:FriendlyNames=$FriendlyName -join ","
}

Function Get_UserInfo
{
 $global:DisplayName=$_.DisplayName
 $global:UPN=$_.UserPrincipalName
 $global:Licenses=$_.Licenses.AccountSkuId 
 $SigninStatus=$_.BlockCredential
 if($SigninStatus -eq $False)
 {$global:SigninStatus="Enabled"}
 else{$global:SigninStatus="Disabled"}
 $global:Department=$_.Department
 $global:JobTitle=$_.Title
 if($Department -eq $null)
 {$global:Department="-"}
 if($JobTitle -eq $null)
 {$global:JobTitle="-"}
}

{
     $OutputCSVName="c:\temp\Office365LicenseUsageReport__$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
     Write-Host Generating Office 365 license usage report...
     $ProcessedCount=0
     Get-MsolAccountSku | foreach {
      $ProcessedCount++
      $AccountSkuID=$_.AccountSkuID
      $LicensePlan= $_.SkuPartNumber
      $SubscriptionState=Get-MsolSubscription
      Write-Progress -Activity "`n     Retrieving license info "`n"  Currently Processing: $LicensePlan"
      $EasyName=$FriendlyNameHash[$LicensePlan]  
      if(!($EasyName))  
      {$FriendlyName=$LicenseItem}  
      else  
      {$FriendlyName=$EasyName} 
      $Result = @{'AccountSkuId'=$AccountSkuID;'License Plan_Friendly Name'=$FriendlyName;'Active Units'=$_.ActiveUnits;'Consumed Units'=$_.ConsumedUnits }
      $Results = New-Object PSObject -Property $Result
      $Results |select-object 'AccountSkuId','License Plan_Friendly Name','Active Units','Consumed Units' | Export-Csv -Path $OutputCSVName -Notype -Append
     }
     $ActionFlag="Report"
     Open_OutputFile
    }

{
      $OutputCSVName="c:\temp\O365UserLicenseReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
      Write-Host Generating licensed users report...
      $ProcessedCount=0
      Get-MsolUser -All | where {$_.IsLicensed -eq $true} | foreach {
       $ProcessedCount++
       Get-dUserInfo
       Write-Progress -Activity "`n     Processed users count: $ProcessedCount "`n"  Currently Processing: $DisplayName"
       Get-License_FriendlyName
       $Result = @{'Display Name'=$Displayname;'UPN'=$upn;'License Plan'=$LicensePlans;'License Plan Friendly Name'=$FriendlyNames;'Account Status'=$SigninStatus;'Department'=$Department;'Job Title'=$JobTitle }
       $Results = New-Object PSObject -Property $Result
       $Results |select-object 'Display Name','UPN','License Plan','License Plan Friendly Name','Account Status','Department','Job Title' | Export-Csv -Path $OutputCSVName -Notype -Append
      }
      $ActionFlag="Report"
      Open_OutputFile
     }