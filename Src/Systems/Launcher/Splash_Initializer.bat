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
set "CURRENT_STAGE=Booting"

:: Set initial progress
echo 10 > "%IPC_FILE%"

:: [1] Return Code System (RCS) Initialization (Prioritized for logging support)
call :WriteStage "RCS Init" 10 20
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
call :WriteStage "Boot Guard" 20 30
call "%PROJECT_ROOT%\Src\Systems\Launcher\BootEnvironmentGuard.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="0" (
    echo [ERROR] BootEnvironmentGuard validation failed with %errorlevel%
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 30 > "%IPC_FILE%"

:: [2.5] Remote approval is handled by the splash frontend at 40%.
:: Do not block the initializer here, otherwise the frontend never reaches
:: the point where the remote login wizard can create remote_session.env.

:: [2.6] Terminal Environment Check (DetectTerminal) - Front-loaded for safety
call :WriteStage "Terminal Check" 30 35
set "SPLASH_RUNNING=1"
call "%PROJECT_ROOT%\Src\Systems\Environment\DetectTerminal.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 35 > "%IPC_FILE%"

:: [3] Profile Initialization & First Launch Wizard Check (Pre-verified environment guarantees safe wizard display)
call :WriteStage "Setup Wizard" 35 38
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
call :WriteStage "Profile Init" 38 39
call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileInitializer.bat" "%PROJECT_ROOT%" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 39 > "%IPC_FILE%"

:: [5] Path Setup
call :WriteStage "Setting Paths" 39 40
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat" >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)
echo 40 > "%IPC_FILE%"

:: [5.5] Prewarm cmdwiz-friendly SE volume variants during the splash sequence.
call :WriteStage "Prewarm SE" 41 60
call "%PROJECT_ROOT%\Src\Systems\Audio\Prewarm_SE_Variants.bat" FULL "%IPC_FILE%" 41 60 >nul 2>&1
if not "%errorlevel%"=="0" if not "%errorlevel%"=="%RC_OK%" (
    call :ReportFailure %errorlevel%
    exit /b %errorlevel%
)

:: (Terminal Check moved to step 2.6)

:: Final paced fill after heavy initialization to let the splash land gracefully.
call :WriteStage "Finalizing" 61 100
for /l %%p in (61,1,100) do (
    echo %%p > "%IPC_FILE%"
    for /l %%d in (1,1,2) do sc query >nul
)

echo 100 > "%IPC_FILE%"
endlocal
exit /b 0

:WriteStage
set "CURRENT_STAGE=%~1"
set "CURRENT_RANGE_START=%~2"
set "CURRENT_RANGE_END=%~3"
> "%STATUS_FILE%" echo STAGE=%CURRENT_STAGE%
>> "%STATUS_FILE%" echo RANGE_START=%CURRENT_RANGE_START%
>> "%STATUS_FILE%" echo RANGE_END=%CURRENT_RANGE_END%
exit /b 0

:ReportFailure
> "%STATUS_FILE%" (
    echo STAGE=%CURRENT_STAGE%
    echo RANGE_START=%CURRENT_RANGE_START%
    echo RANGE_END=%CURRENT_RANGE_END%
    echo RC=%~1
)
exit /b 0
