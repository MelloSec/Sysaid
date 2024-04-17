# Initiate the Device Code Flow 
$body = @{
    # This client_id is "Azure PowerShell" it's how the portal knows and asks when you use the device code flow
    "client_id" =     "1950a258-227b-4e31-a9cf-717495945fc2"
    "resource" =      "https://graph.microsoft.com"
}

$UserAgent = "Mellozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
$Headers=@{}
$Headers["User-Agent"] = $UserAgent
$authResponse = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$authResponse

# Wait (Read-Host) so we can browse to https://microsoft.com/devicelogin and use the device_code
Read-Host  "Once you have completed the device code flow, press enter to continue"

# Request a set of Tokens
$body=@{
    "client_id" =  "1950a258-227b-4e31-a9cf-717495945fc2"
    "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
    "code" =       $authResponse.device_code
}
$Tokens = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0" `
    -Headers $Headers `
    -Body $body

# Store the access token in a variable for easy use
$accessToken = $Tokens.access_token

# Prepare the Authorization header with the access token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Retrieve all Unified Groups, using the groupTypes filtering on 'Unified'
$groupsUri = "https://graph.microsoft.com/v1.0/groups?$filter=groupTypes/any(c:c eq 'Unified')"
$groupsResponse = Invoke-RestMethod -Headers $headers -Uri $groupsUri -Method Get
$unifiedGroups = $groupsResponse.value

$unifiedGroupMembers = @()

foreach ($group in $unifiedGroups) {
    Write-Host "Processing unified group: $($group.displayName)" -ForegroundColor Yellow
    
    # Iterate to get members
    $membersUri = "https://graph.microsoft.com/v1.0/groups/$($group.id)/members"
    $membersResponse = Invoke-RestMethod -Headers $headers -Uri $membersUri -Method Get
    $members = $membersResponse.value
    
    foreach ($member in $members) {
        if ($member.mail -ne $null) {
            Write-Host  -ForegroundColor Yellow " - $($member.displayName) <$(($member.mail))>"
            $unifiedGroupMembers += [PSCustomObject]@{
                "Group Name" = $group.displayName
                "Group Email" = $group.mail
                "Member Name" = $member.displayName
                "Member Email" = $member.mail
            }
        }
    }
}

# Export CSV
$unifiedGroupMembers | Export-Csv -Path "Unified-GroupMembership.csv" -NoTypeInformation

#### Distro Lists - Have to Use ExchangeOnline
$tokenParts = $accessToken -split '\.'

# Base64Url decode the payload part
$payload = $tokenParts[1]
# Fix padding issues if necessary
$payload = $payload.PadRight([math]::Ceiling($payload.Length / 4) * 4, "=")

# Convert from Base64Url to standard Base64
$base64 = $payload -replace '-','+' -replace '_','/'

# Decode from Base64 to bytes then to a string
$bytes = [System.Convert]::FromBase64String($base64)
$jsonPayload = [System.Text.Encoding]::UTF8.GetString($bytes)

# Convert JSON string to PowerShell object
$claims = $jsonPayload | ConvertFrom-Json

# Access specific claims
# The username might be in different claims depending on the issuer (e.g., 'upn', 'email', 'preferred_username')
$username = $claims.upn
if(-not $username) { $username = $claims.email }
if(-not $username) { $username = $claims.preferred_username }

Write-Output "Username: $username"

$moduleName = "ExchangeOnlineManagement"
$module = Get-Module -Name $moduleName -ListAvailable


$tenantId = "common" # Can use 'common' or specify your tenant ID
$clientId = "d3590ed6-52b3-4102-aeff-aad2292ab01c" # specific clientId for outlook/o365

$refreshToken = $Tokens.refresh_token # Refresh token acquired from previous authentication

# OAuth 2.0 Token Endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Body for the token refresh request, targeting the outlook.office365.com resource
$body = @{
    client_id = $clientId
    scope = "https://outlook.office365.com/.default"
    refresh_token = $refreshToken
    grant_type = "refresh_token"
    #redirect_uri = "https://login.microsoftonline.com/common/oauth2/nativeclient" # Default redirect URI for public clients
}

# Headers for the request
$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Send the request to refresh the token
Write-Host "Using Refresh Token to get a new access token for Exchange/Office365" -ForegroundColor DarkBlue
$refreshResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -Headers $headers

# Access the new access token from the response
$newAccessToken = $refreshResponse.access_token

# Now you can use $newAccessToken with Connect-ExchangeOnline
# Check if the Exchange Online Management module is installed, else attempt to install missing module. Customize the 'else' block if you re-use.
if ($module) {
    # Module is installed, now check if it's imported
    if (-not (Get-Module -Name $moduleName)) {
        Import-Module $moduleName -Force
        Write-Host "$moduleName imported successfully." -ForegroundColor DarkYellow
    } else {
        Write-Host "$moduleName is already imported." -ForegroundColor DarkYellow
    }
} else {
    # Change This if you Change the Module
    # Module is not installed, provide instructions to install it
    Write-Host "$moduleName is not installed. Installing V3.4.0 or greater using 'Install-Module -Name ExchangeOnlineManagement -AllowClobber  -RequiredVersion 3.4.0'"
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber  -RequiredVersion 3.4.0
}

if (Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
    Write-Host "Connected to Exchange Online."
} else {
    
    Write-Host "Connecting to Exchange Online using refreshed access token for https://outlook.office365.com" -ForegroundColor DarkBlue
    #Connect-ExchangeOnline -Device
    Connect-ExchangeOnline -AccessToken $newAccessToken -UserPrincipalName $username
}

$distroGroups = Get-DistributionGroup -RecipientTypeDetails "MailUniversalDistributionGroup", "MailUniversalSecurityGroup" -ResultSize Unlimited
$distributionGroupMembers = @()
    
# Assuming $distroGroups contains the distribution groups you're interested in
foreach ($group in $distroGroups) {
        Write-Host -ForegroundColor Yellow "Processing group: $($group.Name) $($group.PrimarySmtpAddress)" 
        
        # Use Get-DistributionGroup to get the group's Primary SMTP Address (email address)
        $groupDetails = Get-DistributionGroup -Identity $group.Identity | Select-Object Name, PrimarySmtpAddress
    
        $members = Get-DistributionGroupMember -Identity $group.Identity | Select-Object DisplayName, PrimarySmtpAddress
        
        foreach ($member in $members) {
            Write-Host -ForegroundColor Yellow " - $($member.DisplayName) <$(($member.PrimarySmtpAddress))>" 
            $distributionGroupMembers += [PSCustomObject]@{
                "Group Name" = $groupDetails.Name
                "Group Email" = $groupDetails.PrimarySmtpAddress
                "Member Name" = $member.DisplayName
                "Member Email" = $member.PrimarySmtpAddress
            }
        }
    }
   
# Example of how to output or use $distributionGroupMembers
# Displaying in the console
$distributionGroupMembers | Format-Table -AutoSize
        
# Creates the files from the in memory objects without the data types data in the first line which only gets in the way for what we need to do 
$distributionGroupMembers | Export-Csv -Path "Distribution-GroupMembership.csv" -NoTypeInformation

# Compare groupIds to find the ones in common 
$distroGroupIds = $distroGroups | Select-Object -ExpandProperty id
$unifiedGroupIds = $unifiedGroups | Select-Object -ExpandProperty id
$commonGroupIds = $distroGroupIds | Where-Object { $_ -in $unifiedGroupIds }

if ($commonGroupIds.Count -gt 0) {
    Write-Host -ForegroundColor Yellow "Found common groups between Distribution and Unified types:"
    $commonGroups = $distroGroups | Where-Object { $_.id -in $commonGroupIds }
    foreach ($group in $commonGroups) {
        Write-Host -ForegroundColor DarkGreen " - $($group.displayName) (ID: $($group.id))"
    }
} else {
    Write-Host -ForegroundColor Yellow "No common groups found between Distribution and Unified types."
}

Write-Host -ForegroundColor Yellow "Number of Distribution Group IDs: $($distroGroupIds.Count)"
Write-Host -ForegroundColor Yellow "Number of Unified Group IDs: $($unifiedGroupIds.Count)"
Write-Host -ForegroundColor Yellow "Number of Common Group IDs: $($commonGroupIds.Count)"

Disconnect-ExchangeOnline -Confirm:$false

# Use a BackgroundColor with ForegroundColor for a calming closer
Write-Host "Job Finished - Your reports are in the current directory as 'Unified-GroupMembership.csv' and 'Distribution-GroupMembership.csv'" -ForegroundColor Yellow -BackgroundColor Black




