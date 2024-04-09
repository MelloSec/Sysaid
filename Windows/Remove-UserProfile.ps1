param (
    [string]$username
)

$userFolder = "C:\Users\$username"

# Check if the folder exists
if (Test-Path -Path $userFolder -PathType Container) {
    # Remove the folder forcefully and recursively
    Remove-Item -Path $userFolder -Recurse -Force
    Write-Host "User folder '$username' removed successfully."
} else {
    Write-Host "User folder '$username' does not exist."
}
