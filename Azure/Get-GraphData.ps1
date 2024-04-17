# interface for graph takes accesstoken and URI
function Get-GraphData {
    # Based on https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
    # GET data from Microsoft Graph.
        param (
            [parameter(Mandatory = $true)]
            $AccessToken,
    
            [parameter(Mandatory = $true)]
            $Uri
        )
    
        # Check if authentication was successful.
        if ($AccessToken) {
        $Headers = @{
             'Content-Type'  = "application\json"
             'Authorization' = "Bearer $AccessToken" 
             'ConsistencyLevel' = "eventual"  }
    
            # Create an empty array to store the result.
            $QueryResults = @()
    
            # Invoke REST method and fetch data until there are no pages left.
            do {
                $Results = ""
                $StatusCode = ""
    
                do {
                    try {
                        $Results = Invoke-RestMethod -Headers $Headers -Uri $Uri -UseBasicParsing -Method "GET" -ContentType "application/json"
    
                        $StatusCode = $Results.StatusCode
                    } catch {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
    
                        if ($StatusCode -eq 429) {
                            Write-Warning "Got throttled by Microsoft. Sleeping for 45 seconds..."
                            Start-Sleep -Seconds 45
                        }
                        else {
                            Write-Error $_.Exception
                        }
                    }
                } while ($StatusCode -eq 429)
    
                if ($Results.value) {
                    $QueryResults += $Results.value
                }
                else {
                    $QueryResults += $Results
                }
    
                $uri = $Results.'@odata.nextlink'
            } until (!($uri))
    
            # Return the result.
            $QueryResults
        }
        else {
            Write-Error "No Access Token"
        }
    }