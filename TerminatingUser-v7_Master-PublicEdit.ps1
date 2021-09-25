# Terminating a user in Active Directory and Azure AD.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# This script assumes you have already installed/connected to the ActiveDirectory, ExchangeOnlineManagement, and AzureAD modules.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Written by spartan4604
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -Modules ActiveDirectory
#Requires -Modules AzureAD
#Requires -Modules ExchangeOnlineManagement
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Notes / Needed additions
#
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Importing necessary modules and warning executor.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Clear-Host

Write-Host " "

Write-Warning "THIS SCRIPT WILL COMPLETELY TERMINATE AND DISABLE THE USER ENTERED BELOW. BY EXECUTING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY OF VERIFYING THE CORRECT USER IS BEING TERMINATED."

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Setting base variables and starting log.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$date = Get-Date -Format "MMddyyyy-HHmmss"

$descdate = Get-Date -Format "MMddyy-HHmm"

$cu = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host " "

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Getting information from executor.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function Get-IncidentNumber {

    do {

        $incidentnumber = Read-Host "Enter related INC# for termination log"

        if ($incidentnumber -eq "") {

            Write-Host " "

            Write-Host -ForegroundColor Red "INC# cannot be blank. Please enter the associated INC#."

            Write-Host " "

            }

    } until ($incidentnumber)

    $incidentnumber

}

$incidentnumber = Get-IncidentNumber

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host " "

Start-Transcript -Path "\\server1\TerminateUser-$incidentnumber-$date.log" -Append

Write-Host " "

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function Get-Sam {

    do {

        $user = Read-Host -Prompt "Enter the sAM of user being terminated (e.g. john.smith)"

        if ($user -eq "") {

            Write-Host " "

            Write-Host -ForegroundColor Red "Username cannot be blank. Please re-enter username."

            Write-Host " "

            }

        $userverify = $(try { Get-ADUser $user } catch { $null })

        if ($userverify -eq $null) {

            Write-Host " "

            Write-Host -ForegroundColor Red "No user exists with this sAM in Active Directory. Please verify the sAM."

            Write-Host " "

            $user = $null

            }

    } until ($user)

    $user

}

$user = Get-Sam

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host " "

Function Get-Acronym {

    do {

        $acronym = Read-Host -Prompt "Enter company acronym (123456789) of terminated user"

        $allowedacronyms = ("1", "2", "3", "4", "5", "6", "7", "8", "9")

        if ($acronym -eq "") {

            Write-Host " "

            Write-Host -ForegroundColor Red "Company acronym cannot be blank, please enter an acronym."

            Write-Host " "

            }

        if ($acronym -notin $allowedacronyms) {

            Write-Host " "

            Write-Host -ForegroundColor Red "This acronym does not match a company acronym. Please enter the terminated user's company acronym."

            Write-Host " "

            $acronym = $null

            }

    } until ($acronym)

    $acronym

}

$acronym = Get-Acronym

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$ahi = $acronym -eq "1"

$cr = $acronym -eq "2"

$divrad = $acronym -eq "3"

$radltd = $acronym -eq "4"

$rcm = $acronym -eq "5"

$tmi = $acronym -eq "6"

$ucr = $acronym -eq "7"

$usrs = $acronym -eq "8"

$windsong = $acronym -eq "9"

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Active Directory actions.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-ADUser -Identity "$user" -Properties *

Get-ADPrincipalGroupMembership -Identity "$user" | Format-List Name

$userfullname = (Get-ADUser -Identity "$user" -Properties *).Name

$managerdn = (Get-ADUser -Identity "$user" -Properties *).Manager

$dn = (Get-ADUser -Identity "$user" -Properties *).DistinguishedName

$upn = (Get-ADUser -Identity "$user" -Properties *).UserPrincipalName

$managerupn = (Get-ADUser -Identity "$managerdn" -Properties *).UserPrincipalName

Add-Type -AssemblyName System.Web

$password = [System.Web.Security.Membership]::GeneratePassword(16,4)

Disable-ADAccount -Identity "$user" -Confirm

Set-ADAccountPassword -Identity "$user" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force) -Confirm

Set-ADUser -Identity "$user" -Description "Terminated $incidentnumber-$descdate - $cu"

Get-ADUser -Identity "$user" -Properties MemberOf | foreach { 

    $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false 

    }

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if($1 -eq $true) { 

    Move-ADObject -Identity "$dn" -TargetPath "DN1"

    }

if($2 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN2"

    }

if($3 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN3"

    }

if($4 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN4"

    }

if($5 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN5"

    }

if($6 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN6"

    }

if($7 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN7"

    }

if($8 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN8"

    }

if($9 -eq $true) {

    Move-ADObject -Identity "$dn" -TargetPath "DN9"

    }

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Azure AD, ExchangeOnline and M365 actions.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$memberid = (Get-AzureADUser -ObjectId "$upn").ObjectId

Get-AzureADUser -ObjectId "$memberid" | Format-List DisplayName, UserPrincipalName, UsageLocation, AccountEnabled

try { $currentlicenses = Get-AzureADUserLicenseDetail -ObjectId "$memberid" | Format-List SkuPartNumber } catch { $null }

if ($currentlicenses -eq $null) {

    Write-Host " "

    Write-Host -ForegroundColor Yellow "$upn has no licenses assigned."

    }

if ($currentlicenses -ne $null) {

    $currentlicenses

    }

Write-Host " "

