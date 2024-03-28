Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
Install-module PSwindowsUpdate -Force;
powershell -ep bypass Import-Module PSwindowsUpdate -Force;
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ep bypass -c powershell -ep bypass Start-Transcript -Path "~\Desktop\updatelog.txt" -Append; powershell -ep bypass Import-Module PSWindowsUpdate -Force; powershell -ep bypass Get-WindowsUpdate -Install -AcceptAll -Verbose; powershell -ep bypass Stop-Transcript
