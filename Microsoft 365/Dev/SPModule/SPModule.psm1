#Exports a log of guests users and their last login in the last 90 days
Function Get-GuestUsersLastSigIn{
    #Output files
    $ExportGULReport=".\GuestUserSigninReport.csv"
    ##Get all guest users
    $guests = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true 

    ##Loop Guest Users
    foreach ($guest in $guests) {

    ##Get logs filtered by current guest
    $logs = Get-AzureADAuditSignInLogs -Filter "userprincipalname eq `'$($guest.mail)'" -ALL:$true 

    ##Check if multiple entries and tidy results
    if ($logs -is [array]) {
        $timestamp = $logs[0].createddatetime
    }
    else {
        $timestamp = $logs.createddatetime
    }

    ##Build Output Object
    $object = [PSCustomObject]@{

        Userprincipalname = $guest.userprincipalname
        Mail              = $guest.mail
        LastSignin        = $timestamp
        AppsUsed          = (($logs.resourcedisplayname | select -Unique) -join (';'))
    }

    ##Export Results
    $object | export-csv $ExportGULReport -NoTypeInformation -Append

    Remove-Variable object
    Start-Sleep -s 2
    }}
Export-ModuleMember -Function Get-GuestUsersLastSigIn
##############################################################################

#Exports a MFA report
function Get-MFAReport {
    #Output files
    $ExportMFAReport=".\MFAEnabledUserReport.csv"
    #Loop through users
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
  $Results | Select-Object DisplayName,UserPrincipalName,MFAStatus,ActivationStatus,DefaultMFAMethod,AllMFAMethods,MFAPhone,MFAEmail,LicenseStatus,IsAdmin,AdminRoles,SignInStatus | Export-Csv -Path $ExportMFAReport -Notype -Append
 }
    }
    }
Export-ModuleMember -Function Get-MFAReport

##############################################################################

#Exports a forwarding report
function Get-Forwardingreport{
    #Output files
    $ExportFWReport=".\ForwardingReport.csv"
    $ExportInboxRulesReport=".\InboxRulesReport.csv"
    $ExportMailFlowReport=".\MailFlowRulesReport.csv"
    Function GetPrintableValue($RawData) {
    if (($null -eq $RawData) -or ($RawData.Equals(""))) {
        return "-";
    }
    else {
        $StringVal = $RawData | Out-String
        return $StringVal;
    }}
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
    }}

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
    $ExportResults | Select-object 'Mailbox Name', 'Forwarding SMTP Address','Forward To','Deliver To Mailbox and Forward' | Export-csv -path $ExportFWReport -NoType -Append -Force }

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
    $ExportResults | Select-object 'Mailbox Name', 'Inbox Rule', 'Forward To', 'Redirect To', 'Forward As Attachment To','Stop Processing Rules', 'Rule Status' | Export-csv -path $ExportInboxRulesReport -NoType -Append -Force }

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
    $ExportResults | Select-object 'Mail Flow Rule Name','Redirect To', 'Stop Processing Rule','State', 'Mode', 'Priority' | Export-csv -path $ExportMailFlowReport -NoType -Append -Force }

    GetAllMailForwardingRules
    Write-Progress -Activity "--" -Completed}

Export-ModuleMember -Function Get-ForwardingReport

##############################################################################

#Export failed sign in attempts
function Get-SigninFailures{
    Get-AzureADAuditSignInLogs -Filter "status/errorCode ne 0" -All $true | Export-CSV ".\AzureADAuditSignInLogs.CSV" -NoTypeInformation }
Export-ModuleMember -Function Get-SigninFailures 

##############################################################################

