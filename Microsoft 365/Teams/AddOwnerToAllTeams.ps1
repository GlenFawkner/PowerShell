# Install the Microsoft Teams PowerShell Module from PSGallery
# Default install Path C:\Program Files\WindowsPowerShell\Modules\MicrosoftTeams
Install-Module -Name MicrosoftTeams -Repository PSGallery

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Script to Get all Teams and Add an account as a memeber

$UserToAdd = “cbsa@enrichgroup.org.nz”

$AllTeams = Get-Team

Foreach ($Team in $AllTeams)
{
Write-Host “Adding to $($Team.DisplayName)”
Add-TeamUser -GroupId $Team.GroupID -User $UserToAdd -Role Owner
#Sleep Pause so as not to hit the API to hard
Start-Sleep -Seconds 2
}