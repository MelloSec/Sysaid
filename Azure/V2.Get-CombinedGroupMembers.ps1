# Combined Group Membership V2 - Graph Edition
# The MG PowerShell module for the Graph isn't good and the script worked sometimes.
# Direct method using Graph

# Initiate the Device Code Flow 
$body = @{
    "client_id" =     "1950a258-227b-4e31-a9cf-717495945fc2"
    "resource" =      "https://graph.microsoft.com"
}
$UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
$Headers=@{}
$Headers["User-Agent"] = $UserAgent
$authResponse = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$authResponse


# Wait so we can browse to https://microsoft.com/devicelogin and use the device_code
Read-Host  "Once you have completed the device code flow, press enter to continue"

# finally execute this command to ask for  a set of Access/Refresh tokens
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
$Tokens

# Store the access token in a variable for easy use
$accessToken = $Tokens.access_token

# Prepare the Authorization header with the access token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Retrieve all Unified Groups
$groupsUri = "https://graph.microsoft.com/v1.0/groups?$filter=groupTypes/any(c:c eq 'Unified')"
$groupsResponse = Invoke-RestMethod -Headers $headers -Uri $groupsUri -Method Get
$unifiedGroups = $groupsResponse.value

$unifiedGroupMembers = @()

foreach ($group in $unifiedGroups) {
    Write-Host "Processing unified group: $($group.displayName)" -ForeGroundColor DarkBlue
    
    # Step 2: Iterate through each Unified Group to get its members
    $membersUri = "https://graph.microsoft.com/v1.0/groups/$($group.id)/members"
    $membersResponse = Invoke-RestMethod -Headers $headers -Uri $membersUri -Method Get
    $members = $membersResponse.value
    
    foreach ($member in $members) {
        # Some members might not have a primary SMTP address directly accessible
        # This part assumes member type as user for simplification
        if ($member.mail -ne $null) {
            Write-Host " - $($member.displayName) <$(($member.mail))>" -ForeGroundColor DarkYellow
            $unifiedGroupMembers += [PSCustomObject]@{
                "Group Name" = $group.displayName
                "Member Name" = $member.displayName
                "Member Email" = $member.mail
            }
        }
    }
}

# Export the collected data to a CSV file
$unifiedGroupMembers | Export-Csv -Path "Unified-GroupMembership.csv" -NoTypeInformation

# Refresh the Access Token as best-practice (and example)

# Define the required parameters
$tenantId = "common" # Can use 'common' or specify your tenant ID if multi-tenant 
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2" # Client ID for public client (as used in device code flow)
$refreshToken = $Tokens.refresh_token # Refresh token acquired from previous authentication
$resource = "https://graph.microsoft.com" # Target resource; adjust if needed

# OAuth 2.0 Token Endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Body for the token refresh request
$body = @{
    client_id = $clientId
    scope = "https://graph.microsoft.com/.default"
    refresh_token = $refreshToken
    grant_type = "refresh_token"
    redirect_uri = "https://login.microsoftonline.com/common/oauth2/nativeclient" # Default redirect URI for public clients
}

# Headers for the request
$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Send the request to refresh the token
$refreshResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -Headers $headers

# Access the new access token from the response
$newAccessToken = $refreshResponse.access_token

# Assuming $accessToken holds a valid token

$headers = @{
    Authorization = "Bearer $newAccessToken"
    "Content-Type" = "application/json"
}

# List all groups
$groupsUri = "https://graph.microsoft.com/v1.0/groups"
$groupsResponse = Invoke-RestMethod -Headers $headers -Uri $groupsUri -Method Get
$allGroups = $groupsResponse.value

$groupMembersInfo = @()

foreach ($group in $allGroups) {
    # Check if the group is a distribution group
    if ($group.mailEnabled -eq $true -and $group.securityEnabled -eq $false) {
        Write-Host "Processing distribution group: $($group.displayName)" -ForeGroundColor DarkYellow
        
        # List members of the distribution group
        $membersUri = "https://graph.microsoft.com/v1.0/groups/$($group.id)/members"
        $membersResponse = Invoke-RestMethod -Headers $headers -Uri $membersUri -Method Get
        $members = $membersResponse.value
        
        foreach ($member in $members) {
            if ($null -ne $member.mail) {             
                $groupMembersInfo += [PSCustomObject]@{
                    "Group Name" = $group.displayName
                    "Member Name" = $member.displayName
                    "Member Email" = $member.mail
                }
            }
        }
    }
}

# Export to CSV
$groupMembersInfo | Export-Csv -Path "DistributionGroupMemberships.csv" -NoTypeInformation

# Use a BackgroundColor with ForegroundColor for a calming closer
Write-Host "Job Finished - Your reports are in the current directory as 'Unified-GroupMembership.csv' and 'Distribution-GroupMembership.csv'" -ForegroundColor Black -BackgroundColor DarkBlue



