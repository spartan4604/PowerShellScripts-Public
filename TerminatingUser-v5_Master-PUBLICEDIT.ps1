# Terminating a user in Active Directory and Azure AD. (PUBLIC EDIT)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# This script assumes you have already installed/connected to the ActiveDirectory, MSOnline, ExchangeOnlineManagement, and AzureAD modules.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Written by spartan4604
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Requires -RunAsAdministrator
# Requires -Version 5.1
# Requires -PSEdition Desktop
# Requires -Modules ActiveDirectory
# Requires -Modules MSOnline
# Requires -Modules ExchangeOnlineManagement
# Requires -Modules AzureAD
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Notes/needs
#
# - Need to update script to use Azure AD (modern) cmdlets instead of MSOnline (legacy)
#
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Importing necessary modules and warning executor.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Clear-Host

Import-Module ActiveDirectory

Import-Module MSOnline

Import-Module ExchangeOnlineManagement

Import-Module AzureAD

Write-Host " "

Write-Warning "THIS SCRIPT WILL COMPLETELY TERMINATE AND DISABLE THE USER ENTERED BELOW. BY EXECUTING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY OF VERIFYING THE CORRECT USER IS BEING TERMINATED."

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Setting base variables and starting log.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$date = Get-Date -Format "MMddyyyy-HHmmss"

$descdate = Get-Date -Format "MMddyy-HHmm"

Write-Host " "

$inc = Read-Host -Prompt "Enter related INC# for termination log"

if($inc -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "INC# cannot be blank. Please restart the script and enter the associated INC#."

Exit

}

Write-Host " "

Start-Transcript -Path "\\SERVERHERE\TerminatingUser-$inc-$date.log" -Append

Write-Host " "

$user = Read-Host -Prompt "Enter the sAM of user being terminated (e.g. john.smith)"

if($user -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "Username cannot be blank, please restart the script and enter a username."

Exit

}

$userverify = $(try {Get-ADUser $user} catch {$null})

if($userverify -eq $null){

Write-Host " "

Write-Host -ForegroundColor Red "No user exists with this sAM in Active Directory. Please verify the sAM and restart the script."

Exit

}

$userfullname = (Get-ADUser -Identity "$user" -Properties *).Name

Write-Host " "

$acronym = Read-Host -Prompt "Enter company acronym (COMPANY ACRONYMS) of terminated user"

if($acronym -eq ""){

Write-Host " "

Write-Host -ForegroundColor Red "Company acronym cannot be blank, please restart the script and enter an acronym."

Exit

}

$cu = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Add-Type -AssemblyName System.Web

$password = [System.Web.Security.Membership]::GeneratePassword(12,2)

$dn = (Get-ADUser -Identity "$user" -Properties *).DistinguishedName

$managerdn = (Get-ADUser -Identity "$user" -Properties *).Manager

$managerupn = (Get-ADUser -Identity "$managerdn" -Properties *).UserPrincipalName

$managername = (Get-ADUser -Identity "$managerdn" -Properties *).Name

$1 = $acronym -eq "1"

$2 = $acronym -eq "2"

$3 = $acronym -eq "3"

$4 = $acronym -eq "4"

$5 = $acronym -eq "5"

$6 = $acronym -eq "6"

$7 = $acronym -eq "7"

$8 = $acronym -eq "8"

$9 = $acronym -eq "9"

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Active Directory actions.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-ADUser -Identity "$user" -Properties *

Get-ADPrincipalGroupMembership -Identity "$user" | Format-List Name

Disable-ADAccount -Identity "$user" -Confirm

Set-ADAccountPassword -Identity "$user" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)

Set-ADUser -Identity "$user" -Description "Terminated $inc-$descdate - $cu"

Get-ADUser -Identity "$user" -Properties MemberOf | ForEach-Object {

$_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false

}

if($1 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($2 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($3 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($4 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($5 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($6 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($7 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($8 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

if($9 -eq $true){

Move-ADObject -Identity "$dn" -TargetPath "OU"

}

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Azure AD, ExchangeOnline and M365 actions.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$upn = (Get-ADUser -Identity "$user" -Properties *).UserPrincipalName

$memberid = (Get-AzureADUser -ObjectId "$upn").ObjectId

Get-MsolUser -UserPrincipalName "$upn" | Format-List DisplayName, UserPrincipalName, isLicensed, Licenses, BlockCredential

Get-AzureADUserMembership -ObjectId "$upn"

Set-MsolUser -UserPrincipalName "$upn" -BlockCredential $true

Revoke-AzureADUserAllRefreshToken -ObjectId "$upn"

Write-Host " "

$sharedmailbox = Read-Host -Prompt "Would you like to give access to the terminated user's mailbox to $managername, the user's listed manager? (Y/N)"

if($sharedmailbox -eq "Y"){

Set-Mailbox -Identity "$upn" -Type Shared

Add-MailboxPermission -Identity "$upn" -User "$managerupn" -AccessRights FullAccess -InheritanceType All

}

Write-Host " "

$automaticreplies = Read-Host -Prompt "Would you like to set automatic replies for this user? (Y/N)"

if($automaticreplies -eq "Y"){

Set-MailboxAutoReplyConfiguration -Identity "$upn" -AutoReplyState Enabled -InternalMessage "Thanks for your email. I am no longer employed by COMPANY. Please contact $managerupn if you need assistance." -ExternalAudience All -ExternalMessage "Thanks for your email. I am no longer employed by COMPANY. Please contact $managerupn if you need assistance."

}

(Get-MsolUser -UserPrincipalName "$upn").licenses.AccountSkuId | ForEach-Object {

Set-MsolUserLicense -UserPrincipalName "$upn" -RemoveLicenses $_

}

$ErrorActionPreference = "SilentlyContinue"

Write-Host " "

Write-Host -ForegroundColor Cyan "Detecting cloud groups, please wait..."

Get-AzureADUserMembership -ObjectId "$memberid" | Select-Object ObjectId | ForEach-Object {Remove-AzureADGroupMember -ObjectId $_.ObjectId -MemberId "$memberid"}

$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {(Get-DistributionGroupMember $_.Name | ForEach-Object {$_.PrimarySmtpAddress}) -contains "$upn"}

$DistributionGroups | ForEach-Object {Remove-DistributionGroupMember -Identity $_.Identity -Member "$upn" -Confirm:$false}

$propertyseconds = 60

1..$propertyseconds |

ForEach-Object {

$percent = $_ * 100 / $propertyseconds;

Write-Progress -Activity "Waiting for actions to take effect and displaying properties..." -Status "$($propertyseconds - $_) seconds remaining..." -PercentComplete $percent;

Start-Sleep -Seconds 1

}

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Displaying AD / M365 properties.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-ADUser -Identity "$user" -Properties *

Get-MsolUser -UserPrincipalName "$upn" | Format-List DisplayName, UserPrincipalName, isLicensed, Licenses, BlockCredential

Write-Host " "

Write-Host -ForegroundColor Green "$userfullname terminated."

Stop-Transcript

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Alerting to script completion.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

[System.Console]::Beep(1750,200)

[System.Console]::Beep(1500,200)

[System.Console]::Beep(1500,225)