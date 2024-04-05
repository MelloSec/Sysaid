# Collects and exports all members of both Unified Groups and Distribution Groups to CSV Files for reporting

# 1. House-Keeping Section
# Define the module name, can change this for other Modules
$moduleName = "ExchangeOnlineManagement"

# Check if 'pwsh' is installed and on PATH, ifnot, print a help message with link to install
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

# Enforce PowerShell 7 - Check if the script is running in PowerShell 7 or higher, throw a custom error and break back to the terminal
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7+. Please install then use 'pwsh .\Get-CombinedGroupMembers.ps1'" -ForegroundColor Darkyellow
    throw "This script requires PowerShell 7 or higher. Please upgrade to continue."
} else {
    Write-Output "Running in PowerShell 7 or higher. Proceeding..."
}

# Store all the modules imported in memory so we can search them and match on what we want to ensure is imported
$module = Get-Module -Name $moduleName -ListAvailable

# Check if the Exchange Online Management module is installed, attempt to unstall missing module. Customize the 'else' block if you re-use.
if ($module) {
    # Module is installed, now check if it's imported
    if (-not (Get-Module -Name $moduleName)) {
        Import-Module $moduleName -Force
        Write-Host "$moduleName imported successfully."
    } else {
        Write-Host "$moduleName is already imported."
    }
} else {
    # Change This if you Change the Module
    # Module is not installed, provide instructions to install it
    Write-Host "$moduleName is not installed. Installing V3.4.0 or greater using 'Install-Module -Name ExchangeOnlineManagement -AllowClobber  -RequiredVersion 3.4.0'"
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber  -RequiredVersion 3.4.0
}

# 2. Authentication/Device Code Login - Requires PowerShell 7 Module
Write-Output "Connecting to Exchange Online using OAuth Device Code Flow. Follow the instructions below to authenticate."
Connect-ExchangeOnline -Device

# 3. Logic for Building Reports
# Store All Groups as a variable and create an empty array so we have somewhere to put all the group member objects
$distributionGroups = Get-DistributionGroup
$distributionGroupMembers = @()

# DistributionGroups - Pull the name and address as a PSObject, a special data type we customize to have the properties we want and not all the data 
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

# Write the in-memory array of objects to our CSV file plainly
$distributionGroupMembers | Export-Csv -Path "Distribution-GroupMembership.csv" -NoTypeInformation
Write-Output "Exported Distribution Group Members to Distribution-GroupMembership.csv"

# UnifiedGroups - Do the exact same thing with different properties to match unified groups, note 'DisplayName' twice instead of 'Name'
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

Write-Output "Your reports are in the current directory as 'Unified-GroupMembership.csv' and 'Distribution-GroupMembership.csv'"




