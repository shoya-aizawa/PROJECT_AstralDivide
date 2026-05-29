@echo off
setlocal
:: ==============================================================================
:: Time.bat
:: Returns the current Unix Epoch time in milliseconds via PowerShell.
:: Usage: call Lib\Time.bat <ReturnVariableName>
:: ==============================================================================
set "VAR_NAME=%~1"
if "%VAR_NAME%"=="" set "VAR_NAME=CURRENT_TIME_MS"

:: Run PowerShell and capture the output
for /f "usebackq tokens=*" %%A in (`powershell -NoLogo -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()"`) do (
    set "UNIX_TIME=%%A"
)

:: Return to the caller scope
endlocal & set "%VAR_NAME%=%UNIX_TIME%"
exit /b 0
