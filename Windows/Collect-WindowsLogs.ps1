BEGIN
{
    $baseDirectory = "C:\WINDOWS\TEMP\" 
    $targetCompressedFilePath = $baseDirectory + $env:computername + "eventlog" + (get-date -f _yyyyMMdd-HHmmss)
}
PROCESS
{
    # Create a temporary folder for the exporated logs
    $output = New-Item -ItemType Directory -Path $targetCompressedFilePath -Force

    # build menu of eventlog files to export
    $index =1;
    $logList=@()
    $logList += New-Object psobject -Property @{LogFileName="All"; Option=$index}
    $index+=1
   
    $logFiles = Get-WmiObject Win32_NTEventlogFile 

    $output = foreach($logFile in $logFiles)
    {
        $exportFileName = $logFile.LogfileName + (get-date -f _yyyyMMdd-HHmmss) + ".evt"            
        $logFile.backupeventlog($targetCompressedFilePath + '\\' + $exportFileName)
    }   

    # compress the temporary folder to compresses file
    Compress-Archive -Path $targetCompressedFilePath -DestinationPath $targetCompressedFilePath -CompressionLevel Optimal
    # remove the temporary folder 
    Remove-Item -Path $targetCompressedFilePath -Recurse        

    Write-Host "compressed eventlog archive saved to:"
    Write-Host "$($targetCompressedFilePath).zip"
}
END {}
