##################
#    Variables   #
##################
$Localpath               = "c:\temp\wvd\"
$WVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$TeamsURI                = 'https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.4461/Teams_windows_x64.msi'
$OneDriveURI             = 'https://go.microsoft.com/fwlink/p/?LinkID=2121808&clcid=0x409&culture=en-us&country=US'
$FSLogixURI              = 'https://go.microsoft.com/fwlink/?linkid=2084562'
$FSInstaller             = 'FSLogixAppsSetup.zip'
$WVDAgentInstaller       = 'WVD-Agent.msi'
$WVDBootInstaller        = 'WVD-Bootloader.msi'
$TeamsInstaller          = 'Teams_windows_x64.msi'
$OneDriveInstaller       = 'OneDriveSetup.exe'
$CatoCertURI             = 'https://rmm.compassmsp.com/softwarepackages/CatoNetworksTrustedRootCA.cer'
$CatoCert                = 'CatoNetworksTrustedRootCA.cer'
$AadTenantId             = '02e68a77-717b-48c1-881a-acc8f67c291a'
$CCDLocation             = 'DefaultEndpointsProtocol=https;AccountName=compass5490;AccountKey=E4EX7P7iGGeaKMDK30EIU9zRePQMfOOuk4V2/yMOW3NLiyWPIs/TStLMLUT5iHxv4NwekJ+BI4iKHimbyz4FmA==;EndpointSuffix=core.windows.net'


####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path $Localpath) -eq $false) {
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path $Localpath -ItemType Directory
}
else {
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}


#################################
#    Download WVD Components    #
#################################
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$Localpath$FSInstaller"

Expand-Archive `
    -LiteralPath "C:\temp\wvd\$FSInstaller" `
    -DestinationPath "$Localpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $Localpath

#########################
#    FSLogix Install    #
#########################
$fslogix_deploy_status = Start-Process `
    -FilePath "$Localpath\FSLogix\x64\Release\FSLogixAppsSetup.exe" `
    -ArgumentList "/install /quiet" `
    -Wait `
    -Passthru

#######################################
#    FSLogix User Profile Settings    #
#######################################
Push-Location
Set-Location HKLM:\SOFTWARE\FSLogix
New-Item `
    -Path HKLM:\SOFTWARE\FSLogix `
    -Name Profiles `
    -Value "" `
    -Force
    New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "CCDLocations" `
    -PropertyType "MultiString" `
    -Value "type=azure,connectionString=""$CCDLocation"""
    New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "VolumeType" `
    -PropertyType "MultiString" `
    -Value "vhdx"
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "Enabled" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "DeleteLocalProfileWhenVHDShouldApply" `
    -PropertyType "DWord" `
    -Value 0
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "FlipFlopProfileDirectoryName" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "PreventLoginWithFailure" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "PreventLoginWithTempProfile" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "RebootOnUserLogoff" `
    -PropertyType "DWord" `
    -Value 0
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "ShutdownOnUserLogoff" `
    -PropertyType "DWord" `
    -Value 0
Pop-Location


#########################################
#    FSLogix Office Profile Settings    #
#########################################
Push-Location
Set-Location HKLM:\SOFTWARE\Policies
New-Item `
    -Name FSLogix `
    -Value "" `
    -Force
New-Item `
    -Path .\FSLogix `
    -Name ODFC `
    -Value "" `
    -Force
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "CCDLocations" `
    -PropertyType "MultiString" `
    -Value "type=azure,connectionString=""$CCDLocation"""
    New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "VolumeType" `
    -PropertyType "MultiString" `
    -Value "vhdx"
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "DeleteLocalProfileWhenVHDShouldApply" `
    -PropertyType "DWord" `
    -Value 0
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "FlipFlopProfileDirectoryName" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "PreventLoginWithFailure" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "PreventLoginWithTempProfile" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOneDrive" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOneNote" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOneNote_UWP" `
    -PropertyType "DWord" `
    -Value 0
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOutlook" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOutlookPersonalization" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeSharepoint" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeSkype" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeTeams" `
    -PropertyType "DWord" `
    -Value 1
Pop-Location

#################################
#    Other Registry Settings    #
#################################

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "fEnableTimeZoneRedirection" `
    -PropertyType "DWord" `
    -Value 1

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "DehydrateSyncedTeamSites" `
    -PropertyType "DWord" `
    -Value 1

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "FilesOnDemandEnabled" `
    -PropertyType "DWord" `
    -Value 1

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "KFMSilentOptIn" `
    -PropertyType "String" `
    -Value "$AadTenantId"

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "KFMSilentOptInWithNotification" `
    -PropertyType "DWord" `
    -Value 1

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "SilentAccountConfig" `
    -PropertyType "DWord" `
    -Value 1

New-ItemProperty `
    -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive `
    -Name "ForcedLocalMassDeleteDetection" `
    -PropertyType "DWord" `
    -Value 1
