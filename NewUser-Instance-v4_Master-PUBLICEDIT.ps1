# Creating new user in Active Directory and Azure AD. (PUBLIC EDIT)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# This script assumes you have already installed/connected to the ActiveDirectory, MSOnline, ExchangeOnlineManagement, and AzureAD modules.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Written by spartan4604
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -RunAsAdministrator
#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -Modules ActiveDirectory
#Requires -Modules MSOnline
#Requires -Modules ExchangeOnlineManagement
#Requires -Modules AzureAD
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Notes / Needed additions
#
# - Need to update script to use Azure AD (modern) cmdlets instead of MSOnline (legacy)
#
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Importing necessary modules and warning executor.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Import-Module ActiveDirectory

Import-Module MSOnline

Import-Module ExchangeOnlineManagement

Import-Module AzureAD

Write-Warning "THIS SCRIPT IS FOR THE CREATION OF A NEW USER. BY UTILIZING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY TO ENSURE ACCURACY OF THE NEW USER'S ATTRIBUTES."

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Setting base variables and starting log.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$inc = Read-Host -Prompt "Enter related INC# for log"

if($inc -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "INC# cannot be blank. Please restart the script and enter the associated INC#."

Write-Host " "

Exit

}

$date = Get-Date -Format "MMddyyyy-HHmm"

Start-Transcript -Path "\\SERVERHERE\NewUser-$inc-$date.log" -Append

Write-Host " "

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Active Directory setup.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$usercheck = Read-Host -Prompt "Enter the intended username of the new user"

if($usercheck -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "Username cannot be blank, please restart the script and enter a username."

Write-Host " "

Exit

}

$user = $(try {Get-ADUser $usercheck} catch {$null})

if($user -ne $null){

Write-Host " "

Write-Host -ForegroundColor Red "This username is already taken in Active Directory. Please restart the script and enter a different username."

Write-Host " "

Exit

}

Else

{

Write-Host " "

Write-Host -ForegroundColor Green "This username is available, proceed with creation."

Write-Host " "

}

$template = Read-Host -Prompt "Enter the sAM of the user to mirror"

if($template -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "Template username cannot be blank. Please restart the script and enter the sAM of the user to mirror."

Write-Host " "

Exit

}

$templateaccount = Get-ADUser -Identity "$template" -Properties EmailAddress, DistinguishedName, UserPrincipalName, Country, City, Company, Description, Department, HomeDrive, HomeDirectory, Manager, Office, PostalCode, StreetAddress, State, Title

$templateaccount.UserPrincipalName = $null

$givenname = Read-Host -Prompt "Enter the first name of the new user (e.g. John)"

if($givenname -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "First name cannot be blank. Please restart the script and enter the new user's first name."

Write-Host " "

Exit

}

$surname = Read-Host -Prompt "Enter the last name of the new user (e.g. Smith)"

if($surname -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "Last name cannot be blank. Please restart the script and enter the new user's last name."

Write-Host " "

Exit

}

$name = $givenname + " " + $surname

$sam = "$usercheck"

$email = "$givenname.$surname@contoso.com"

$ou = ($templateaccount.DistinguishedName -split ",", 2)[1]

Add-Type -AssemblyName 'System.Web'

$unsecurepassword = "Templogin2021!"

$securepassword = ConvertTo-SecureString -String "$unsecurepassword" -AsPlainText -Force

$properties = @{

        Instance              = $templateaccount
        Name                  = $name
        Path                  = $ou
        SamAccountName        = $sam
        DisplayName           = $name
        GivenName             = $givenname
        Surname               = $surname
        AccountPassword       = $securepassword
        Description           = $description
        UserPrincipalName     = $email
        EmailAddress          = $email
        ChangePasswordAtLogon = $true
        Enabled               = $true

        }

New-ADUser @properties

$adminutes = 19

1..$adminutes |

ForEach-Object{

$percent = $_ * 100 / $adminutes;

Write-Progress -Activity "Waiting for Active Directory to sync..." -Status "$($adminutes - $_) minutes remaining..." -PercentComplete $percent;

Start-Sleep -Seconds 60

}

Get-ADUser -Identity "$templateaccount" -Properties * | Select-Object Memberof -ExpandProperty Memberof | Add-ADGroupMember -Members "$sam"

Add-ADGroupMember -Identity "GROUP" -Members "$sam"

[System.Console]::Beep(2000,200)

[System.Console]::Beep(2000,200)

