function get-forwardingreport{
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
    $ExportResults | Select-object 'Mailbox Name', 'Forwarding SMTP Address','Forward To','Deliver To Mailbox and Forward' | Export-csv -path c:\temp\ForwardingReport.csv -NoType -Append -Force 
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
    $ExportResults | Select-object 'Mailbox Name', 'Inbox Rule', 'Forward To', 'Redirect To', 'Forward As Attachment To','Stop Processing Rules', 'Rule Status' | Export-csv -path c:\temp\ForwardingReport.csv -NoType -Append -Force 
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
    $ExportResults | Select-object 'Mail Flow Rule Name','Redirect To', 'Stop Processing Rule','State', 'Mode', 'Priority' | Export-csv -path c:\temp\ForwardingReport.csv -NoType -Append -Force 
}

GetAllMailForwardingRules
Write-Progress -Activity "--" -Completed
}