#Exports mailbox size report for each user
function Get-MailboxStorageReport{
     #Output files
    $ExportMBStorage=".\MailboxStorageReport.csv"
    Function Get-Mailboxes {
  
  process {
     $mailboxTypes = "UserMailbox,SharedMailbox"
    Get-EXOMailbox -ResultSize unlimited -RecipientTypeDetails $mailboxTypes -Properties IssueWarningQuota, ProhibitSendReceiveQuota, ArchiveQuota, ArchiveWarningQuota, ArchiveDatabase | 
      select UserPrincipalName, DisplayName, PrimarySMTPAddress, RecipientType, RecipientTypeDetails, IssueWarningQuota, ProhibitSendReceiveQuota, ArchiveQuota, ArchiveWarningQuota, ArchiveDatabase
  }}
    Function ConvertTo-Gb {
  <#
    .SYNOPSIS
        Convert mailbox size to Gb for uniform reporting.
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    [string]$size
  )
  process {
    if ($size -ne $null) {
      $value = $size.Split(" ")

      switch($value[1]) {
        "GB" {$sizeInGb = ($value[0])}
        "MB" {$sizeInGb = ($value[0] / 1024)}
        "KB" {$sizeInGb = ($value[0] / 1024 / 1024)}
      }

      return [Math]::Round($sizeInGb,2,[MidPointRounding]::AwayFromZero)
    }
  }}


    Function Get-MailboxStats {
  <#
    .SYNOPSIS
        Get the mailbox size and quota
  #>
  process {
    $mailboxes = Get-Mailboxes
    $i = 0

    $mailboxes | ForEach {

      # Get mailbox size     
      $mailboxSize = Get-MailboxStatistics -identity $_.UserPrincipalName | Select TotalItemSize,TotalDeletedItemSize,ItemCount,DeletedItemCount,LastUserActionTime

      if ($mailboxSize -ne $null) {
      
        # Get archive size if it exists and is requested
        $archiveSize = 0
        $archiveResult = $null

        if ($archive.IsPresent -and ($_.ArchiveDatabase -ne $null)) {
          $archiveResult = Get-EXOMailboxStatistics -UserPrincipalName $_.UserPrincipalName -Archive | Select ItemCount,DeletedItemCount,@{Name = "TotalArchiveSize"; Expression = {$_.TotalItemSize.ToString().Split("(")[0]}}
          if ($archiveResult -ne $null) {
            $archiveSize = ConvertTo-Gb -size $archiveResult.TotalArchiveSize
          }else{
            $archiveSize = 0
          }
        }  
    
        [pscustomobject]@{
          "Display Name" = $_.DisplayName
          "Email Address" = $_.PrimarySMTPAddress
          "Mailbox Type" = $_.RecipientTypeDetails
          "Last User Action Time" = $mailboxSize.LastUserActionTime
          "Total Size (GB)" = ConvertTo-Gb -size $mailboxSize.TotalItemSize.ToString().Split("(")[0]
          "Deleted Items Size (GB)" = ConvertTo-Gb -size $mailboxSize.TotalDeletedItemSize.ToString().Split("(")[0]
          "Item Count" = $mailboxSize.ItemCount
          "Deleted Items Count" = $mailboxSize.DeletedItemCount
          "Mailbox Warning Quota (GB)" = $_.IssueWarningQuota.ToString().Split("(")[0]
          "Max Mailbox Size (GB)" = $_.ProhibitSendReceiveQuota.ToString().Split("(")[0]
          "Archive Size (GB)" = $archiveSize
          "Archive Items Count" = $archiveResult.ItemCount
          "Archive Deleted Items Count" = $archiveResult.DeletedItemCount
          "Archive Warning Quota (GB)" = $_.ArchiveWarningQuota.ToString().Split("(")[0]
          "Archive Quota (GB)" = ConvertTo-Gb -size $_.ArchiveQuota.ToString().Split("(")[0]
        }

        $currentUser = $_.DisplayName
        Write-Progress -Activity "Collecting mailbox status" -Status "Current Count: $i" -PercentComplete (($i / $mailboxes.Count) * 100) -CurrentOperation "Processing mailbox: $currentUser"
        $i++;
      }
    }
  }}
    Get-MailboxStats | Export-CSV -Path $ExportMBStorage -NoTypeInformation -Encoding UTF8}
Export-ModuleMember -Function Get-MailboxStorageReport

##############################################################################

