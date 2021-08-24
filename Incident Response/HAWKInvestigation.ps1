#Install HAWK Module
Install-module -name hawk 

#Tenant wide investigation
start-hawktenantinvestigation

#User investigation 
Start-HawkUserInvestigation -userprincipalname 