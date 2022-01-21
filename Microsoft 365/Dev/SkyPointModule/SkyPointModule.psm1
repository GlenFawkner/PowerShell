##Gets friendly M365 license names
###################################################################
Function Get-License_FriendlyName
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

##Gets user information
###################################################################
Function Get-UserInfo
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

##Gets accounts with admin roles
###################################################################
function Get-AdminRoles 
{

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
$exportResults | Select-Object 'AdminName','AdminEmailAddress','RoleName','LicenseStatus','SignInStatus' | Export-csv -path .\adminroles.csv -NoType -Append  
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
$exportResults | Select-Object 'RoleName','AdminName','AdminEmailAddress' | Export-csv -path .\adminroles.csv -NoType -Append 
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

##Gets external users
###################################################################
function Get-Externalusers 
{
param (
    [string] $UserName = $null,
    [string] $Password = $null,
    [Int] $GuestsCreatedWithin_Days,
    [Switch] $SiteWiseGuest,
    [Parameter(Mandatory = $True)]
    [string] $HostName = $null
       
)


#This function checks the user choice and get the guest user data
Function FindGuestUsers {
    $AllGuestUserData = @()
    $global:ExportCSVFileName = "SPOExternalUsersReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 

    #Checks the SPO Sites and lists the guest users
    if ($SiteWiseGuest.IsPresent) {
        $GuestDataAvailable = $false
        Get-SPOSite | foreach-object {
            $CurrSite = $_
            Write-Progress "Finding the guest users in the site: $($CurrSite.Url)" "Processing the sites with guest users..."
            #Fiters the sites with guest users
            Get-SPOUser -Site $CurrSite.Url | where-object { $_.LoginName -like "*#ext#*" -or $_.LoginName -like "urn:spo:guest#*"} | foreach-object {
                    $global:ExportedGuestUser = $global:ExportedGuestUser + 1    
                    $CurrGuestData = $_
                    ExportGuestsAndSitesData
                }
        }
        if ($global:ExportedGuestUser -eq 0) {
            Write-Host "No SharePoint Online guests in any SharePoint Online sites in your tenant" -ForegroundColor Magenta
        }
    }
   
    #Checks the guest user acount creation within the mentioned days and retrieves it
    elseif ($GuestsCreatedWithin_Days -gt 0) {
        $AccountCreationDate = (Get-date).AddDays(-$GuestsCreatedWithin_Days).Date
        for (($i = 0), ($errVar = @()); (($errVar.Count) -eq 0); $i += 50) {
        Get-SPOExternalUser -Position $i -PageSize 50 -ErrorAction SilentlyContinue -ErrorVariable errVar | where-object { $_.WhenCreated -ge $AccountCreationDate } | foreach-object {
                $global:ExportedGuestUser = $global:ExportedGuestUser + 1   
                $CurrGuestData = $_
                ExportGuestUserDetails
            }
        }
        if ($global:ExportedGuestUser -eq 0) {
            Write-host "No SharePoint Online guests created in last $GuestsCreatedWithin_Days days" -ForegroundColor Magenta
        }
    }

    #Returns all SPO guest users in your tenant
    else {
        for (($i = 0), ($errVar = @()); (($errVar.Count) -eq 0); $i += 50) {
            Get-SPOExternalUser -Position $i -PageSize 50 -ErrorAction SilentlyContinue -ErrorVariable errVar | ForEach-Object {
                $global:ExportedGuestUser = $global:ExportedGuestUser + 1   
                $CurrGuestData = $_
                ExportGuestUserDetails
            }
        }
        if ($global:ExportedGuestUser -eq 0) {
            Write-Host "No SharePoint Online guest users found in your tenant." -ForegroundColor Magenta
        }
    }
}

#Saves site-wise guest user data
Function ExportGuestsAndSitesData {
    $SiteName = $CurrSite.Title
    $SiteUrl = $CurrSite.Url
    $GuestDisplayName = $CurrGuestData.DisplayName
    $GuestEmailAddress = $CurrGuestData.LoginName
    if($GuestEmailAddress -like "*ext*"){
    $GuestDomain = ($CurrGuestData.LoginName).split("_#") | Select-Object -Index 1
    }
    else{
    $GuestDomain = ($CurrGuestData.LoginName).split("@") | Select-Object -Index 1
    }
    
    $ExportResult = @{'Guest User' = $GuestDisplayName; 'Email Address' = $GuestEmailAddress; 'Site Name' = $SiteName; 'Site Url' = $SiteUrl; 'Guest Domain' = $GuestDomain }
    $ExportResults = New-Object PSObject -Property $ExportResult
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Site Name', 'Site Url', 'Guest Domain' | Export-csv -path .\ExternalUserReport -NoType -Append -Force
      
}

#Saves guest user data
Function ExportGuestUserDetails {
    $GuestDisplayName = $CurrGuestData.DisplayName
    $GuestEmailAddress = $CurrGuestData.Email
    $GuestInviteAcceptedAs = $CurrGuestData.AcceptedAs
    $CreationDate = ($CurrGuestData.WhenCreated).ToString().split(" ") | Select-Object -Index 0
    $GuestDomain = ($CurrGuestData.Email).split("@") | Select-Object -Index 1
    
    Write-Progress "Retrieving the Guest User: $GuestDisplayName" "Processed Guest Users Count: $global:ExportedGuestUser"
   
    #Exports the guest user data to the csv file format

    $ExportResult = @{'Guest User' = $GuestDisplayName; 'Email Address' = $GuestEmailAddress; 'Invitation Accepted via' = $GuestInviteAcceptedAs; 'Created On' = $CreationDate; 'Guest Domain' = $GuestDomain }
    $ExportResults = New-Object PSObject -Property $ExportResult
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Created On', 'Invitation Accepted via', 'Guest Domain' | Export-csv -path .\ExternalUserReport -NoType -Append -Force
    
}

#Execution starts here.
ConnectSPOService
$global:ExportedGuestUser = 0
FindGuestUsers
}

##Gets forwarding rules on all accounts
###################################################################
function Get-Forwardingreport
{
param(
    [string] $UserName = $null,
    [string] $Password = $null,
    [Switch] $InboxRules,
    [Switch] $MailFlowRules
)


Function GetPrintableValue($RawData) {
    if (($null -eq $RawData) -or ($RawData.Equals(""))) {
        return "-";
    }
    else {
        $StringVal = $RawData | Out-String
        return $StringVal;
    }
}

Function GetAllMailForwardingRules {
    Write-host "Preparing the Email Forwarding Report..."
    if($InboxRules.IsPresent) {
        $global:ExportCSVFileName = "InboxRulesWithEmailForwarding_" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv"
        Get-Mailbox -ResultSize Unlimited | ForEach-Object { 
            Write-Progress "Processing the Inbox Rule for the User: $($_.Id)" " "
            Get-InboxRule -Mailbox $_.PrimarySmtpAddress | Where-Object { $_.ForwardAsAttachmentTo -ne $Empty -or $_.ForwardTo -ne $Empty -or $_.RedirectTo -ne $Empty} | ForEach-Object {
                $CurrUserRule = $_
                GetInboxRulesInfo
            }
        }
    }
    Elseif ($MailFlowRules.IsPresent) {
        $global:ExportCSVFileName = "TransportRulesWithEmailForwarding_" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv"
        Get-TransportRule -ResultSize Unlimited | Where-Object { $_.RedirectMessageTo -ne $Empty } | ForEach-Object {
            Write-Progress -Activity "Processing the Transport Rule: $($_.Name)" " "
            $CurrEmailFlowRule = $_
            GetMailFlowRulesInfo
        }
    } 
    else{
        $global:ExportCSVFileName = "EmailForwardingReport_" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv"
        Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ForwardingSMTPAddress -ne $Empty -or $_.ForwardingAddress -ne $Empty} | ForEach-Object {
            Write-Progress -Activity "Processing Mailbox Forwarding Rules for the User: $($_.Id)" " "
            $CurrEmailSetUp = $_
            GetMailboxForwardingInfo
        }
    }
}


Function GetMailboxForwardingInfo {
    $global:ReportSize = $global:ReportSize + 1
    $MailboxOwner = $CurrEmailSetUp.PrimarySMTPAddress
    $DeliverToMailbox = $CurrEmailSetUp.DeliverToMailboxandForward 
    if ($null -ne $CurrEmailSetUp.ForwardingSMTPAddress) {
        $CurrEmailSetUp.ForwardingSMTPAddress = GetPrintableValue (($CurrEmailSetUp.ForwardingSMTPAddress).split(":") | Select -Index 1)
    }
    $ForwardingSMTPAddress = GetPrintableValue $CurrEmailSetUp.ForwardingSMTPAddress
    if ($null -ne $CurrEmailSetUp.ForwardingAddress){
        $CurrEmailSetUp.ForwardingAddress = GetPrintableValue ($CurrEmailSetUp.ForwardingAddress)
    }
    $ForwardTo = GetPrintableValue $CurrEmailSetUp.ForwardingAddress
    
    #ExportResults
    $ExportResult = @{'Mailbox Name' = $MailboxOwner; 'Forwarding SMTP Address' = $ForwardingSMTPAddress;'Forward To' =$ForwardTo; 'Deliver To Mailbox and Forward' = $DeliverToMailbox}
    $ExportResults = New-Object PSObject -Property $ExportResult
    $ExportResults | Select-object 'Mailbox Name', 'Forwarding SMTP Address','Forward To','Deliver To Mailbox and Forward' | Export-csv -path .\ForwardingReport.csv -NoType -Append -Force 
}

Function GetInboxRulesInfo {
    $global:ReportSize = $global:ReportSize + 1
    $MailboxOwner = $CurrUserRule.MailboxOwnerId
    $RuleName = $CurrUserRule.Name
    $Enable = $CurrUserRule.Enabled
    $StopProcessingRules = $CurrUserRule.StopProcessingRules
    if ($null -ne $CurrUserRule.RedirectTo) {
        $CurrUserRule.RedirectTo = GetPrintableValue (($CurrUserRule.RedirectTo).split("[") | Select-Object -Index 0).Replace('"', '').Trim()
    }
    $RedirectTo = GetPrintableValue $CurrUserRule.RedirectTo
    if ($null -ne $CurrUserRule.ForwardAsAttachmentTo) {
        $CurrUserRule.ForwardAsAttachmentTo = GetPrintableValue (($CurrUserRule.ForwardAsAttachmentTo).split("[") | Select-Object -Index 0).Replace('"', '').Trim()
    }
    $ForwardAsAttachment = GetPrintableValue $CurrUserRule.ForwardAsAttachmentTo
    if ($null -ne $CurrUserRule.ForwardTo) {
        $CurrUserRule.ForwardTo = GetPrintableValue (($CurrUserRule.ForwardTo).split("[") | Select-Object -Index 0).Replace('"', '').Trim()
    }
    $ForwardTo = GetPrintableValue $CurrUserRule.ForwardTo
    
    #ExportResults
    $ExportResult = @{'Mailbox Name' = $MailboxOwner; 'Inbox Rule' = $RuleName; 'Rule Status' = $Enable; 'Forward As Attachment To' = $ForwardAsAttachment; 'Forward To' = $ForwardTo; 'Stop Processing Rules' = $StopProcessingRules; 'Redirect To' = $RedirectTo }
    $ExportResults = New-Object PSObject -Property $ExportResult
    $ExportResults | Select-object 'Mailbox Name', 'Inbox Rule', 'Forward To', 'Redirect To', 'Forward As Attachment To','Stop Processing Rules', 'Rule Status' | Export-csv -path .\ForwardingReport.csv -NoType -Append -Force 
}

Function GetMailFlowRulesInfo {
    $global:ReportSize = $global:ReportSize + 1
    $RuleName = $CurrEmailFlowRule.Name
    $State = $CurrEmailFlowRule.State
    $Mode = $CurrEmailFlowRule.Mode
    $Priority = $CurrEmailFlowRule.Priority
    $StopProcessingRules = $CurrEmailFlowRule.StopRuleProcessing
    if ($null -ne $CurrEmailFlowRule.RedirectMessageTo) {
        $CurrEmailFlowRule.RedirectMessageTo = GetPrintableValue ($CurrEmailFlowRule.RedirectMessageTo).Replace('{}', '').Trim()
    }
    $RedirectTo = $CurrEmailFlowRule.RedirectMessageTo
    
    #ExportResults
    $ExportResult = @{'Mail Flow Rule Name' = $RuleName; 'State' = $State; 'Mode' = $Mode; 'Priority' = $Priority; 'Redirect To' = $RedirectTo; 'Stop Processing Rule' = $StopProcessingRules}
    $ExportResults = New-Object PSObject -Property $ExportResult
    $ExportResults | Select-object 'Mail Flow Rule Name','Redirect To', 'Stop Processing Rule','State', 'Mode', 'Priority' | Export-csv -path .\ForwardingReport.csv -NoType -Append -Force 
}

GetAllMailForwardingRules
Write-Progress -Activity "--" -Completed
}

