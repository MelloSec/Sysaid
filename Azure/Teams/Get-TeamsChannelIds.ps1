[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TeamName,
    [string]$ChannelName = "General"
    
)

# Install-Module -Name MicrosoftTeams
Import-Module MicrosoftTeams

Connect-MicrosoftTeams

$team = Get-Team -DisplayName $TeamName

if ($team) {
    # Get the channel named "General" within the team
    $channel = Get-TeamChannel -GroupId $team.GroupId -DisplayName "$ChannelName"

    if ($channel) {
        # Output the GroupId and ChannelId
        Write-Output "Group Id: $($team.GroupId)"
        Write-Output "Channel Id: $($channel.Id)"
    } else {
        Write-Output "Channel 'General' not found in the team 'Security'."
    }
} else {
    Write-Output "Team 'Security' not found."
}