[System.Console]::Beep(2000,200)

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Inquire about changing properties.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-ADUser -Identity "$sam" -Properties Title | Format-List Title

$changetitle = Read-Host -Prompt "Would you like to change $sam's title? (Y/N)"

if($changetitle -eq "Y"){

$titlechange = Read-Host -Prompt "Enter the desired title for $sam"

Set-ADUser -Identity "$sam" -Title "$titlechange"

}

Write-Host " "

Get-ADUser -Identity "$sam" -Properties Description | Format-List Description

$changedesc = Read-Host -Prompt "Would you like to change $sam's description? (Y/N)"

if($changedesc -eq "Y"){

$descchange = Read-Host -Prompt "Enter the desired description for $sam"

Set-ADUser -Identity "$sam" -Description "$descchange"

}

Write-Host " "

Get-ADUser -Identity "$sam" -Properties Manager | Format-List Manager

$changemanager = Read-Host -Prompt "Would you like to change $sam's manager? (Y/N)"

if($changemanager -eq "Y"){

$managerchange = Read-Host -Prompt "Enter the sAM of the desired manager for $sam"

Set-ADUser -Identity "$sam" -Manager "$managerchange"

}

Write-Host " "

$userdn = (Get-ADUser -Identity "$sam" -Properties *).DistinguishedName

$changeou = Read-Host -Prompt "Would you like to change $sam's OU? (Y/N)"

if($changeou -eq "Y"){

$ouchange = Read-Host -Prompt "Enter the DistinguishedName of the desired OU for $sam"

Move-ADObject -Identity "$userdn" -TargetPath "$ouchange"

}

Write-Host " "

$proxyaddressinquire = Read-Host -Prompt "Would you like to set a different primary email for the user? (Y/N)"

if($proxyaddressinquire -eq "Y"){

$proxyaddress = Read-Host -Prompt "Enter the desired primary email for the user, if any (e.g. SMTP:john.smith@contoso.com)"

Set-ADUser -Identity "$sam" -Add @{proxyaddresses="$proxyaddress"}

}

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Azure AD / M365 setup.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$aadminutes = 39

1..$aadminutes |

ForEach-Object{

$percent = $_ * 100 / $aadminutes;

Write-Progress -Activity "Waiting for Azure AD connect to sync..." -Status "$($aadminutes - $_) minutes remaining..." -PercentComplete $percent;

Start-Sleep -Seconds 60

}

Set-MsolUser -UserPrincipalName "$email" -UsageLocation US

Set-MsolUser -UserPrincipalName "$email" -BlockCredential $false

$templateemail = (Get-ADUser -Identity "$template").UserPrincipalName

$templatelicense = Get-MsolUser -UserPrincipalName "$templateemail" | Select-Object -ExpandProperty Licenses | Select-Object -ExpandProperty AccountSkuId

$memberid = (Get-AzureADUser -ObjectId "$templateemail").ObjectId

$refid = (Get-AzureADUser -ObjectId "$email").ObjectId

Set-MsolUserLicense -UserPrincipalName "$email" -AddLicenses $templatelicense

$ErrorActionPreference = 'SilentlyContinue'

Get-AzureADUserMembership -ObjectId "$memberid" | Select-Object ObjectId | ForEach-Object {Add-AzureADGroupMember -ObjectId $_.ObjectId -RefObjectId "$refid"}

$DistributionGroups = Get-DistributionGroup | Where-Object {(Get-DistributionGroupMember $_.Name | ForEach-Object {$_.PrimarySmtpAddress}) -contains "$templateemail"}

$DistributionGroups | ForEach-Object {Add-DistributionGroupMember -Identity $_.Identity -Member "$email"}

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Log all Active Directory and Azure AD properties.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$propertyseconds = 60

1..$propertyseconds |

ForEach-Object{

$percent = $_ * 100 / $propertyseconds;

Write-Progress -Activity "Waiting for actions to take effect and displaying properties..." -Status "$($propertyseconds - $_) seconds remaining..." -PercentComplete $percent;

Start-Sleep -Seconds 1

}

Get-ADUser -Identity "$sam" -Properties *

Get-MsolUser -UserPrincipalName "$email" | Format-List UserPrincipalName, DisplayName, isLicensed, Licenses

Write-Host " "

Write-Host -ForegroundColor Green "$name setup complete!"

Write-Host " "

Stop-Transcript

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Completion alert.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

[System.Console]::Beep(1750,225)

[System.Console]::Beep(1500,225)

[System.Console]::Beep(1500,225)