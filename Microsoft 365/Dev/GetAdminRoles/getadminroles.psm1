function Get-AdminRoles {

param ( 
[string] $UserName = $null, 
[string] $Password = $null, 
[switch] $RoleBasedAdminReport, 
[String] $AdminName = $null, 
[String] $RoleName = $null) 

Write-Host "Preparing admin report..." 
$admins=@() 
$list = @() 
$outputCsv=".\AdminReport_$((Get-Date -format MMM-dd` hh-mm` tt).ToString()).csv" 

function process_Admin{ 
$roleList= (Get-MsolUserRole -UserPrincipalName $admins.UserPrincipalName | Select-Object -ExpandProperty Name) -join ',' 
if($admins.IsLicensed -eq $true)
 { 
$licenseStatus = "Licensed" 
 }
else
  { 
$licenseStatus= "Unlicensed" 
  } 
if($admins.BlockCredential -eq $true)
 { 
$signInStatus = "Blocked" 
 }
else
  { 
$signInStatus = "Allowed" 
  } 
$displayName= $admins.DisplayName 
$UPN= $admins.UserPrincipalName 
Write-Progress -Activity "Currently processing: $displayName" -Status "Updating CSV file"
if($roleList -ne "") 
 { 
$exportResult=@{'AdminEmailAddress'=$UPN;'AdminName'=$displayName;'RoleName'=$roleList;'LicenseStatus'=$licenseStatus;'SignInStatus'=$signInStatus} 
$exportResults= New-Object PSObject -Property $exportResult         
$exportResults | Select-Object 'AdminName','AdminEmailAddress','RoleName','LicenseStatus','SignInStatus' | Export-csv -path c:\temp\adminroles.csv -NoType -Append  
  } 
} 

function process_Role{ 
$adminList = Get-MsolRoleMember -RoleObjectId $roles.ObjectId #Email,DisplayName,Usertype,islicensed 
$displayName = ($adminList | Select-Object -ExpandProperty DisplayName) -join ',' 
$UPN = ($adminList | Select-Object -ExpandProperty EmailAddress) -join ',' 
$RoleName= $roles.Name 
Write-Progress -Activity "Processing $RoleName role" -Status "Updating CSV file"
if($displayName -ne "")
 { 
$exportResult=@{'RoleName'=$RoleName;'AdminEmailAddress'=$UPN;'AdminName'=$displayName} 
$exportResults= New-Object PSObject -Property $exportResult 
$exportResults | Select-Object 'RoleName','AdminName','AdminEmailAddress' | Export-csv -path c:\temp\adminroles.csv -NoType -Append 
 } 
} 

#Check to generate role based admin report
if($RoleBasedAdminReport.IsPresent)
{ 
Get-MsolRole | ForEach-Object { 
$roles= $_        #$ObjId = $_.ObjectId;$_.Name 
process_Role 
 } 
}

#Check to get admin roles for specific user
elseif($AdminName -ne "")
{ 
$allUPNs = $AdminName.Split(",") 
ForEach($admin in $allUPNs) 
 { 
$admins = Get-MsolUser -UserPrincipalName $admin -ErrorAction SilentlyContinue 
if( -not $?)
  { 
Write-host "$admin is not available. Please check the input" -ForegroundColor Red 
  }
else
  { 
process_Admin 
  } 
 } 
}

#Check to get all admins for a specific role
elseif($RoleName -ne "")
{ 
$RoleNames = $RoleName.Split(",") 
ForEach($name in $RoleNames) 
 { 
$roles= Get-MsolRole -RoleName $name -ErrorAction SilentlyContinue 
if( -not $?)
  { 
Write-Host "$name role is not available. Please check the input" -ForegroundColor Red 
  }
else
  { 
process_Role 
  } 
 } 
}

#Generating all admins report
else
 { 
Get-MsolUser -All | ForEach-Object  { 
$admins= $_ 
process_Admin 
 } 
} 
write-Host "`nThe script executed successfully" 
                                            
}
Export-ModuleMember -Function Get-AdminRoles