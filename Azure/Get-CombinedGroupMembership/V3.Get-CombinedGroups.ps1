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
                "Member Name" = $member.displayName
                "Member Email" = $member.mail
            }
        }
    }
}

# Export CSV
$unifiedGroupMembers | Export-Csv -Path "Unified-GroupMembership.csv" -NoTypeInformation
$distroUri = "https://graph.microsoft.com/v1.0/groups?$filter=groupTypes/any(c:c eq 'Distribution')"
$distroResponse = Invoke-RestMethod -Headers $headers -Uri $distroUri -Method Get
$distroGroups = $distroResponse.value

$DistroGroupMembers = @()

foreach ($group in $distroGroups) {
    Write-Host "Processing Distribution group: $($group.displayName)" -ForegroundColor Yellow

    $membersUri = "https://graph.microsoft.com/v1.0/groups/$($group.id)/members"
    $membersResponse = Invoke-RestMethod -Headers $headers -Uri $membersUri -Method Get
    $members = $membersResponse.value
    
    foreach ($member in $members) {
        if ($member.mail -ne $null) {
            Write-Host  -ForegroundColor Yellow " - $($member.displayName) <$(($member.mail))>"
            $DistroGroupMembers += [PSCustomObject]@{
                "Group Name" = $group.displayName
                "Member Name" = $member.displayName
                "Member Email" = $member.mail
            }
        }
    }
}

# Export CSV
$DistroGroupMembers | Export-Csv -Path "Distribution-GroupMembership.csv" -NoTypeInformation

# Compare groupIds to find the ones in common 
$distroGroupIds = $distroGroups | Select-Object -ExpandProperty id
$unifiedGroupIds = $unifiedGroups | Select-Object -ExpandProperty id
$commonGroupIds = $distroGroupIds | Where-Object { $_ -in $unifiedGroupIds }

# Output the results
if ($commonGroupIds.Count -gt 0) {
    "Found common groups between Distribution and Unified types:"
    $commonGroups = $distroGroups | Where-Object { $_.id -in $commonGroupIds }
    foreach ($group in $commonGroups) {
        " - $($group.displayName) (ID: $($group.id))"
    }
} else {
    "No common groups found between Distribution and Unified types."
}