#Export mailbox permissions report
function Get-MailboxPermissionsReport{

    #Output files
    $ExportMBPermissions=".\MailboxPermissionsReport.csv"
    Function Find-LargestValue {
  <#
    .SYNOPSIS
        Find the value with the most records
  #>
  param(
    [Parameter(Mandatory = $true)]$sob,
    [Parameter(Mandatory = $true)]$fa,
    [Parameter(Mandatory = $true)]$sa,
    [Parameter(Mandatory = $true)]$ib,
    [Parameter(Mandatory = $true)]$ca
  )

  if ($sob -gt $fa -and $sob -gt $sa -and $sob -gt $ib -and $sob -gt $ca) {return $sob}
  elseif ($fa -gt $sa -and $fa -gt $ib -and $fa -gt $ca) {return $fa}
  elseif ($sa -gt $ib -and $sa -gt $ca) {return $sa}
  elseif ($ib -gt $ca) {return $ib}
  else {return $ca}}
    Function Get-DisplayName {
  <#
    .SYNOPSIS
      Get the full displayname (if requested) or return only the userprincipalname
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    $identity
  )

  if ($displayNames.IsPresent) {
    Try {
      return (Get-EXOMailbox -Identity $identity -ErrorAction Stop).DisplayName
    }
    Catch{
      return $identity
    }
  }else{
    return $identity.ToString().Split("@")[0]
  }}

    Function Get-SingleUser {
  <#
    .SYNOPSIS
      Get only the requested mailbox
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    $identity
  )

  Get-EXOMailbox -Identity $identity -Properties GrantSendOnBehalfTo, ForwardingSMTPAddress | 
      select UserPrincipalName, DisplayName, PrimarySMTPAddress, RecipientType, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingSMTPAddress}

    Function Get-Mailboxes {
  <#
    .SYNOPSIS
        Get all the mailboxes for the report
  #>
  process {$mailboxTypes = "UserMailbox,SharedMailbox"
    Get-EXOMailbox -ResultSize unlimited -RecipientTypeDetails $mailboxTypes -Properties GrantSendOnBehalfTo, ForwardingSMTPAddress| select UserPrincipalName, DisplayName, PrimarySMTPAddress, RecipientType, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingSMTPAddress
    }}

    Function Get-SendOnBehalf {
  <#
    .SYNOPSIS
        Get Display name for each Send on Behalf entity
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    $mailbox
  )

  # Get Send on Behalf
  $SendOnBehalfAccess = @();
  if ($mailbox.GrantSendOnBehalfTo -ne $null) {
    
    # Get a proper displayname of each user
    $mailbox.GrantSendOnBehalfTo | ForEach {
      $sendOnBehalfAccess += Get-DisplayName -identity $_
    }
  }
  return $SendOnBehalfAccess}

    Function Get-SendAsPermissions {
  <#
    .SYNOPSIS
        Get all users with Send as Permissions
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    $identity
  )
  $users = Get-EXORecipientPermission -Identity $identity | where { -not ($_.Trustee -match "NT AUTHORITY") -and ($_.IsInherited -eq $false)}

  $sendAsUsers = @();
  
  # Get a proper displayname of each user
  $users | ForEach {
    $sendAsUsers += Get-DisplayName -identity $_.Trustee
  }
  return $sendAsUsers}

    Function Get-FullAccessPermissions {
  <#
    .SYNOPSIS
        Get all users with Read and manage (full access) permissions
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    $identity
  )
  
  $users = Get-EXOMailboxPermission -Identity $identity | where { -not ($_.User -match "NT AUTHORITY") -and ($_.IsInherited -eq $false)}

  $fullaccessUsers = @();
  
  # Get a proper displayname of each user
  $users | ForEach {
    $fullaccessUsers += Get-DisplayName -identity $_.User
  }
  return $fullaccessUsers}

    Function Get-FolderPermissions {
  <#
    .SYNOPSIS
      Get Inbox folder permisions
  #>
  param(
    [Parameter(Mandatory = $true)] $identity,
    [Parameter(Mandatory = $true)] $folder
  )
  
  $return = @{
    users = @()
    permission = @()
    delegated = @()
  }

  Try {
    $ErrorActionPreference = "Stop"; #Make all errors terminating
    $users = Get-EXOMailboxFolderPermission -Identity "$($identity):\$($folder)" | where { -not ($_.User -match "Default") -and -not ($_.AccessRights -match "None")}
  }
  Catch{
    return $return
  }
  Finally{
   $ErrorActionPreference = "Continue"; #Reset the error action pref to default
  }

  $folderUsers = @();
  $folderAccessRights = @();
  $folderDelegated = @();
  
  # Get a proper displayname of each user
  $users | ForEach {
    $folderUsers += Get-DisplayName -identity $_.User
    $folderAccessRights += $_.AccessRights
    $folderDelegated += $_.SharingPermissionFlags
  }

  $return.users = $folderUsers
  $return.permission = $folderAccessRights
  $return.delegated = $folderDelegated

  return $return}

    Function Get-AllMailboxPermissions {
  <#
    .SYNOPSIS
      Get all the permissions of each mailbox
        
      Permission are spread into 4 parts.
      - Read and Manage permission
      - Send as Permission
      - Send on behalf of permission
      - Folder permissions (inbox and calendar set by the user self)
  #>
  process {

    if ($UserPrincipalName) {
      
      Write-Host "Collecting mailboxes" -ForegroundColor Cyan
      $mailboxes = @()

      # Get the requested mailboxes
      foreach ($user in $UserPrincipalName) {
        Write-Host "- Get mailbox $user" -ForegroundColor Cyan
        $mailboxes += Get-SingleUser -identity $user
      }
    }elseif ($csvFile) {
      
      Write-Host "Using CSV file" -ForegroundColor Cyan
      $mailboxes = @()

      # Test CSV file path
      if (Test-Path $csvFile) {

        # Read CSV File
        Import-Csv $csvFile | ForEach {
          Write-Host "- Get mailbox $($_.UserPrincipalName)" -ForegroundColor Cyan
          $mailboxes += Get-SingleUser -identity $_.UserPrincipalName
        }
      }else{
        Write-Host "Unable to find CSV file $csvFile" -ForegroundColor black -BackgroundColor Yellow
      }
    }else{
      Write-Host "Collecting mailboxes" -ForegroundColor Cyan
      $mailboxes = Get-Mailboxes
    }
    
    $i = 0
    Write-Host "Collecting permissions" -ForegroundColor Cyan
    $mailboxes | ForEach {
     
      # Get Send on Behalf Permissions
      $sendOnbehalfUsers = Get-SendOnBehalf -mailbox $_
      
      # Get Fullaccess Permissions
      $fullAccessUsers = Get-FullAccessPermissions -identity $_.UserPrincipalName

      # Get Send as Permissions
      $sendAsUsers = Get-SendAsPermissions -identity $_.UserPrincipalName

      # Count number or records
      $sob = $sendOnbehalfUsers.Count
      $fa = $fullAccessUsers.Count
      $sa = $sendAsUsers.Count

      if ($folderPermissions.IsPresent) {
        
        # Get Inbox folder permission
        $inboxFolder = Get-FolderPermissions -identity $_.UserPrincipalName -folder $inboxFolderName
        $ib = $inboxFolder.users.Count

        # Get Calendar permissions
        $calendarFolder = Get-FolderPermissions -identity $_.UserPrincipalName -folder $calendarFolderName
        $ca = $calendarFolder.users.Count
      }else{
        $inboxFolder = @{
            users = @()
            permission = @()
            delegated = @()
        }
        $calendarFolder = @{
            users = @()
            permission = @()
            delegated = @()
        }
        $ib = 0
        $ca = 0
      }
     
      $mostRecords = Find-LargestValue -sob $sob -fa $fa -sa $sa -ib $ib -ca $ca

      $x = 0
      if ($mostRecords -gt 0) {
          
          Do{
            if ($x -eq 0) {
                [pscustomobject]@{
                  "Display Name" = $_.DisplayName
                  "Emailaddress" = $_.PrimarySMTPAddress
                  "Mailbox type" = $_.RecipientTypeDetails
                  "Read and manage" = @($fullAccessUsers)[$x]
                  "Send as" = @($sendAsUsers)[$x]
                  "Send on behalf" = @($sendOnbehalfUsers)[$x]
                  "Inbox folder" = @($inboxFolder.users)[$x]
                  "Inbox folder Permission" = @($inboxFolder.permission)[$x]
                  "Inbox folder Delegated" = @($inboxFolder.delegated)[$x]
                  "Calendar" = @($calendarFolder.users)[$x]
                  "Calendar Permission" = @($calendarFolder.permission)[$x]
                  "Calendar Delegated" = @($calendarFolder.delegated)[$x]
                }
                $x++;
            }else{
                [pscustomobject]@{
                  "Display Name" = ''
                  "Emailaddress" = ''
                  "Mailbox type" = ''
                  "Read and manage" = @($fullAccessUsers)[$x]
                  "Send as" = @($sendAsUsers)[$x]
                  "Send on behalf" = @($sendOnbehalfUsers)[$x]
                  "Inbox folder" = @($inboxFolder.users)[$x]
                  "Inbox folder Permission" = @($inboxFolder.permission)[$x]
                  "Inbox folder Delegated" = @($inboxFolder.delegated)[$x]
                  "Calendar" = @($calendarFolder.users)[$x]
                  "Calendar Permission" = @($calendarFolder.permission)[$x]
                  "Calendar Delegated" = @($calendarFolder.delegated)[$x]
                }
                $x++;
            }

            $currentUser = $_.DisplayName
            if ($mailboxes.Count -gt 1) {
              Write-Progress -Activity "Collecting mailbox permissions" -Status "Current Count: $i" -PercentComplete (($i / $mailboxes.Count) * 100) -CurrentOperation "Processing mailbox: $currentUser"
            }
          }
          while($x -ne $mostRecords)
      }
      $i++;
    }
  }}

    Get-AllMailboxPermissions | Export-CSV -Path $ExportMBPermissions -NoTypeInformation}