##Gets MFA status on accounts
###################################################################
function Get-MFAReport 
{
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$DisabledOnly,
    [switch]$EnabledOnly,
    [switch]$EnforcedOnly,
    [switch]$ConditionalAccessOnly,
    [switch]$AdminOnly,
    [switch]$LicensedUserOnly,
    [Nullable[boolean]]$SignInAllowed = $null,
    [string]$UserName,
    [string]$Password
)


#Output file declaration
$ExportCSV=".\MFADisabledUserReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
$ExportCSVReport=".\MFAEnabledUserReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"


#Loop through each user
Get-MsolUser -All | foreach{
 $UserCount++
 $DisplayName=$_.DisplayName
 $Upn=$_.UserPrincipalName
 $MFAStatus=$_.StrongAuthenticationRequirements.State
 $MethodTypes=$_.StrongAuthenticationMethods
 $RolesAssigned=""
 Write-Progress -Activity "`n     Processed user count: $UserCount "`n"  Currently Processing: $DisplayName"
 if($_.BlockCredential -eq "True")
 {
  $SignInStatus="False"
  $SignInStat="Denied"
 }
 else
 {
  $SignInStatus="True"
  $SignInStat="Allowed"
 }

 #Filter result based on SignIn status
 if(($SignInAllowed -ne $null) -and ([string]$SignInAllowed -ne [string]$SignInStatus))
 {
  return
 }

 #Filter result based on License status
 if(($LicensedUserOnly.IsPresent) -and ($_.IsLicensed -eq $False))
 {
  return
 }

 if($_.IsLicensed -eq $true)
 {
  $LicenseStat="Licensed"
 }
 else
 {
  $LicenseStat="Unlicensed"
 }

 #Check for user's Admin role
 $Roles=(Get-MsolUserRole -UserPrincipalName $upn).Name
 if($Roles.count -eq 0)
 {
  $RolesAssigned="No roles"
  $IsAdmin="False"
 }
 else
 {
  $IsAdmin="True"
  foreach($Role in $Roles)
  {
   $RolesAssigned=$RolesAssigned+$Role
   if($Roles.indexof($role) -lt (($Roles.count)-1))
   {
    $RolesAssigned=$RolesAssigned+","
   }
  }
 }

 #Filter result based on Admin users
 if(($AdminOnly.IsPresent) -and ([string]$IsAdmin -eq "False"))
 {
  return
 }

 #Check for MFA enabled user
 if(($MethodTypes -ne $Null) -or ($MFAStatus -ne $Null) -and (-Not ($DisabledOnly.IsPresent) ))
 {
  #Check for Conditional Access
  if($MFAStatus -eq $null)
  {
   $MFAStatus='Enabled via Conditional Access'
  }

  #Filter result based on EnforcedOnly filter
  if((([string]$MFAStatus -eq "Enabled") -or ([string]$MFAStatus -eq "Enabled via Conditional Access")) -and ($EnforcedOnly.IsPresent))
  {
   return
  }

  #Filter result based on EnabledOnly filter
  if(([string]$MFAStatus -eq "Enforced") -and ($EnabledOnly.IsPresent))
  {
   return
  }

  #Filter result based on MFA enabled via Other source
  if((($MFAStatus -eq "Enabled") -or ($MFAStatus -eq "Enforced")) -and ($ConditionalAccessOnly.IsPresent))
  {
   return
  }

  $Methods=""
  $MethodTypes=""
  $MethodTypes=$_.StrongAuthenticationMethods.MethodType
  $DefaultMFAMethod=($_.StrongAuthenticationMethods | where{$_.IsDefault -eq "True"}).MethodType
  $MFAPhone=$_.StrongAuthenticationUserDetails.PhoneNumber
  $MFAEmail=$_.StrongAuthenticationUserDetails.Email

  if($MFAPhone -eq $Null)
  { $MFAPhone="-"}
  if($MFAEmail -eq $Null)
  { $MFAEmail="-"}

  if($MethodTypes -ne $Null)
  {
   $ActivationStatus="Yes"
   foreach($MethodType in $MethodTypes)
   {
    if($Methods -ne "")
    {
     $Methods=$Methods+","
    }
    $Methods=$Methods+$MethodType
   }
  }

  else
  {
   $ActivationStatus="No"
   $Methods="-"
   $DefaultMFAMethod="-"
   $MFAPhone="-"
   $MFAEmail="-"
  }

  #Print to output file
  $PrintedUser++
  $Result=@{'DisplayName'=$DisplayName;'UserPrincipalName'=$upn;'MFAStatus'=$MFAStatus;'ActivationStatus'=$ActivationStatus;'DefaultMFAMethod'=$DefaultMFAMethod;'AllMFAMethods'=$Methods;'MFAPhone'=$MFAPhone;'MFAEmail'=$MFAEmail;'LicenseStatus'=$LicenseStat;'IsAdmin'=$IsAdmin;'AdminRoles'=$RolesAssigned;'SignInStatus'=$SigninStat}
  $Results= New-Object PSObject -Property $Result
  $Results | Select-Object DisplayName,UserPrincipalName,MFAStatus,ActivationStatus,DefaultMFAMethod,AllMFAMethods,MFAPhone,MFAEmail,LicenseStatus,IsAdmin,AdminRoles,SignInStatus | Export-Csv -Path .\MFAreport.csv -Notype -Append
 }

 #Check for MFA disabled user
 elseif(($DisabledOnly.IsPresent) -and ($MFAStatus -eq $Null) -and ($_.StrongAuthenticationMethods.MethodType -eq $Null))
 {
  $MFAStatus="Disabled"
  $Department=$_.Department
  if($Department -eq $Null)
  { $Department="-"}
  $PrintedUser++
  $Result=@{'DisplayName'=$DisplayName;'UserPrincipalName'=$upn;'Department'=$Department;'MFAStatus'=$MFAStatus;'LicenseStatus'=$LicenseStat;'IsAdmin'=$IsAdmin;'AdminRoles'=$RolesAssigned; 'SignInStatus'=$SigninStat}
  $Results= New-Object PSObject -Property $Result
  $Results | Select-Object DisplayName,UserPrincipalName,Department,MFAStatus,LicenseStatus,IsAdmin,AdminRoles,SignInStatus | Export-Csv -Path .\MFAReport.csv -Notype -Append
 }
}
}


Export-ModuleMember -Function Get-License_FriendlyName
Export-ModuleMember -Function Get-UserInfo
Export-ModuleMember -Function Get-Externalusers
Export-ModuleMember -Function Get-Forwardingreport
Export-ModuleMember -Function Get-MFAReport