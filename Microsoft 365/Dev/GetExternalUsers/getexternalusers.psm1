function get-externalusers {
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
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Site Name', 'Site Url', 'Guest Domain' | Export-csv -path C:\Temp\ExternalUserReport -NoType -Append -Force
      
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
    $ExportResults | Select-object 'Guest User', 'Email Address', 'Created On', 'Invitation Accepted via', 'Guest Domain' | Export-csv -path C:\Temp\ExternalUserReport -NoType -Append -Force
    
}

#Execution starts here.
ConnectSPOService
$global:ExportedGuestUser = 0
FindGuestUsers
}