Get-AzureADUserMembership -ObjectId "$memberid" | Format-List DisplayName, Description

Write-Host " "

Set-AzureADUser -ObjectId "$memberid" -AccountEnabled $false

Revoke-AzureADUserAllRefreshToken -ObjectId "$upn"

Write-Host " "

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function Get-SharedMailbox {

    do {

        $sharedmailbox = Read-Host -Prompt "Would you like to give access to the terminated user's mailbox to another user? (Y/N)"

        if ($sharedmailbox -eq "") {

            Write-Host " "

            Write-Host -ForegroundColor Red "This prompt cannot be blank. Please indicate if you would like to give access to the terminated user's mailbox to another user."

            Write-Host " "

            }

        if ($sharedmailbox -eq "Y") {

            Write-Host " "            

            Set-Mailbox -Identity "$upn" -Type Shared

            Start-Sleep -Seconds 5

            Write-Host " "

            $mailboxuser = Read-Host -Prompt "Please enter the sAM (e.g. john.smith) of the user who you would like to give access to $user's email"

            Write-Host " "

            $mailboxupn = (Get-ADUser -Identity "$mailboxuser" -Properties *).UserPrincipalName

            Add-MailboxPermission -Identity "$upn" -User "$mailboxupn$upn" -AccessRights FullAccess -InheritanceType All

            Write-Host " "

            }

    } until ($sharedmailbox)

    $sharedmailbox

}

$sharedmailbox = Get-SharedMailbox

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host " "

$autoreplymessage = "Thanks for your email. I am no longer employed by COMPANY. Please contact $managerupn if you need assistance."

Function Get-AutomaticReplies {

    do {

        $automaticreplies = Read-Host -Prompt "Would you like to set automatic replies for this user? (Y/N)"

        if ($automaticreplies -eq "") {

            Write-Host " "

            Write-Host -ForegroundColor Red "This prompt cannot be blank. Please indicate if you would like to enable automatic replies for the user."

            Write-Host " "

            }

        if ($automaticreplies -eq "Y") {

            Write-Host " "
            
        Set-MailboxAutoReplyConfiguration -Identity "$upn" -AutoReplyState Enabled -InternalMessage "$autoreplymessage" -ExternalAudience All -ExternalMessage "$autoreplymessage"

            Write-Host " "

            }

    } until ($automaticreplies)

    $automaticreplies

}

$automaticreplies = Get-AutomaticReplies

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$userlist = Get-AzureADUser -ObjectID $upn

$skus = $userlist | Select-Object -ExpandProperty Assignedlicenses | Select-Object SkuID

    if ($userlist.Count -ne 0) {

        if ($skus -is [array]) {

            $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.Assignedlicenses

            for ($i=0; $i -lt $skus.Count; $i++) {

                $licenses.Removelicenses +=  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $skus[$i].SkuId -EQ).SkuID
                
                }

            Set-AzureADUserLicense -ObjectId $upn -Assignedlicenses $licenses

        } else {

            $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.Assignedlicenses

            $licenses.Removelicenses =  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $skus.SkuId -EQ).SkuID

            Set-AzureADUserLicense -ObjectId $upn -Assignedlicenses $licenses

            }

}

Write-Host " "

Write-Host -ForegroundColor Cyan "Detecting and removing cloud-based groups, please wait..."

Write-Host " "

$ErrorActionPreference = 'SilentlyContinue'

Get-AzureADUserMembership -ObjectId "$memberid" | Select-Object ObjectId | foreach { 

    Remove-AzureADGroupMember -ObjectId $_.ObjectId -MemberId "$memberid" -ErrorAction SilentlyContinue
    
    }

$userdn = (Get-EXORecipient -Identity "$upn").DistinguishedName

$distrogroups = Get-EXORecipient -Filter "Members -like '$userdn'" -RecipientTypeDetails MailUniversalDistributionGroup, MailUniversalSecurityGroup

foreach ($group in $distrogroups) { 

    Remove-DistributionGroupMember -Identity $group.Identity -Member "$upn" -Confirm:$false -ErrorAction SilentlyContinue 
    
    }

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$propertyseconds = 15

1..$propertyseconds |

foreach {

    $percent = $_ * 100 / $propertyseconds;

    Write-Progress -Activity "Waiting for actions to take effect and displaying properties..." -Status "$($propertyseconds - $_) seconds remaining..." -PercentComplete $percent;

    Start-Sleep -Seconds 1

    }

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Displaying Active Directory, Azure Active Directory, and Microsoft 365 properties.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-ADUser -Identity "$user" -Properties *

Get-AzureADUser -ObjectId "$upn" | Format-List *

Get-AzureADUser -ObjectId "$memberid" | Format-List DisplayName, UserPrincipalName, UsageLocation, AccountEnabled

try { $licensecheck = Get-AzureADUserLicenseDetail -ObjectId "$memberid" | Format-List SkuPartNumber } catch { $null }

if ($licensecheck -eq $null) {

    Write-Host " "

    Write-Host -ForegroundColor Yellow "$upn has no licenses assigned."

    }

if ($licensecheck -ne $null) {

    $licensecheck

    }

Clear-Host

Write-Host " "

Write-Host -ForegroundColor DarkRed "$userfullname terminated. To view all details, see log."

Write-Host " "

Stop-Transcript

Write-Host " "

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Alerting to script completion.
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

[System.Console]::Beep(1750,200)

[System.Console]::Beep(1500,200)

[System.Console]::Beep(1500,225)