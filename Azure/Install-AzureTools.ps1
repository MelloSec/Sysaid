# Install Azure CLI and PowerShell Modules
# OS Agnostic

# Check Operating System and Install Azure CLI and Git
if ($IsWindows) {
    # Ensure Chocolatey is installed before running these commands
    # Install Azure CLI
    choco install -y azure-cli
    # Install Git
    choco install -y git
} elseif ($IsLinux) {
    # Install Azure CLI
    curl -L https://aka.ms/InstallAzureCli | bash
    # Install Git
    sudo apt-get update && sudo apt-get install -y git unizp
} else {
    Write-Output "Unsupported OS."
}

# Powershell Modules
# Install-Module PSWindowsUpdate -Accept -Force
Install-Module aadinternals -force  -AllowClobber -Scope CurrentUser
Install-Module Az -Force -AllowClobber -Scope CurrentUser
Install-Module -Name ExchangeOnlineManagement -Force  -AllowClobber -Scope CurrentUser
Install-Module MSOnline -Force  -AllowClobber -Scope CurrentUser        # OPTIONAL
Install-Module AzureADPreview -Force -AllowClobber -Scope CurrentUser  # OPTIONAL
Install-Module AzureAD -Force  -AllowClobber -Scope CurrentUser
# Install-Module Microsoft.Graph -Force  -AllowClobber -Scope CurrentUser # OPTIONAL