Export-ModuleMember -Function Get-MailboxPermissionsReport

##############################################################################

#Export external forwarding rules report
function Get-ExternalForwardingReport{
    #Output files
    $ExportExternalForwardingRules=".\ExternalForwardingRulesReport.csv"
    $domains = Get-AcceptedDomain
    $mailboxes = Get-Mailbox -ResultSize Unlimited
 
    foreach ($mailbox in $mailboxes) {
 
    $forwardingRules = $null
    Write-Host "Checking rules for $($mailbox.displayname) - $($mailbox.primarysmtpaddress)" -foregroundColor Green
    $rules = get-inboxrule -Mailbox $mailbox.primarysmtpaddress
     
    $forwardingRules = $rules | Where-Object {$_.forwardto -or $_.forwardasattachmentto}
 
    foreach ($rule in $forwardingRules) {
        $recipients = @()
        $recipients = $rule.ForwardTo | Where-Object {$_ -match "SMTP"}
        $recipients += $rule.ForwardAsAttachmentTo | Where-Object {$_ -match "SMTP"}
     
        $externalRecipients = @()
 
        foreach ($recipient in $recipients) {
            $email = ($recipient -split "SMTP:")[1].Trim("]")
            $domain = ($email -split "@")[1]
 
            if ($domains.DomainName -notcontains $domain) {
                $externalRecipients += $email
            }    
        }
 
        if ($externalRecipients) {
            $extRecString = $externalRecipients -join ", "
            Write-Host "$($rule.Name) forwards to $extRecString" -ForegroundColor Yellow
 
            $ruleHash = $null
            $ruleHash = [ordered]@{
                PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                DisplayName        = $mailbox.DisplayName
                RuleId             = $rule.Identity
                RuleName           = $rule.Name
                RuleDescription    = $rule.Description
                ExternalRecipients = $extRecString
            }
            $ruleObject = New-Object PSObject -Property $ruleHash
            $ruleObject | Export-Csv $ExportExternalForwardingRules -NoTypeInformation -Append
        }
    }}}
