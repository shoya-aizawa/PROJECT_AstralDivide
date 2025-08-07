<#
.SYNOPSIS
    Play or stop audio files asynchronously from batch scripts with volume control using WMP COM with message pumping via DoEvents (no window focus steal).

.PARAMETER Path
    Full path to the audio file to play. Not required when Mode is stop.

.PARAMETER Mode
    play   - play the file once
    repeat - loop continuously
    stop   - terminate a previously started player

.PARAMETER Volume
    Integer volume level from 0 to 100. Defaults to 50 if not provided.

.EXAMPLE
    call "<path>\Play_BGM.bat" "C:\Music\Battle.wav" play 75
.EXAMPLE
    call "<path>\Play_BGM.bat" "C:\Music\Theme.wav" repeat 50
.EXAMPLE
    call "<path>\Play_BGM.bat" "" stop

.USAGE
    call "Play_BGM.bat" "<wav_path>" play <volume>
    call "Play_BGM.bat" "<wav_path>" repeat <volume>
    call "Play_BGM.bat" "" stop
#>
param(
    [string]$Path,
    [ValidateSet('play','repeat','stop')][string]$Mode = 'play',
    [ValidateRange(0,100)][int]$Volume = 50
)

# Path to PID file
$pidFile = Join-Path $PSScriptRoot 'player.pid'

# Stop mode: terminate previous instance
if ($Mode -eq 'stop') {
    if (Test-Path $pidFile) {
        Stop-Process -Id (Get-Content $pidFile) -ErrorAction SilentlyContinue
        Remove-Item $pidFile -ErrorAction SilentlyContinue
    }
    exit
}

# Ensure STA for COM
if ($Host.Runspace.ThreadOptions -ne 'ReuseThread') {
    powershell -Sta -NoLogo -NoProfile -WindowStyle Hidden -File $PSCommandPath -Path $Path -Mode $Mode -Volume $Volume
    exit
}

# Load WinForms for event pumping
Add-Type -AssemblyName System.Windows.Forms

# Instantiate Windows Media Player COM object
$player = New-Object -ComObject WMPlayer.OCX
$player.settings.volume = $Volume
$player.URL            = (Resolve-Path $Path).ProviderPath
if ($Mode -eq 'repeat') {
    $player.settings.setMode('loop', $true)
}

# Save this process ID for external stop
Set-Content -Path $pidFile -Value $PID -NoNewline

# Begin playback
$player.controls.play()

# Pump COM messages without stealing focus
while ($true) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100
}
