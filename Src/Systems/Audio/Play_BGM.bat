@echo off
chcp 65001 >nul
::------------------------------------------------------------------------------
:: Play_BGM.bat (Wrapper for BgmPlayer)
:: Interfaces with the high-performance BgmPlayer system.
:: Maintained for perfect compatibility with all existing game scripts.
::
:: Arguments
::   %1  Path   - Full path to the audio file to play. Ignored when Mode is stop.
::   %2  Mode   - play | repeat | stop
::   %3  Volume - Optional volume level (0-100). Defaults to 50.
::------------------------------------------------------------------------------
setlocal
set "FILE_PATH=%~1"
set "MODE=%~2"
set "VOLUME=%~3"
if "%VOLUME%"=="" set "VOLUME=%BGM_VOLUME%"
if "%VOLUME%"=="" set "VOLUME=50"

set "BGM_PLAYER=%~dp0BgmPlayer.bat"

if /i "%MODE%"=="stop" (
    :: Stop with a premium 1.5-second fade-out for a smooth transition!
    call "%BGM_PLAYER%" STOP 1500
) else if /i "%MODE%"=="repeat" (
    :: Play and loop, featuring a smooth 500ms fade-in
    call "%BGM_PLAYER%" PLAY "%FILE_PATH%" %VOLUME% 500 1
) else (
    :: Play once, featuring a smooth 500ms fade-in
    call "%BGM_PLAYER%" PLAY "%FILE_PATH%" %VOLUME% 500 0
)

endlocal
exit /b 0
