#Find ObjectID of your security group
Get-AzureADGroup -SearchString "<Name of your security group>"

$Template = Get-AzureADDirectorySettingTemplate | where {$_.DisplayName -eq 'Group.Unified'}

$Setting = $Template.CreateDirectorySetting()

New-AzureADDirectorySetting -DirectorySetting $Setting

$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id

$Setting["EnableGroupCreation"] = $False

$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString "<Name of your security group>").objectid

Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $Setting

(Get-AzureADDirectorySetting).Values