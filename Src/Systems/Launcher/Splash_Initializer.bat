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

:: Set initial progress
echo 10 > "%IPC_FILE%"

:: [1] Return Code System (RCS) Initialization (Prioritized for logging support)
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
    exit /b 90610001
)
call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat"
if not "%errorlevel%"=="0" (
    exit /b 90610002
)
echo 20 > "%IPC_FILE%"

:: [2] Boot Environment Guard (Integrated check: Multi-launch, PS, permissions, & external tools)
call "%PROJECT_ROOT%\Src\Systems\Launcher\BootEnvironmentGuard.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="0" (
    echo [ERROR] BootEnvironmentGuard validation failed with %errorlevel%
    exit /b %errorlevel%
)
echo 40 > "%IPC_FILE%"

:: [3] Profile Initialization & First Launch Wizard Check (Pre-verified environment guarantees safe wizard display)
if not exist "%PROJECT_ROOT%\Config\user_config.env" (
    :: Create UI request file to signal frontend (Splash.bat) to show the setup wizards
    echo NEED_SETUP > "%TEMP%\splash_ui_req.tmp"
    
    :: Wait until frontend processes the wizard and deletes the request file
    :WaitForUI
    if exist "%TEMP%\splash_ui_req.tmp" (
        for /l %%d in (1,1,5) do sc query >nul
        goto :WaitForUI
    )
)
echo 55 > "%IPC_FILE%"

set "SPLASH_RUNNING=1"

:: [4] Profile Initialization (Safe profile load since environment is already verified)
call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileInitializer.bat" "%PROJECT_ROOT%" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    exit /b %errorlevel%
)
echo 70 > "%IPC_FILE%"

:: [5] Path Setup
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    exit /b %errorlevel%
)
echo 85 > "%IPC_FILE%"

:: [6] Terminal Environment Check (DetectTerminal)
call "%PROJECT_ROOT%\Src\Systems\Environment\DetectTerminal.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    exit /b %errorlevel%
)
echo 95 > "%IPC_FILE%"

:: Final delay loop to ensure smooth visual bar completion
for /l %%d in (1,1,10) do sc query >nul

echo 100 > "%IPC_FILE%"
endlocal
exit /b 0
