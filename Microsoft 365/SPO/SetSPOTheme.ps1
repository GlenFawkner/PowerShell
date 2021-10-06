#Connect to tenant
$userCredential = Get-Credential -UserName $adminUPN -Message "Type the password."
Connect-SPOService -Url https://ivsnz-admin.sharepoint.com/ -Credential $userCredential

#Set theme

$theme = @{
"themePrimary" = "#78a22e";
"themeLighterAlt" = "#f9fbf4";
"themeLighter" = "#e6f0d5";
"themeLight" = "#d1e3b2";
"themeTertiary" = "#a8c872";
"themeSecondary" = "#86ae40";
"themeDarkAlt" = "#6c9329";
"themeDark" = "#5b7c23";
"themeDarker" = "#435b1a";
"neutralLighterAlt" = "#faf9f8";
"neutralLighter" = "#f3f2f1";
"neutralLight" = "#edebe9";
"neutralQuaternaryAlt" = "#e1dfdd";
"neutralQuaternary" = "#d0d0d0";
"neutralTertiaryAlt" = "#c8c6c4";
"neutralTertiary" = "#c2c2c2";
"neutralSecondary" = "#858585";
"neutralPrimaryAlt" = "#4b4b4b";
"neutralPrimary" = "#333333";
"neutralDark" = "#272727";
"black" = "#1d1d1d";
"white" = "#ffffff";
}

Add-SPOTheme -Name "IVS Theme" -Palette $theme -IsInverted $false