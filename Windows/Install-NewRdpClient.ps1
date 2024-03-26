$folderPath = "C:\tempRDP"
$file = "$folderPath\rdp.msi" 
$exe = "C:\Program Files\Remote Desktop\msrdcw.exe"

if (Test-Path $exe) { Write-Output "New RDP Client already installed." }
else {
       # Check if the folder exists
       if (-not (Test-Path $folderPath)) {
            # Create the folder if it doesn't exist
            New-Item -Path $folderPath -ItemType Directory }
       if (Test-Path $file) {
            # Delete any old copies of the installer
            Remove-Item -Path $file -Force }
            
        # Download the file using Invoke-WebRequest
        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2139369" -OutFile $file -UseBasicParsing

        Start-Sleep 5

        msiexec /i $file /qn 

        Start-Sleep 10

        # Clean-Up temp folder 
        if(test-path $folderPath){ Remove-Item $folderPath -Recurse -Force }

 }
