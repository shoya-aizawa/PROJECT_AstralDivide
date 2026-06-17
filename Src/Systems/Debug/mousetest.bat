@echo off
chcp 65001 >nul
setlocal EnableExtensions

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)

set "LOG_DIR=%PROJECT_ROOT%\Logs"
set "CRASH_LOG=%LOG_DIR%\MouseProbeCrash.log"
set "PROBE_LOG=%LOG_DIR%\Chapter01_RoomExplore_MouseProbe.log"
set "PROBE_FILE=%PROJECT_ROOT%\Src\Systems\Debug\Chapter01_RoomExplore_MouseProbe.bat"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

set "MOUSE_PROBE_LOG=0"
set "PROBE_DEBUG_PANEL=0"

>> "%CRASH_LOG%" echo ============================================================
>> "%CRASH_LOG%" echo [%date% %time%] Mouse probe start
>> "%CRASH_LOG%" echo PROJECT_ROOT=%PROJECT_ROOT%
>> "%CRASH_LOG%" echo PROBE_FILE=%PROBE_FILE%
>> "%CRASH_LOG%" echo PROBE_LOG=%PROBE_LOG%
>> "%CRASH_LOG%" echo STDERR_ONLY=1

call "%PROBE_FILE%" 2>> "%CRASH_LOG%"
set "EXIT_CODE=%errorlevel%"

>> "%CRASH_LOG%" echo [%date% %time%] Mouse probe end exit_code=%EXIT_CODE%
>> "%CRASH_LOG%" echo.

echo Crash log: "%CRASH_LOG%"
echo Probe log: "%PROBE_LOG%"
pause >nul
exit /b %EXIT_CODE%
