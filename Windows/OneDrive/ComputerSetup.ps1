## This script is to setup OneDrive Policy and to import task.
## Configure Tenant ID in this script.


Function ComputerSetup {

    ##Get current permission
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())


    ## Stop when running withou admin permission
    if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){

        write-host "This Script needs to run with admin priviledge!" -ForegroundColor “Red”
        pause
        break

    } else {

    write-host "Running with admin priviledge! Please wait ..." -ForegroundColor “Yellow”

    }

    ##Check Windows Version
    $WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID
    if($WinVersion -lt 1709) { 

        write-host "Windows Version is too low, please update your Windows to latest version." -ForegroundColor “Yellow”
        pause
        break

    } 


    ##Import REG keys for OneDrive Policy
    $HKLMregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
    $TenantGUID = 'e1b3d1aa-6612-48f6-a2bd-2d492b074844'

    If(!(Test-Path $HKLMregistryPath)) {

        New-Item -Path $HKLMregistryPath -Force
        
        }

    ##Add keys for policies 
    ##Enable silent account configuration
    New-ItemProperty -Path $HKLMregistryPath -Name 'SilentAccountConfig' -Value '1' -PropertyType DWORD -Force | Out-Null 

    ##Enable Files On-Demand
    New-ItemProperty -Path $HKLMregistryPath -Name 'FilesOnDemandEnabled' -Value '1' -PropertyType DWORD -Force | Out-Null 

    #Silently move Windows known folders to OneDrive
    New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptIn' -Value $TenantGUID -PropertyType String -Force | Out-Null 
    

    ## Copy setup script to user logon
    copy-item "C:\support\OneDrive\UserSetup.bat" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

}

ComputerSetup

