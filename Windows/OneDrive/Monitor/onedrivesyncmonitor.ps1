
#Unblock .dll
Unblock-File -Path "c:\Support\OneDriveLib.dll"

#Import Module 
Import-Module "c:\Support\OneDriveLib.dll"

#Email Body
$Header = @"
            <style>
            body {background-color: #F0CA44;}
            p {font-family: Arial;}
            p {font-size: 13pt;}
            p {color: #6D6E71;}
            </style>    
"@
$HTMLBODY = $Header
$HTMLBODY += '<img src="https://centralkids.org.nz/wp-content/uploads/2018/11/Central-Kids-Logo.png"/>'
$HTMLBODY += '<p>Hi,</p>'
$HTMLBODY += '<p><b>There has been a OneDrive sync error detected on your machine. Please check the error and resolve. If you need any assitance please call the SkyPoint team.</b></p>'
$HTMLBODY += '<p>Thanks,</p>'
$HTMLBODY += '<p>SkyPoint Team</p>'
$HTMLBODY += '<p><font color = "#1e1478"><b>P</b></font> 07-9607011 | <font color = "#1e1478"><b>E</b></font> support@skypoint.co.nz | <font color = "#1e1478"><b>W</b></font> skypoint.co.nz </p>'
$HTMLBODY += $Queue | ConvertTo-Html -Fragment | Out-String

#Get Status
$status = Get-ODStatus
#write-host $status.StatusString

#Get UPN
$UserEmail = Get-ItemPropertyValue -Path HKCU:\Software\Microsoft\OneDrive\Accounts\Business1 -Name "UserEmail"
#write-host $UserEmail


#Send email with status
If ($status.StatusString -eq 'Error')
{
    Send-MailMessage -From “onedrive@centralkids.org.nz" -To $UserEmail -Cc "support@skypoint.co.nz"  -SMTPServer mail.smtp2go.com -Subject (“OneDrive Error On ”+ $env:COMPUTERNAME) -BodyAsHtml -body "$HTMLBODY"

}
