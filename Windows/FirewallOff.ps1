Configuration FirewallScriptResource            
{                
    Node localhost            
    {            
        Script DisableFirewall            
        {            
            # Must return a hashtable with at least one key            
            # named 'Result' of type String            
            GetScript = {            
                Return @{            
                    Result = [string]$(netsh advfirewall show allprofiles)            
                }            
            }            
            
            # Must return a boolean: $true or $false            
            TestScript = {            
                If ((netsh advfirewall show allprofiles) -like "State*on*") {            
                    Write-Verbose "One or more firewall profiles are on"            
                    Return $false            
                } Else {            
                    Write-Verbose "All firewall profiles are OFF"            
                    Return $true            
                }            
            }            
            
            # Returns nothing            
            SetScript = {            
                Write-Verbose "Setting all firewall profiles to Off"            
                netsh advfirewall set allprofiles state off            
            }            
        }            
    }            
}            
            
FirewallScriptResource            
            
Start-DscConfiguration -Path .\FirewallScriptResource -Wait -Verbose            
            
Get-DscConfiguration  