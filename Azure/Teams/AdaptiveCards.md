# Status Check Functions / Incoming WebHooks

Function for HTTP Health Checks uses these, after confirming hosts are online, status is posted to an Incoming Webhook to alert admins using one of these Adaptive Cards

## Status Okay
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
                        ""text"": ""Status Okay - Target Hosts are Online"",
                        ""size"": ""Large"",
                        ""weight"": ""Bolder"",
                        ""color"": ""Good""
                    }},
                    {{
                        ""type"": ""TextBlock"",
                        ""text"": ""{successMessage}""
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
