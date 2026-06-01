@echo off
chcp 65001 >nul
setlocal

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=START"

set "SE_SERVER_SCRIPT=%~dp0SePlayer.ps1"
set "SE_QUEUE=%TEMP%\astral_divide_se_queue.txt"
set "SE_PID_FILE=%TEMP%\astral_divide_se_pid.txt"

if /i "%ACTION%"=="START" goto :Start
if /i "%ACTION%"=="PLAY" goto :Play
if /i "%ACTION%"=="STOP" goto :Stop
exit /b 1

:Start
if not exist "%SE_SERVER_SCRIPT%" exit /b 2

set "SE_PID="
set "SE_RUNNING=0"
if exist "%SE_PID_FILE%" (
    set /p "SE_PID=" < "%SE_PID_FILE%"
)
if defined SE_PID (
    powershell.exe -NoProfile -NonInteractive -Command "if (Get-Process -Id %SE_PID% -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
    if not errorlevel 1 set "SE_RUNNING=1"
)
if "%SE_RUNNING%"=="1" exit /b 0

break > "%SE_QUEUE%"
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%SE_SERVER_SCRIPT%" -QueueFile "%SE_QUEUE%" -PidFile "%SE_PID_FILE%" >nul 2>&1

for /l %%i in (1,1,40) do (
    if exist "%SE_PID_FILE%" exit /b 0
    timeout /t 1 /nobreak >nul
)
exit /b 3

:Play
set "TARGET_VOLUME=%~2"
set "TARGET_SOUND=%~3"
if "%TARGET_VOLUME%"=="" exit /b 4
if "%TARGET_SOUND%"=="" exit /b 5

call "%~f0" START >nul 2>&1
if errorlevel 1 exit /b 6

>> "%SE_QUEUE%" echo %TARGET_VOLUME%^|%TARGET_SOUND%
exit /b 0

:Stop
if exist "%SE_QUEUE%" >> "%SE_QUEUE%" echo SHUTDOWN
exit /b 0
