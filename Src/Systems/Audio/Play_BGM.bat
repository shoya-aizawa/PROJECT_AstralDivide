::------------------------------------------------------------------------------
:: Play_BGM.bat
:: Launches Play_BGM.ps1 to play, loop, or stop a .wav file in the background.
::
:: Arguments
::   %1  Path   - Full path to the .wav file to play. Ignored when Mode is stop.
::   %2  Mode   - play | repeat | stop
::   %3  Volume - Optional volume level (0-100). Defaults to 50.
::
:: Examples
::   call "%src_BGM_dir%\Play_BGM.bat" "%assets_sounds_starfall_dir%\StarFallHill.wav" play 75
::   call "%src_BGM_dir%\Play_BGM.bat" "%assets_sounds_starfall_dir%\StarFallHill.wav" repeat 50
::   call "%src_BGM_dir%\Play_BGM.bat" "" stop
::------------------------------------------------------------------------------
@echo off
setlocal
if /I "%2"=="stop" (
   start /min powershell -Sta -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File "%~dp0Play_BGM.ps1" -Mode stop
) else (
   start /min powershell -Sta -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File "%~dp0Play_BGM.ps1" -Path "%~1" -Mode %2 -Volume %3
)
endlocal
exit /b 0