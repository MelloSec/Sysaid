# Collects and exports all members of both Unified Groups and Distribution Groups to CSV Files for da bosses.
# Requires PowerShell 7+ (pwsh.exe) and ExchangeOnline V3+ (but it still beats the graph module)
# From cmd.exe/powershell.exe terminal enter the scripts location and run 'pwsh .\Get-CombinedGroupMembers.ps1'  

# 1. House-Keeping Section - Check for and Install Dependencies before we do anything else

# Define the module name, can change this for other Modules
$moduleName = "ExchangeOnlineManagement"

# Define Help Message
$seven = @"
To install PowerShell 7 on Windows, follow these steps:
1. Visit the GitHub releases page for PowerShell: https://github.com/PowerShell/PowerShell/releases
2. Download the latest stable release for Windows.
3. Run the installer and follow the instructions.
Once installed, you can launch PowerShell 7 using the 'pwsh' command.
"@

# Check if 'pwsh' is installed and on PATH, ifnot, print a help message with link to install
try {
    $Host = pwsh -Command "$PSVersionTable.PSVersion"
    if ($Host) {
        Write-Host "PowerShell 7 installed! Lock and load." -ForegroundColor Black -BackgroundColor DarkBlue
    }
} catch {
    # Store and Display Help Message @rr@y
    Write-Host "Please install PowerShell 7 then use 'pwsh .\Get-CombinedGroupMemberss.ps1'"  -ForegroundColor Black -BackgroundColor DarkBlue
    Write-Host ""
    Write-Host $seven -ForegroundColor DarkYellow
}

# Enforce PowerShell 7 - Check if the script is running in PowerShell 7 or higher, else, throw a custom error and break back to the terminal.
# Helpful so you dont waste time trying to debug the version, it gives you what  you need to fix the error and ensures we cannot continue without the right tool
if ($PSVersionTable.PSVersion.Major -lt 7) {
    # Blank Write for Spacing of Output
    Write-Host ""
     throw "This script requires PowerShell 7 or higher. Please upgrade to continue." 
    # break
    # exit
    
} else {
    Write-Host "Running in PowerShell 7 or higher. Proceeding..."
}

# Store all the modules imported in memory so we can search them and match on the one we want (ExchangeOnline)
$module = Get-Module -Name $moduleName -ListAvailable

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

# 2. Authentication/Device Code Login - Requires PowerShell 7 Module

# Trick to check if You're already Signed in by checking if we get Output from an Exchange Cmdlet
# Use the device code - This way works on headless systems, you verify your identity with a code in the browser on any other device that's signed in
if (Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
    Write-Host "Connected to Exchange Online."
} else {
    Write-Host "Connecting to Exchange Online using OAuth Device Code Flow. Follow the instructions and use the code below below to authenticate." -ForegroundColor DarkBlue
    Connect-ExchangeOnline -Device
}

# 3. Main Logic / Building Reports

# Store All Groups as a variable and create an empty array for our PowerShell PSCustomObject (everything is an object, so we can create our own type) so we have somewhere to put all the group member objects
$distributionGroups = Get-DistributionGroup
$distributionGroupMembers = @()

# DistributionGroups - Pull the name and address as a PSObject, a special data type we customize to have the properties we want store them without the extra data returned by Cmdlet
# This part is similar to what you used in the old version to get the group memberships, we'll build the CSV from the PSCustomObject's properties later.
foreach ($group in $distributionGroups) {
    Write-Host "Processing group: $($group.Name)" -ForegroundColor DarkYellow
    $members = Get-DistributionGroupMember -Identity $group.Identity | Select DisplayName, PrimarySmtpAddress
    
    # Loop through the members and append them to the PSCustomObject with the desired properties only. 
    # PSCUstomObjects are a good way to speed up performance on processing 'big' objects via filtering out useless properties of one object and creating a new one before processing
    foreach ($member in $members) {
        Write-Host " - $($member.DisplayName) <$(($member.PrimarySmtpAddress))>" -ForegroundColor DarkYellow
        $distributionGroupMembers += [PSCustomObject]@{
            "Group Name" = $group.Name
            "Member Name" = $member.DisplayName
            "Member Email" = $member.PrimarySmtpAddress
        }
    }
}

# Write the in-memory array of objects to our CSV file plainly

# Creates the files from the in memory objects without the data types data in the first line which only gets in the way for what we need to do 
$distributionGroupMembers | Export-Csv -Path "Distribution-GroupMembership.csv" -NoTypeInformation
Write-Host "Exported Distribution Group Members to Distribution-GroupMembership.csv" -ForegroundColor Darkyellow

# UnifiedGroups - Do the exact same thing with slightly different properties to match the unified group's format, note 'DisplayName' twice instead of 'Name'
$unifiedGroups = Get-UnifiedGroup
$unifiedGroupMembers = @()

foreach ($group in $unifiedGroups) {
    Write-Host "Processing unified group: $($group.DisplayName)"
    $members = Get-UnifiedGroupLinks -Identity $group.Identity -LinkType Members | Select DisplayName, PrimarySmtpAddress
    foreach ($member in $members) {
        Write-Host " - $($member.DisplayName) <$(($member.PrimarySmtpAddress))>"
        $unifiedGroupMembers += [PSCustomObject]@{
            "Group Name" = $group.DisplayName
            "Member Name" = $member.DisplayName
            "Member Email" = $member.PrimarySmtpAddress
        }
    }
}

$unifiedGroupMembers | Export-Csv -Path "Unified-GroupMembership.csv" -NoTypeInformation
Write-Host "Exported Unified Group Members to Unified-GroupMembership.csv" -ForegroundColor Darkyellow

# 4. Close Session and Disconnect

# If you use Write-Host instead of Host, you can specify different colors to customize your Host on the terminal
Write-Host "Work complete, disconnecting from Exchange Online." -ForegroundColor DarkBlue
Disconnect-ExchangeOnline -Confirm:$false

# Use a BackgroundColor with ForegroundColor for a calming closer
Write-Host "Job Finished - Your reports are in the current directory as 'Unified-GroupMembership.csv' and 'Distribution-GroupMembership.csv'" -ForegroundColor Black -BackgroundColor DarkBlue




