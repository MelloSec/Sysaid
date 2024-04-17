param(
    [Parameter(Mandatory=$true)]
    [string]$UserName,

    [Parameter(Mandatory=$true)]
    [System.Security.SecureString]$Password
)

# Convert the secure string password to a plain text string to use with New-LocalUser
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Attempt to create the new local user
try {
    $user = New-LocalUser -Name $UserName -Password (ConvertTo-SecureString -String $PlainTextPassword -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Description "User created via PowerShell script"
    Write-Host "User '$($user.Name)' created successfully."
} catch {
    Write-Error "Failed to create user. Error: $_"
}

# $SecurePassword = ConvertTo-SecureString "PlainTextPasswordHere" -AsPlainText -Force
# .\CreateLocalUser.ps1 -UserName "NewUserName" -Password $SecurePassword
