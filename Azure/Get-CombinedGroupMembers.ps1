try {
    $output = pwsh -Command "$PSVersionTable.PSVersion"
    if ($output) {
        Write-Output "PowerShell 7 installed! Lock and load."
    }
} catch {
    $seven = @"
To install PowerShell 7 on Windows, follow these steps:
1. Visit the GitHub releases page for PowerShell: https://github.com/PowerShell/PowerShell/releases
2. Download the latest stable release for Windows.
3. Run the installer and follow the instructions.
Once installed, you can launch PowerShell 7 using the 'pwsh' command.
"@
    Write-Output "Please install PowerShell 7 then use 'pwsh .\Get-CombinedGroupMemberss.ps1'"
    Write-Output $seven
}

# Check if the script is running in PowerShell 7 or higher
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7+. Please install then use 'pwsh .\Get-CombinedGroupMembers.ps1'" -ForegroundColor Darkyellow
    throw "This script requires PowerShell 7 or higher. Please upgrade to continue."
} else {
    Write-Output "Running in PowerShell 7 or higher. Proceeding..."
}

# Define the module name
$moduleName = "ExchangeOnlineManagement"

# Check if the Exchange Online Management module is installed
$module = Get-Module -Name $moduleName -ListAvailable

if ($module) {
    # Module is installed, now check if it's imported
    if (-not (Get-Module -Name $moduleName)) {
        Import-Module $moduleName
        Write-Host "$moduleName imported successfully."
    } else {
        Write-Host "$moduleName is already imported."
    }
} else {
    # Module is not installed, provide instructions to install it
    Write-Host "$moduleName is not installed. Installing V3.4.0 or greater using 'Install-Module -Name ExchangeOnlineManagement -AllowClobber  -RequiredVersion 3.4.0'"
    Install-Module -Name ExchangeOnlineManagement -AllowClobber  -RequiredVersion 3.4.0
}

# Authenticate - Requires PowerShell 7 Module
Write-Output "Connecting to Exchange Online using OAuth Device Code Flow. Follow the instructions below to authenticate."
Connect-ExchangeOnline -Device

$distributionGroups = Get-DistributionGroup
$distributionGroupMembers = @()

foreach ($group in $distributionGroups) {
    Write-Output "Processing group: $($group.Name)"
    $members = Get-DistributionGroupMember -Identity $group.Identity | Select DisplayName, PrimarySmtpAddress
    foreach ($member in $members) {
        Write-Output " - $($member.DisplayName) <$(($member.PrimarySmtpAddress))>"
        $distributionGroupMembers += [PSCustomObject]@{
            "Group Name" = $group.Name
            "Member Name" = $member.DisplayName
            "Member Email" = $member.PrimarySmtpAddress
        }
    }
}

$distributionGroupMembers | Export-Csv -Path "Distribution-GroupMembership.csv" -NoTypeInformation
Write-Output "Exported Distribution Group Members to Distribution-GroupMembership.csv"


$unifiedGroups = Get-UnifiedGroup
$unifiedGroupMembers = @()

foreach ($group in $unifiedGroups) {
    Write-Output "Processing unified group: $($group.DisplayName)"
    $members = Get-UnifiedGroupLinks -Identity $group.Identity -LinkType Members | Select DisplayName, PrimarySmtpAddress
    foreach ($member in $members) {
        Write-Output " - $($member.DisplayName) <$(($member.PrimarySmtpAddress))>"
        $unifiedGroupMembers += [PSCustomObject]@{
            "Group Name" = $group.DisplayName
            "Member Name" = $member.DisplayName
            "Member Email" = $member.PrimarySmtpAddress
        }
    }
}

$unifiedGroupMembers | Export-Csv -Path "Unified-GroupMembership.csv" -NoTypeInformation
Write-Output "Exported Unified Group Members to Unified-GroupMembership.csv"





