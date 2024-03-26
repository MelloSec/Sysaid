Write-Output "Gathering sysmon event logs."
$test = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational"
Write-Output "Writing Sysmon logs to CSV: sysmonEvents.csv"
$test | Export-Csv -Path "sysmonEvents.csv" -NoTypeInformation
