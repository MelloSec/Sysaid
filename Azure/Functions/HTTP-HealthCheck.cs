using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace biHealthCheck
{
    public static class Function1
    {
        private static readonly HttpClient httpClient = new HttpClient();

        [FunctionName("Function1")]
        public static async Task RunTimer(
            [TimerTrigger("0 0 */12 * * *")] TimerInfo myTimer,
            ILogger log)
        {
            
            // Store full URI to target hosts list, Teams Channel Incoming Webhook (or whatever) and grab the ConnectionString
            string blobUri = Environment.GetEnvironmentVariable("BlobUri");
            string webhookUrl = Environment.GetEnvironmentVariable("webhookUrl");
            string connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");

            // Call the Method that acts as our Blob Client and get an array of IPs/Hostnames work, too
            string[] ipAddresses = await ReadIpAddressesFromBlobAsync(blobUri, connectionString);


            // Set Adaptive Card Image URL Here for a nice touch.... of mayhem 
            string imageUrl = "https://i.redd.it/lprym5wfcw681.jpg";

            bool allOnline = true;

            foreach (var ipAddress in ipAddresses)
            {
                int retryCount = 0;
                bool success = false;

                while (retryCount < 3)
                {
                    try
                    {
                      // Change to HTTPs if needed
                      HttpResponseMessage response = await httpClient.GetAsync($"http://{ipAddress}");

                      // Or Use Conditional
                      // Try HTTPS first
                      // response = await httpClient.GetAsync($"https://{ipAddress}");
                      // if success, log and set true / else 
                      //  HttpResponseMessage response = await httpClient.GetAsync($"http://{ipAddress}");
                      // if success set bool / else         log.LogWarning($"Failed to reach IP address {ipAddress} using both HTTPS and HTTP. Retrying...");
                      // await Task.Delay(TimeSpan.FromMinutes(3));
                      // retryCount++;
        
                        if (response.IsSuccessStatusCode)
                        {
                            success = true;
                            log.LogInformation($"IP address {ipAddress} is online.");

                            break;
                        }
                        else
                        {
                            log.LogWarning($"Failed to reach IP address {ipAddress}. Retrying...");
                            await Task.Delay(TimeSpan.FromMinutes(3));
                            retryCount++;
                        }
                    }
                    catch (Exception ex)
                    {
                        log.LogError($"An error occurred while testing IP address {ipAddress}: {ex.Message}");
                        retryCount++;
                    }
                }

                if (!success)
                {
                    log.LogError($"Failed to reach IP address {ipAddress} after 3 retries.");
                    allOnline = false;

                    var adaptiveCardJson = $@"{{
    ""type"": ""message"",
    ""attachments"": [
        {{
            ""contentType"": ""application/vnd.microsoft.card.adaptive"",
            ""content"": {{
                ""type"": ""AdaptiveCard"",
                ""body"": [
                    {{
                        ""type"": ""TextBlock"",
                        ""text"": ""Service Disrupted - One or More Hosts are Offline"",
                        ""size"": ""Large"",
                        ""weight"": ""Bolder"",
                        ""color"": ""Attention""
                    }},
                    {{
                        ""type"": ""TextBlock"",
                        ""text"": ""Failed to reach IP address {ipAddress} after 3 retries.""
                    }},
                    {{
                        ""type"": ""Image"",
                        ""url"": ""{imageUrl}"",
                        ""size"": ""Medium""
                    }}
                ],
                ""$schema"": ""http://adaptivecards.io/schemas/adaptive-card.json"",
                ""version"": ""1.0""
            }}
        }}
    ]
}}";


                    var content = new StringContent(adaptiveCardJson, Encoding.UTF8, "application/json");
                    var response = await httpClient.PostAsync(webhookUrl, content);

                    if (response.IsSuccessStatusCode)
                    {
                        log.LogInformation($"Failed to reach IP address {ipAddress}. Adaptive Card notification posted to webhook.");
                    }
                    else
                    {
                        log.LogError($"Failed to post Adaptive Card notification to webhook for failed IP address {ipAddress}. Status code: {response.StatusCode}");
                    }
                }
            }

            if (allOnline)
            {
                var adaptiveCardJson = $@"{{
    ""type"": ""message"",
    ""attachments"": [
        {{
            ""contentType"": ""application/vnd.microsoft.card.adaptive"",
            ""content"": {{
                ""type"": ""AdaptiveCard"",
                ""body"": [
                    {{
                        ""type"": ""TextBlock"",
                        ""text"": ""Status Okay - Target Hosts Online"",
                        ""size"": ""Large"",
                        ""weight"": ""Bolder"",
                        ""color"": ""Good""
                    }},
                    {{
                        ""type"": ""TextBlock"",
                        ""text"": ""All systems are responding to requests.""
                    }},
                    {{
                        ""type"": ""Image"",
                        ""url"": ""{imageUrl}"",
                        ""size"": ""Medium""
                    }}
                ],
                ""$schema"": ""http://adaptivecards.io/schemas/adaptive-card.json"",
                ""version"": ""1.0""
            }}
        }}
    ]
}}";

                var content = new StringContent(adaptiveCardJson, Encoding.UTF8, "application/json");
                var response = await httpClient.PostAsync(webhookUrl, content);

                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation("Adaptive Card message sent successfully.");
                }
                else
                {
                    log.LogError($"Failed to send Adaptive Card message. Status code: {response.StatusCode}");
                }
            }
        }

        // store the full URI to the hosts list in a storage container, use connectionstring, SAS or Managed ID 'Storage Account Blob Reader' on the Function App to read them in
        async static Task<string[]> ReadIpAddressesFromBlobAsync(string blobUri, string connectionString)
        {
            BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);

            UriBuilder uriBuilder = new UriBuilder(blobUri);
            string blobContainerName = uriBuilder.Uri.Segments[1];
            string blobName = uriBuilder.Uri.Segments[2];

            BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(blobContainerName);
            BlobClient blobClient = containerClient.GetBlobClient(blobName);

            List<string> ipAddresses = new List<string>();

            using (MemoryStream stream = new MemoryStream())
            {
                await blobClient.DownloadToAsync(stream);
                string blobContent = Encoding.UTF8.GetString(stream.ToArray());
                ipAddresses.AddRange(blobContent.Split(Environment.NewLine));
            }

            return ipAddresses.ToArray();
        }
    }
}
