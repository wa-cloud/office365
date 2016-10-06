<#TODO
# Tidy for script operation with parameters
# Parameters for write and rollback
# Implement pssessions for remote operation
#>

    <#
    .SYNOPSIS
    Set UPN for Active Directory users based on their email address 

    .DESCRIPTION
    Gather AD Users, their UPN and e-mail address ready for setting the UPN to email address.
	Provides a "before" csv of orignal user state.
     
    .NOTES  
        Filename      : Set-UPNfromEmail.ps1
        Version       : 1.0 
        Update Date   : 20160530
        Author        : Robert Blackstock / Troy Stephens
        Contact       : robert.blackstock@dsr.wa.gov.au / troy.stephens@dsr.wa.gov.au
        Requires      : PowerShell V3, Active Directory Module
#>

# Query AD for list of all computer objects in OUs "Servers" and "Domain Controllers"
$adusers = ""
$OUpaths = @("OU=Users,OU=Container,DC=domain,DC=com,DC=au")
$adUsers = $OUpaths | foreach { Get-AdUser -Filter * -SearchBase $_ -SearchScope OneLevel -Properties DisplayName,SamAccountName,UserPrincipalName,Mail }

#Backup AD User Properties
$adUsers | ConvertTo-CSV | Out-File ADUserList_Original.csv

#Setup Arrays for use in the loops
$previewUsers = @()

#Gather Information for Preview CSV
foreach ($user in $adUsers)
    {
		$eMail = $user.Mail | Out-String
        $eMail = $eMail -replace [Environment]::NewLine, "";
        $eMail = $eMail.ToLower()

		$previewUser = New-Object System.Object
		$previewUser | Add-Member -type NoteProperty -name DisplayName -value $user.DisplayName
		$previewUser | Add-Member -type NoteProperty -name SamAccountName -value $user.SamAccountName
		$previewUser | Add-Member -type NoteProperty -name Mail -value $user.Mail
		$previewUser | Add-Member -type NoteProperty -name UserPrincipalName -value $eMail
		$previewUsers += $previewUser
    }

#Export all AD User Properties to CSV
$previewUsers | Select-Object DisplayName, SamAccountName,Mail, UserPrincipalName | ConvertTo-CSV | Out-File ADUserList_Modified.csv

Write-Host "Please review the csv export and ensure all changes are correct"
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


#Write email into UPN attribute
Foreach ($user in $previewUsers) {
    Set-ADUser -Identity $user.SamAccountName -UserPrincipalName $user.UserPrincipalName
}

#Revert to original UPN
#$originalUsers = Import-CSV ADUserList_Original.csv
#Foreach ($user in $originalUsers) { Set-ADUser -Identity $user.SamAccountName -UserPrincipalName $user.UserPrincipalName }