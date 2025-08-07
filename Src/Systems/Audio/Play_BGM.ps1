param(
    [string]$Path,
    [ValidateSet('play','repeat','stop')][string]$Mode = 'play',
    [ValidateRange(0,100)][int]$Volume = 50
)

$pidFile = Join-Path $PSScriptRoot 'player.pid'

if ($Mode -eq 'stop') {
    if (Test-Path $pidFile) {
        try {
            $playerPid = Get-Content $pidFile
            Stop-Process -Id $playerPid -ErrorAction SilentlyContinue
            Remove-Item $pidFile -ErrorAction SilentlyContinue
        } catch {}
    }
    exit
}

Add-Type -AssemblyName PresentationCore
$player = New-Object System.Windows.Media.MediaPlayer
$player.Open([Uri]::new((Resolve-Path $Path)))
$player.Volume = $Volume / 100

if ($Mode -eq 'repeat') {
    $player.MediaEnded.Add({
        $player.Position = [TimeSpan]::Zero
        $player.Play()
    }) | Out-Null
}

Set-Content -Path $pidFile -Value $PID
$player.Play()

if ($Mode -eq 'repeat') {
    while ($true) { Start-Sleep -Seconds 1 }
} else {
    $finishedEvent = New-Object System.Threading.AutoResetEvent($false)
    $player.MediaEnded.Add({ $finishedEvent.Set() }) | Out-Null
    $finishedEvent.WaitOne() | Out-Null
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}