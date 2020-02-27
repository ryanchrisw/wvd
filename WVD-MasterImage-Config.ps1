<#Author       : Chris Williams
# Creation Date: 2-18-2020
# Usage        : WVD - Master Image Provision

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 02/18/2020                     1.0        Intial Version
#
#*********************************************************************************
#
#>


##############################
#    WVD Script Parameters   #
##############################
Param (
    [Parameter(Mandatory=$true)]
        [string]$CCDLocation,
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken
)


######################
#    WVD Variables   #
######################
$Localpath               = "c:\temp\wvd\"
$WVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$FSLogixURI              = 'https://go.microsoft.com/fwlink/?linkid=2084562'
$FSInstaller             = 'FSLogixAppsSetup.zip'
$WVDAgentInstaller       = 'WVD-Agent.msi'
$WVDBootInstaller        = 'WVD-Bootloader.msi'
$CatoCertURI             = 'https://automate.compassmsp.com/softwarepackages/CatoNetworksTrustedRootCA.cer'
$CatoCert                = 'CatoNetworksTrustedRootCA.cer'


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
#    Download WVD Componants    #
#################################
Invoke-WebRequest -Uri $WVDBootURI -OutFile "$Localpath$WVDBootInstaller"
Invoke-WebRequest -Uri $WVDAgentURI -OutFile "$Localpath$WVDAgentInstaller"
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$Localpath$FSInstaller"
Invoke-WebRequest -Uri $CatoCertURI -OutFile "$Localpath$CatoCert"


###########################
#    Install Cato Cert    #
###########################
Import-Certificate -FilePath "$Localpath$CatoCert" -CertStoreLocation Cert:\LocalMachine\Root


##############################
#    Prep for WVD Install    #
##############################
Expand-Archive `
    -LiteralPath "C:\temp\wvd\$FSInstaller" `
    -DestinationPath "$Localpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $Localpath


################################
#    Install WVD Componants    #
################################
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDBootInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "/l* $Localpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$RegistrationToken", "/l* $Localpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Wait-Event -Timeout 5


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
    -Name "Enabled" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "VolumeType" `
    -PropertyType "String" `
    -Value "vhdx"    
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
    -Name "Enabled" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path .\FSLogix\ODFC `
    -Name "IncludeOfficeActivation" `
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
    -Name fEnableTimeZoneRedirection `
    -PropertyType DWORD `
    -Value 1






