@echo off
::------------------------------------------------------------------------------
:: Splash.Progress.bat
:: Handles progress file initialization and reading.
::------------------------------------------------------------------------------

if "%~1"=="init" goto :Init
if "%~1"=="read" goto :Read
exit /b

:Init
if exist "%TEMP%\splash_ui_req.tmp" del "%TEMP%\splash_ui_req.tmp" >nul 2>&1
if exist "%TEMP%\ad_boot_diag_result.env" del "%TEMP%\ad_boot_diag_result.env" >nul 2>&1
if exist "%TEMP%\splash_progress.tmp" del "%TEMP%\splash_progress.tmp" >nul 2>&1
if exist "%TEMP%\remote_session.env" del "%TEMP%\remote_session.env" >nul 2>&1
if exist "%TEMP%\splash_status.tmp" del "%TEMP%\splash_status.tmp" >nul 2>&1

set "PROGRESS_FILE=%TEMP%\splash_progress.tmp"
set "STATUS_FILE=%TEMP%\splash_status.tmp"
set "splash_exit_code=0"
set "splash_stage=Booting"
set "splash_stage_start=0"
set "splash_stage_end=100"
echo 0 > "%PROGRESS_FILE%"
> "%STATUS_FILE%" (
    echo STAGE=Booting
    echo RANGE_START=0
    echo RANGE_END=100
)
exit /b

:Read
if exist "%STATUS_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%STATUS_FILE%") do (
        if /i "%%A"=="RC" set "splash_exit_code=%%B"
        if /i "%%A"=="STAGE" set "splash_stage=%%B"
        if /i "%%A"=="RANGE_START" set "splash_stage_start=%%B"
        if /i "%%A"=="RANGE_END" set "splash_stage_end=%%B"
    )
)
if exist "%PROGRESS_FILE%" (
    for /f "usebackq delims=" %%p in ("%PROGRESS_FILE%") do set "actual_pct=%%p"
)
set /a "pct=!actual_pct!+0"
exit /b
