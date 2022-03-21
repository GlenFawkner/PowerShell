## Configure SiteID and etc in this script

Function ProcessCheck {

    ## Get running process
    $OneDriveProcess = Get-Process OneDrive -ErrorAction SilentlyContinue

    if (!$OneDriveProcess) {
        ## Loop is OneDrive is not detected
        sleep 3
        ProcessCheck

    } else {

        Write-host "OneDrive is up and running, configuring teamsite ..." -ForegroundColor Yellow

    }

}


Function UserSetup {

    ##Automapping SharePoint Teamsite
    ##Import URL Encoder from .Net
    Add-type -Assembly system.web

    ##To find library ID: https://docs.microsoft.com/en-us/onedrive/use-group-policy#AutoMountTeamSites 
    ##Copy "siteId=xxx&webId=xxx&listId=xxx&webUrl=httpsxxx" and split it into following variables

    $SiteID = "siteId=%7Bd8615859%2D2644%2D4c3d%2D9cf6%2Dd23b66963524%7D"
    $WebID = "webId=%7Bc2025616%2D4b75%2D42d6%2D9a3a%2D1ca9b28f55de%7D"
    $ListID = "listId=%7BF68841C6%2D0A2A%2D4424%2DB93C%2DCA6351100A93%7D"
    $WebURL = "webUrl=https%3A%2F%2Fcentralkidskindergartens.sharepoint.com%2Fsites%2FHuntly"

    ##Give webtitle an string value. It will be used as the folder name 
    $TenantName = "Central Kids Kindergartens"
    $WebTitle = "Huntly Kindergarten"
    $WebTitleURI = "webtitle=" + $webtitle

    ##Get UPN of current user and encode 
    $UPN =  (whoami /upn)
    $UPNEncoded = [system.web.httputility]::URLEncode($UPN) 
    $UserEmail =  "userEmail=" + $UPNEncoded 


    ##Prepare URI for OneDrive
    $SPTeamSiteURI ="odopen://sync/?" + $SiteID + "&amp;" + $WebID + "&amp;" + $ListID + "&amp;" + $UserEmail + "&amp;" + $WebURL + "&amp;" + $WebTitleURI

    ##Check if path exists      
    $Path = "C:\Users\$env:username\$TenantName\$WebTitle - Documents" 

    if(Test-Path $Path){ 
    
        ##Create shorcut on desktop
        $Shell = New-Object -ComObject ("WScript.Shell")
        $ShortcutName = $TenantName + "-" + $WebTitle
        $ShortCut = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\$ShortcutName.lnk")
        $ShortCut.TargetPath = "$Path"
        $ShortCut.IconLocation = "$env:LOCALAPPDATA\Microsoft\OneDrive\onedrive.exe, 3";
        $ShortCut.Save()

        break

    } else { 

        ##Wait for OneDrive to load
        ProcessCheck

        ##Wait for OneDrive to be ready
        $Rand = Get-Random -Minimum 15 -Maximum 30
        sleep $Rand

        ##Check OneDrive version
        $OneDriveVersion = Get-ItemPropertyValue  'HKCU:\Software\Microsoft\OneDrive' -Name Version
        $VersionToInstall = "19.12.121.11" 

        if([version]$OneDriveVersion -lt [version]$VersionToInstall) {

            ##Update OneDrive Client
            write-host "Updating OneDrive ..." -ForegroundColor Yellow
            Start-Process -Wait -FilePath "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveStandaloneUpdater.exe" -PassThru

        } 

        write-host "Mapping Teamsite ..." -ForegroundColor Yellow

        start $SPTeamSiteURI

        ## Import Taks Scheduler
        $ScheduledTask = Get-ScheduledTask -TaskName "OneDrive Monitoring" -ErrorAction SilentlyContinue

        if (!$ScheduledTask){

            write-host "Importing task to monitor OneDrive ..." -ForegroundColor Yellow
            Register-ScheduledTask -Xml (get-content 'C:\support\OneDrive\Monitor\OneDrive Monitoring.xml' | out-string) -TaskName "OneDrive Monitoring" –Force

        }
        ##Wait for Folder to be ready
        $Rand = Get-Random -Minimum 3 -Maximum 10
        sleep $Rand       
        
        ##Create shorcut on desktop
        $Shell = New-Object -ComObject ("WScript.Shell")
        $ShortcutName = $TenantName + "-" + $WebTitle
        $ShortCut = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\$ShortcutName.lnk")
        $ShortCut.TargetPath = "$Path"
        $ShortCut.IconLocation = "$env:LOCALAPPDATA\Microsoft\OneDrive\onedrive.exe, 3";
        $ShortCut.Save()
         
    } 
    
}

$paragraph1 = "This scipt is to load sharepoint site in OneDrive. Please leave it running." 

$paragraph2 += "Waiting for OneDrive to start ..."

write-host $paragraph1 -ForegroundColor Yellow
write-host
write-host $paragraph2 -ForegroundColor Yellow

UserSetup
