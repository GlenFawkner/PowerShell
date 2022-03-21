#Connect to Office 365
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication  Basic -AllowRedirection
$Session1 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Import-PSSession $Session2
Connect-MsolService
Write-Host "Connected to Office 365"

#Disable IMAP and POP
Get-CASMailboxPlan -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | set-CASMailboxPlan -ImapEnabled $false -PopEnabled $false
Get-CASMailbox -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}} | Set-CASMailbox -ImapEnabled $false -PopEnabled $false
Write-Host "IMAP and POP disabled"

#Enable Audit Logging
Enable-OrganizationCustomization
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
$AuditLogConfigResult = Get-AdminAuditLogConfig 
Write-Host "Audit logging status"$AuditLogConfigResult.AdminAuditLogEnabled

#Adjust spam filter
Set-HostedContentFilterPolicy -Identity Default -EnableRegionBlockList $True -RegionBlockList AX,AL,DZ,AD,AO,AI,AQ,AG,AR,AM,AW,AT,AZ,BS,BH,BD,BB,BY,BE,BZ,BJ,BM,BT,BO,BA,BW,BV,BR,VG,IO,BN,BG,BF,BI,KH,CM,CV,KY,CF,TD,CL,CN,HK,MO,CX,CC,CO,KM,CG,CD,CK,CR,CI,HR,CU,CY,CZ,DK,DJ,DM,DO,EC,EG,SV,GQ,ER,EE,ET,FK,FO,FJ,FI,FR,GF,PF,TF,GA,GM,GE,DE,GH,GI,GR,GL,GD,GP,GU,GT,GG,GN,GW,GY,HT,HM,VA,HN,HU,IS,IN,ID,IR,IQ,IE,IM,IL,IT,JM,JP,JE,JO,KZ,KE,KI,KP,KR,KW,KG,LA,LV,LB,LS,LR,LY,LI,LT,LU,MK,MG,MW,MY,MV,ML,MT,MH,MQ,MR,MU,YT,MX,FM,MD,MC,MN,ME,MS,MA,MZ,MM,NA,NR,NP,NL,NC,NI,NE,NG,NU,NF,MP,NO,OM,PK,PW,PS,PA,PG,PY,PE,PH,PN,PL,PT,PR,QA,RE,RO,RU,RW,BL,SH,KN,LC,MF,PM,VC,WS,SM,ST,SA,SN,RS,SC,SL,SG,SK,SI,SB,SO,ZA,GS,ES,LK,SD,SR,SJ,SZ,SE,CH,SY,TW,TJ,TZ,TH,TL,TG,TK,TO,TT,TN,TR,TM,TC,TV,UG,UA,AE,UM,UY,UZ,VU,VE,VN,VI,WF,YE,ZM,ZW
write-host "Regional spam filter enabled"

#Set malware filter
Set-MalwareFilterPolicy -Identity "Default" -Action DeleteMessage -EnableFileFilter $true -FileTypes "ace","ani","app","bat","com","docm","exe","jar","reg","scr","vbe","vbs"
write-host "Malware filter enabled"

#Set ransomeware filter
New-TransportRule -Name "Anti-ransomware rule:Advise users" -AttachmentExtensionMatchesWords "ade","adp","ani","bas","bat","chm","cmd","com","cpl","crt","hlp","ht","hta","inf","ins","isp","job","js","jse","lnk","mda","mdb","mde","mdz","msc","msi","msp","mst","pcd","reg","scr","sct","shs","url","vb","vbe","vbs","wsc","wsf","wsh","exe","pif" -RejectMessageReasonText "Email was blocked as possible ransomeware was detected"
write-host "Ransomware filter enabled"

