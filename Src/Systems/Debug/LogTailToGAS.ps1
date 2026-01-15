# LogTailToGAS.ps1 - Tail log file and POST new lines to GAS using FileSystemWatcher
param(
    [Parameter(Mandatory=$true)][string]$LogPath,
    [Parameter(Mandatory=$true)][string]$GasUrl
)

$logFile = Get-Item $LogPath
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $logFile.DirectoryName
$watcher.Filter = $logFile.Name
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$lastPosition = 0
$sentLogs = New-Object System.Collections.Generic.Queue[string]

Write-Host "Starting log tail for $LogPath, posting to $GasUrl using FileSystemWatcher"

$action = {
    try {
        $stream = [System.IO.File]::Open($LogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $stream.Position = $lastPosition
        $reader = New-Object System.IO.StreamReader $stream
        while (!$reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ($line -and -not $sentLogs.Contains($line)) {
                $body = @{log = $line}
                Invoke-WebRequest -Uri $GasUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction SilentlyContinue
                $sentLogs.Enqueue($line)
                if ($sentLogs.Count -gt 1000) {
                    $sentLogs.Dequeue() | Out-Null
                }
            }
        }
        $lastPosition = $stream.Position
        $reader.Close()
        $stream.Close()
    } catch {
        Write-Host "Error in tail: $_"
    }
}

Register-ObjectEvent $watcher "Changed" -Action $action

# Keep the script running
while ($true) { Start-Sleep -Seconds 1 }