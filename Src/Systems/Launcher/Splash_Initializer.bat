@echo off
::------------------------------------------------------------------------------
:: Splash_Initializer.bat
:: Runs the system initialization sequences in the background during the splash screen,
:: updating the progress level for the animated loading bar.
::
:: Arguments:
::   %1 - Path to the splash progress tracking file.
::   %2 - PROJECT_ROOT directory path.
::------------------------------------------------------------------------------
setlocal
set "IPC_FILE=%~1"
set "PROJECT_ROOT=%~2"
set "STATUS_FILE=%TEMP%\splash_status.tmp"

:: Set initial progress
echo 10 > "%IPC_FILE%"

:: [1] Return Code System (RCS) Initialization (Prioritized for logging support)
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
    call :ReportFailure 90610001
    exit /b 90610001
)
call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat"
if not "%errorlevel%"=="0" (
    call :ReportFailure 90610002
    exit /b 90610002
)
echo 20 > "%IPC_FILE%"

:: [2] Boot Environment Guard (Integrated check: Multi-launch, PS, permissions, & external tools)
call "%PROJECT_ROOT%\Src\Systems\Launcher\BootEnvironmentGuard.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="0" (
    echo [ERROR] BootEnvironmentGuard validation failed with %errorlevel%
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 30 > "%IPC_FILE%"

:: [2.5] Remote Debugging Approval Block (Halt background progress until remote session is established)
if "%REMOTE_MODE%"=="1" (
    :WaitForRemoteApproval
    if not exist "%TEMP%\remote_session.env" (
        for /l %%d in (1,1,5) do sc query >nul
        goto :WaitForRemoteApproval
    )
)

:: [2.6] Terminal Environment Check (DetectTerminal) - Front-loaded for safety
set "SPLASH_RUNNING=1"
call "%PROJECT_ROOT%\Src\Systems\Environment\DetectTerminal.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 35 > "%IPC_FILE%"

:: [3] Profile Initialization & First Launch Wizard Check (Pre-verified environment guarantees safe wizard display)
if not exist "%PROJECT_ROOT%\Config\user_config.env" (
    :: Create UI request file to signal frontend (Splash.bat) to show the setup wizards
    echo NEED_SETUP >> "%TEMP%\splash_ui_req.tmp"
)

:: Wait until frontend processes the wizard(s) and deletes the request file
if exist "%TEMP%\splash_ui_req.tmp" (
    :WaitForUI
    if exist "%TEMP%\splash_ui_req.tmp" (
        for /l %%d in (1,1,5) do sc query >nul
        goto :WaitForUI
    )
)
echo 38 > "%IPC_FILE%"

:: [4] Profile Initialization (Safe profile load since environment is already verified)
call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileInitializer.bat" "%PROJECT_ROOT%" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 39 > "%IPC_FILE%"

:: [5] Path Setup
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 40 > "%IPC_FILE%"

:: [5.5] Prewarm cmdwiz-friendly SE volume variants during the splash sequence.
call "%PROJECT_ROOT%\Src\Systems\Audio\Prewarm_SE_Variants.bat" FULL "%IPC_FILE%" 41 60 >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)

:: (Terminal Check moved to step 2.6)

:: Final paced fill after heavy initialization to let the splash land gracefully.
for /l %%p in (61,1,100) do (
    echo %%p > "%IPC_FILE%"
    for /l %%d in (1,1,2) do sc query >nul
)

echo 100 > "%IPC_FILE%"
endlocal
exit /b 0

:ReportFailure
> "%STATUS_FILE%" echo RC=%~1
exit /b 0