Export-ModuleMember -Function Get-ExternalForwardingReport

##############################################################################
#Check accounts with admin roles
function Get-AdminRoles {


    Write-Host "Preparing admin report..." 
    $admins=@() 
    $list = @() 
    $outputCsv=".\AdminReport.csv" 

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
    $exportResults | Select-Object 'AdminName','AdminEmailAddress','RoleName','LicenseStatus','SignInStatus' | Export-csv -path $outputCsv -NoType -Append  
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
    $exportResults | Select-Object 'RoleName','AdminName','AdminEmailAddress' | Export-csv -path $outputCsv -NoType -Append 
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
    }}
Export-ModuleMember -Function Get-AdminRoles

##############################################################################

#Export list of external SharePoint users
function Get-Externalusers {
    #Output files
    $ExportExternalUsersReport=".\SharePointExternalUsersReport.csv"
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

    #Saves guest user data
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
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Site Name', 'Site Url', 'Guest Domain' | Export-csv -path $ExportExternalUsersReport -NoType -Append -Force
      
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
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Created On', 'Invitation Accepted via', 'Guest Domain' | Export-csv -path $ExportExternalUsersReport -NoType -Append -Force
    
    }

    #Execution starts here.
    $global:ExportedGuestUser = 0
    FindGuestUsers}
Export-ModuleMember -Function Get-Externalusers

##############################################################################

#Export SharePoint online current storage use
function get-spostoragereportusage{
    #Output files
    $ExportSPOStorageReport=".\SPOStorageReport.csv"
    #Get all Site collections
    $SiteCollections = Get-SPOSite -Limit All
    Write-Host "Total Number of Site collections Found:"$SiteCollections.count -f Yellow
 
    #Array to store Result
    $ResultSet = @()
 
    Foreach($Site in $SiteCollections)
    {
    Write-Host "Processing Site Collection :"$Site.URL -f Yellow
    #Send the Result to CSV 
    $Result = new-object PSObject
    $Result| add-member -membertype NoteProperty -name "SiteURL" -Value $Site.URL
    $Result | add-member -membertype NoteProperty -name "Allocated" -Value $Site.StorageQuota
    $Result | add-member -membertype NoteProperty -name "Used" -Value $Site.StorageUsageCurrent
    $Result | add-member -membertype NoteProperty -name "Warning Level" -Value  $site.StorageQuotaWarningLevel
    $ResultSet += $Result
    }
 
    #Export Result to csv file
    $ResultSet |  Export-Csv $ExportSPOStorageReport -notypeinformation}
Export-ModuleMember -Function Get-spostoragereportusage