$appName = "Benefits Enrollment Program"
$app = az ad app create --display-name $appName | ConvertFrom-Json
$clientId = $app.appId

$sp = az ad sp create --id $clientId | ConvertFrom-Json
$servicePrincipalId = $sp.appId

# Display the Service Principal ID
Write-Host "Service Principal ID: $servicePrincipalId"

# get the subscription
$subscriptionIds = az account list --query "[].id" | ConvertFrom-Json
$subscriptionIds

$accts = az account list 
az role assignment create --assignee $servicePrincipalId --role "User Access Administrator" --scope /subscriptions/$subscriptionIds

# Create a new secret for the application
$secret = az ad app credential reset --id $clientId | ConvertFrom-Json

# Extracting the secret value
$secretValue = $secret

# Display the secret (Be careful with this operation; secrets should be kept secure!)
Write-Host "Secret Value: $secretValue"
