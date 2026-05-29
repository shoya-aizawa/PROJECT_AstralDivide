@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

rem =============================================================================
rem Native Windows BGM Player (PowerShell COM Wrapper)
rem Bypasses firewall and antivirus blocks by using native WMP COM object.
rem Supports: PLAY, STOP, VOLUME, PAUSE, RESUME with smooth fades.
rem =============================================================================

set "BGM_CONTROL=%TEMP%\bgm_control.tmp"
set "ACTION=%~1"

if /i "%ACTION%"=="PLAY" goto :Play
if /i "%ACTION%"=="STOP" goto :Stop
if /i "%ACTION%"=="VOLUME" goto :Volume
if /i "%ACTION%"=="PAUSE" goto :Pause
if /i "%ACTION%"=="RESUME" goto :Resume

:Usage
echo =======================================================================
echo Native Windows BGM Player
echo =======================================================================
echo Usage:
echo   %~nx0 PLAY [file_path] [volume] [fadeInMs] [loop]
echo   %~nx0 STOP [fadeOutMs]
echo   %~nx0 VOLUME [targetVolume] [fadeMs]
echo   %~nx0 PAUSE
echo   %~nx0 RESUME
echo.
echo Arguments:
echo   file_path     - Path to the audio file or folder (playlist)
echo   volume        - Target volume (0 to 100, default: 100)
echo   fadeInMs      - Fade-in duration in milliseconds (default: 0)
echo   loop          - Loop playback (1: yes, 0: no, default: 1)
echo   fadeOutMs     - Fade-out duration in milliseconds (default: 0)
echo   targetVolume  - Target volume to transition to (0 to 100)
echo   fadeMs        - Volume transition duration in milliseconds (default: 0)
echo =======================================================================
exit /b 1

:Play
set "FILE_PATH=%~f2"
if not exist "%FILE_PATH%" (
    echo Error: Audio file not found: "%FILE_PATH%"
    exit /b 1
)

set "VOL=%~3"
if "%VOL%"=="" set "VOL=100"
set "FADE_IN=%~4"
if "%FADE_IN%"=="" set "FADE_IN=0"
set "LOOP=%~5"
if "%LOOP%"=="" set "LOOP=1"

rem Clear any existing control file
if exist "%BGM_CONTROL%" del "%BGM_CONTROL%" >nul 2>&1

rem Start background PowerShell process using native WPF MediaPlayer class
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -Command "Add-Type -AssemblyName PresentationCore; $filePath = '%FILE_PATH:'=''%'; $isFolder = Test-Path -Path $filePath -PathType Container; $playlist = New-Object System.Collections.Generic.List[string]; if ($isFolder) { $files = Get-ChildItem -Path $filePath -File | Where-Object { $_.Extension -match '^\.(mp3|wav|wma|aac|m4a)$' } | Select-Object -ExpandProperty FullName; if ($files.Count -gt 0) { $shuffled = $files | Get-Random -Count $files.Count; foreach ($f in $shuffled) { $playlist.Add($f) } } } else { $playlist.Add($filePath) }; if ($playlist.Count -eq 0) { exit }; $player = New-Object System.Windows.Media.MediaPlayer; $playlistIndex = 0; function Play-Current { if ($playlistIndex -lt $playlist.Count) { $mediaPath = $playlist[$playlistIndex]; $uri = New-Object System.Uri($mediaPath); $player.Open($uri); $player.Volume = 0.0; $player.Play() } }; function Fade-Volume($target, $duration) { $start = $player.Volume * 100; if ($duration -le 0) { $player.Volume = $target / 100.0; return }; $steps = 20; $sleep = [int]($duration / $steps); if ($sleep -lt 10) { $sleep = 10; $steps = [int]($duration / 10) }; $diff = $target - $start; for ($i = 1; $i -le $steps; $i++) { $current = $start + ($diff * ($i / $steps)); if ($current -lt 0) { $current = 0 }; if ($current -gt 100) { $current = 100 }; $player.Volume = $current / 100.0; Start-Sleep -Milliseconds $sleep }; $player.Volume = $target / 100.0 }; Play-Current; if (%FADE_IN% -gt 0) { Fade-Volume %VOL% %FADE_IN% } else { $player.Volume = %VOL% / 100.0 }; $controlFile = '%BGM_CONTROL:'=''%'; while ($true) { if ($player.NaturalDuration.HasTimeSpan -and ($player.Position -ge $player.NaturalDuration.TimeSpan)) { if ($isFolder) { $playlistIndex++; if ($playlistIndex -ge $playlist.Count) { if ('%LOOP%' -eq '1') { $playlistIndex = 0; Play-Current; $player.Volume = %VOL% / 100.0 } else { break } } else { Play-Current; $player.Volume = %VOL% / 100.0 } } else { if ('%LOOP%' -eq '1') { $player.Position = [TimeSpan]::Zero; $player.Play() } else { break } } } if (Test-Path $controlFile) { try { $cmdLine = Get-Content $controlFile -ErrorAction SilentlyContinue; if ($cmdLine) { Remove-Item $controlFile -Force -ErrorAction SilentlyContinue; $parts = $cmdLine -split ' '; $act = $parts[0].ToUpper(); if ($act -eq 'STOP') { $dur = 0; if ($parts.Length -gt 1) { [int]::TryParse($parts[1], [ref]$dur) }; Fade-Volume 0 $dur; $player.Stop(); break } elseif ($act -eq 'VOLUME') { $targ = 100; $dur = 0; if ($parts.Length -gt 1) { [int]::TryParse($parts[1], [ref]$targ) }; if ($parts.Length -gt 2) { [int]::TryParse($parts[2], [ref]$dur) }; Fade-Volume $targ $dur } elseif ($act -eq 'PAUSE') { $player.Pause() } elseif ($act -eq 'RESUME') { $player.Play() } } } catch {} } Start-Sleep -Milliseconds 100 }"
exit /b 0
:Stop
setlocal EnableDelayedExpansion
set "FADE_OUT=%~2"
if "%FADE_OUT%"=="" set "FADE_OUT=0"

rem Write the stop command to the control file
echo STOP %FADE_OUT% > "%BGM_CONTROL%"

rem Calculate wait loops (fade duration + 1000ms buffer, divided by 100ms)
set /a "fade_ms = FADE_OUT"
if !fade_ms! LSS 0 set "fade_ms=0"
set /a "loops = (fade_ms + 1000) / 100"
if !loops! LSS 10 set "loops=10"

set "success=0"
for /L %%i in (1,1,!loops!) do (
    if not exist "%BGM_CONTROL%" (
        set "success=1"
        goto :StopCheckDone
    )
    rem Light delay ~100ms
    for /L %%d in (1,1,10) do sc query >nul
)

:StopCheckDone
if "!success!"=="1" (
    endlocal & exit /b 0
) else (
    rem Cleanup file on fail to not block future control calls
    if exist "%BGM_CONTROL%" del "%BGM_CONTROL%" >nul 2>&1
    endlocal & exit /b 1
)

:Volume
set "TARGET_VOL=%~2"
set "FADE_MS=%~3"
if "%FADE_MS%"=="" set "FADE_MS=0"
echo VOLUME %TARGET_VOL% %FADE_MS% > "%BGM_CONTROL%"
exit /b 0

:Pause
echo PAUSE > "%BGM_CONTROL%"
exit /b 0

:Resume
echo RESUME > "%BGM_CONTROL%"
exit /b 0
