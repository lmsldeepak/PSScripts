function Update-ADUserPasswordExpiry {
    [alias("extend")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $User
    )
    
    begin {

    }
    
    process {
        try {
            $Filter = "$User*"
            $ADUser = Get-ADUser -Filter { Name -like $Filter } -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed", "PasswordNeverExpires"
        }
        catch {
            $Error.Exception.Message
            break
        }
        if ($ADUser.Count -gt 1) {
            Write-Host -ForegroundColor Red "Multiple users were returned. Please narrow your search"
            $ADUser.UserPrincipalName
            break
        }
        else {
            if ($ADUser.PasswordNeverExpires) {
                $Expiry = "Never expire."
            }
            else {
                $Expiry = [datetime]::FromFileTime($ADUser.'msDS-UserPasswordExpiryTimeComputed')
            }
            "User: $($ADUser.UserPrincipalName)"
            "Expiry: $Expiry"
            write-host -ForegroundColor Yellow -Object "Press ENTER to extend password expriry"
            $KeyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($KeyPress.VirtualKeyCode -eq 13) {
                try {
                    $ADUser.PwdLastSet = 0
                    $ADUser.PasswordNeverExpires = $false
                    Set-ADUser -Instance $ADUser

                    $ADUser.pwdLastSet = -1
                    Set-ADUser -Instance $ADUser
                    Write-Host -ForegroundColor Green "Password expiry has been extended."
                }
                catch {
                    "Following error occured"
                    $Error[0].Exception.Message
                    break
                }
                $ADUser = Get-ADUser -Filter { Name -like $Filter } -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed"
                $Expiry = [datetime]::FromFileTime($ADUser.'msDS-UserPasswordExpiryTimeComputed')
                "User: $($ADUser.UserPrincipalName)"
                "Extended Expiry: $Expiry"
            }
            else {
                "Skipped updating password expiry"
            }
        }
    }
    
    end {
        
    }
}
