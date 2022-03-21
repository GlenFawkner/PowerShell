#######Elevate Powershell As Admin###############################################################################################################################
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
 
################################################################################################################################################################


##Create BKPMaster 
$Password = Read-Host 'Enter BKPMaster Admin Password' -AsSecureString
Write-host 'Creating Local BKPMaster'
New-LocalUser "bkpmaster" -Password $Password -FullName "SkyPoint Backup Master" -Description "Local Backup Account 1"
Add-LocalGroupMember -Group "Administrators" -Member "bkpmaster"
Disable-LocalUser -Name "Administrator"

##Create BKPMaster2 
$Password = Read-Host 'Enter BKPMaster2 Admin Password' -AsSecureString
Write-host 'Creating Local BKPMaster2'
New-LocalUser "bkpmaster2" -Password $Password -FullName "SkyPoint Backup Master 2" -Description "Local Backup Account 2"
Add-LocalGroupMember -Group "Administrators" -Member "bkpmaster2"
Disable-LocalUser -Name "Administrator"

##Create Client BKPMaster 
$ClientCode = Read-Host 'Enter Client Code'
$Password = Read-Host 'Enter Client Backup Admin Password' -AsSecureString
Write-host 'Creating Local BKPMaster'
New-LocalUser ($ClientCode + "bkpmaster") -Password $Password -FullName "Client Backup Master" -Description "Local Client Backup Account"
Add-LocalGroupMember -Group "Administrators" -Member ($ClientCode + "bkpmaster")
Disable-LocalUser -Name "Administrator"

#Install HyperV Role
#Write-host 'HyperV role installing'
#Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

#Change Power Plan
Write-Host 'Changing power plan to High Performance'
$pp = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High Performance'"          
Invoke-CimMethod -InputObject $pp -MethodName Activate

#Disable Firewalls 
Write-Host 'Turning firewalls off'
netsh advfirewall set allprofiles state off

#Set Region
Write-Host 'Setting users region'
Set-WinHomeLocation -GeoId 183

#Disable IE ESC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name 'IsInstalled' -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name 'IsInstalled' -Value 0

#Enable RDP
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" –Value  0
#Disable NLA
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name 'UserAuthentication' -Value '00000000' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name 'SecurityLayer' -Value '00000000' -PropertyType DWORD -Force | Out-Null

#Disable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

#Create Support Directory
New-Item -ItemType directory -Path C:\Support
New-Item -ItemType directory -Path C:\Support\ScreenConnect
New-Item -ItemType directory -Path C:\Support\Webroot
New-Item -ItemType directory -Path C:\Support\ISOs
New-Item -ItemType directory -Path C:\Support\Misc
New-Item -ItemType directory -Path C:\Support\Pluseway

#Install Windows Updates
Install-Module PSWindowsUpdate -Force
Get-Command –module PSWindowsUpdate
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d
Get-WUInstall –MicrosoftUpdate –AcceptAll 



Pause