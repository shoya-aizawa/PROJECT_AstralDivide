::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

@chcp 65001 >nul
@echo off
@mode 90,35
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")

:: Check if debug mode is requested in arguments to avoid opening a new window
@set "IS_DEBUG_MODE=0"
@echo "%*" | findstr /i "\-mode debug" >nul && set "IS_DEBUG_MODE=1"

@if not "%IS_DEBUG_MODE%"=="1" if not "%~2"=="remoteadmin" (@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof)
@title Astral Divide - Booting.
set "self_name=%~n0"
rem================================================= Main Flow =================================================

set "REMOTE_GAS_URL=https://script.google.com/macros/s/AKfycbwIOTx9BM2IwcIoHPyKJN529AkBUk7Kbadwxb4HzxYrHMUrV_2PX2BpbaPVhLuWphhK/exec"
set "REMOTE_ADMIN_KEY=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"

:: Load secret override configs if they exist in user_config.env
if not defined PROJECT_ROOT (
    for %%I in ("%~dp0..\..") do set "PROJECT_ROOT=%%~fI"
)
if exist "%PROJECT_ROOT%\Config\user_config.env" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%PROJECT_ROOT%\Config\user_config.env") do (
        if "%%A"=="REMOTE_GAS_URL" set "REMOTE_GAS_URL=%%B"
        if "%%A"=="REMOTE_ADMIN_KEY" set "REMOTE_ADMIN_KEY=%%B"
    )
)

:: [0.1] Launch Token Guard (Direct execution prevention)
set "LAUNCH_GUARD=%PROJECT_ROOT%\Src\Systems\Launcher\LaunchGuard.bat"
if exist "%LAUNCH_GUARD%" (
    call "%LAUNCH_GUARD%"
)
if exist "%LAUNCH_GUARD%" if not "%errorlevel%"=="0" (
    exit /b %errorlevel%
)







:: --- Developer Option: Force First Launch Setup ---
set "FORCE_FIRST_LAUNCH=0"
for %%A in (%*) do (
    if /i "%%~A"=="-first" set "FORCE_FIRST_LAUNCH=1"
    if /i "%%~A"=="--first" set "FORCE_FIRST_LAUNCH=1"
)
if "%FORCE_FIRST_LAUNCH%"=="1" goto :Dev_ForceFirstLaunch
goto :Dev_ForceFirstLaunch_End

:Dev_ForceFirstLaunch
    echo %esc%[93m[DEV] Force First Launch option detected.%esc%[0m
    if not defined PROJECT_ROOT (
        for %%I in ("%~dp0..\..") do set "PROJECT_ROOT=%%~fI"
    )
    for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"
    if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

    set "_dev_cfg=%PROJECT_ROOT%\Config\user_config.env"
    if exist "%_dev_cfg%" (
        echo %esc%[90mClearing user_config.env ...%esc%[0m %esc%[92m[ OK ]%esc%[0m
        del /q "%_dev_cfg%" >nul 2>&1
    )
    set "_dev_cache=%PROJECT_ROOT%\Config\Cache\Screen"
    if exist "%_dev_cache%" (
        echo %esc%[90mClearing screen cache ...%esc%[0m %esc%[92m[ OK ]%esc%[0m
        rd /s /q "%_dev_cache%" >nul 2>&1
    )
    set "_dev_se_cache=%PROJECT_ROOT%\Config\Cache\SEVariants"
    if exist "%_dev_se_cache%" (
        echo %esc%[90mClearing prewarmed SE variants ...%esc%[0m %esc%[92m[ OK ]%esc%[0m
        rd /s /q "%_dev_se_cache%" >nul 2>&1
    )
    set "_dev_logs=%PROJECT_ROOT%\Config\Logs"
    if exist "%_dev_logs%" (
        echo %esc%[90mClearing log files ...%esc%[0m %esc%[92m[ OK ]%esc%[0m
        for %%F in ("%_dev_logs%\*.log") do (
            type nul > "%%F" 2>nul
        )
    )
    timeout /t 1 >nul
    goto :Dev_ForceFirstLaunch_End

:Dev_ForceFirstLaunch_End

:: [0] Mode Interpretation (Default=RUN) (*RUN*/DEBUG/INTERCEPT/REMOTE/REMOTEADMIN)
:: Parse startup options robustly regardless of argument order
set "BUILD_PROFILE=release"
set "INTERCEPT_MODE=0"
set "REMOTE_MODE=0"
set "REMOTE_ADMIN_MODE=0"
set "FORCE_RENDER_QUALITY="

:ParseArgsLoop
if "%~1"=="" goto :ParseArgsEnd
if /i "%~1"=="-mode" (
    if /i "%~2"=="debug"     set "BUILD_PROFILE=dev"
    if /i "%~2"=="intercept" set "BUILD_PROFILE=dev"& set "INTERCEPT_MODE=1"
    if /i "%~2"=="remote" (
        for /f %%d in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd')"') do (
            set "date_tag=%%d"
            set "logfile=%PROJECT_ROOT%\Config\Logs\AstralDivide_Session_%%d.log"
        )
        set "REMOTE_MODE=1"
    )
    if /i "%~2"=="remoteadmin" set "REMOTE_ADMIN_MODE=1"
    shift
)
if /i "%~1"=="-quality" (
    if /i "%~2"=="high" set "FORCE_RENDER_QUALITY=HIGH"
    if /i "%~2"=="middle" set "FORCE_RENDER_QUALITY=MIDDLE"
    if /i "%~2"=="low" set "FORCE_RENDER_QUALITY=LOW"
    shift
)
if /i "%~1"=="--quality" (
    if /i "%~2"=="high" set "FORCE_RENDER_QUALITY=HIGH"
    if /i "%~2"=="middle" set "FORCE_RENDER_QUALITY=MIDDLE"
    if /i "%~2"=="low" set "FORCE_RENDER_QUALITY=LOW"
    shift
)
shift
goto :ParseArgsLoop
:ParseArgsEnd

if "%REMOTE_ADMIN_MODE%"=="1" (
    if not defined REMOTE_GAS_URL (
        echo [E2001] REMOTE_GAS_URL not set.
        pause >nul
        goto :eof
    )
    if not defined REMOTE_ADMIN_KEY (
        echo [E2002] REMOTE_ADMIN_KEY not set.
        pause >nul
        goto :eof
    )
    powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Src\Systems\Debug\LogWatcher.ps1" -GasUrl "%REMOTE_GAS_URL%" -AdminKey "%REMOTE_ADMIN_KEY%"
    goto :eof
)



:: [1] Splash Animation & Background Initialization (Synchronous execution)
@title Astral Divide - Loading...
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="0" (
    set "RCS_FALLBACK=%errorlevel%"
    if "%RCS_FALLBACK%" LSS "10000000" set /a "RCS_FALLBACK=90640100 + %errorlevel%"
    set "RCS_MISSING_TAG=Splash/Initializer"
    goto :FailRun
)

:: Load remote debugging session token if exists to parent shell scope
if exist "%TEMP%\remote_session.env" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%TEMP%\remote_session.env") do (
        set "%%A=%%B"
    )
    del "%TEMP%\remote_session.env" >nul 2>&1
)

:: Splash frontend has completed. All profile and setups are written to disk.
:: Now we natively load RCS and Environment Variables inside the parent scope to protect game systems!
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
	set "RCS_MISSING_TAG=RCS_Util.bat"
	set "RCS_FALLBACK=90610001"
	goto :FailRun
)
call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat" >nul 2>&1 || (
	set "RCS_MISSING_TAG=RCS_Const.bat"
	set "RCS_FALLBACK=90610002"
	goto :FailRun
)
call "%RCSU%" -build %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000 >nul 2>&1

:: =============================================================================
:: [RCS & Configuration Parent Scope Load]
:: All profile setups & directory calculations have been 100% completed 
:: and sync'd with the loading bar during the Splash.
:: Here we purely & silently load the generated configuration to the parent shell.
:: =============================================================================
set "USER_CONFIG=%PROJECT_ROOT%\Config\user_config.env"
if exist "%USER_CONFIG%" (
    call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%USER_CONFIG%" SILENT >nul 2>&1
)

:: Export finalized directory path variables to the parent shell (using SILENT to avoid duplicated logs)
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat" SILENT >nul 2>&1
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun

:: Transition directly to the Main Game Core (RCS variables are fully active!)
goto :GoMain

:: [2] Terminal Environment Check (Bypassed - already checked in Splash)
:: [3] Environment Detection (Bypassed - already checked in Splash)
:: [4] Security Verification
rem TODO call "%root_dir%\Src\Systems\Security\VerifySignatures.bat"

:: [8] Initiate Main.bat
:GoMain
rem start "AstralDivide[v0.1.1]" /max cmd /c %src_main_dir%\Main.bat 65001 "AstralDivide[v0.1.1]"
if "%IS_DEBUG_MODE%"=="1" (
    :: Run Main.bat directly using CALL in debug mode to keep execution in the same terminal
    pushd "%src_main_dir%"
    call Main.bat 65001 "AstralDivide[v0.1.1]"
    popd
) else (
    start /d "%src_main_dir%" Main.bat 65001 "AstralDivide[v0.1.1]"
)
set launch_time=%time%
call "%RCSU%" -trace INFO "%self_name%" "main launched time=%launch_time%"
if defined FORCE_RENDER_QUALITY call "%RCSU%" -trace INFO "%self_name%" "forced render quality=%FORCE_RENDER_QUALITY%"

:: Launch remote debugging log streamer if active
if "%REMOTE_MODE%"=="1" (
    if defined REMOTE_TOKEN (
        if not "%REMOTE_STREAMER_STARTED%"=="1" (
            :: Ensure the log directory and log file exist before tail starts to avoid file-not-found exceptions
            for %%D in ("%logfile%") do (
                if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
            )
            if not exist "%logfile%" type nul > "%logfile%" 2>nul
            
            start "AstralDivide - Log Streamer" /b powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Src\Systems\Debug\LogTailToGAS.ps1" -LogPath "%logfile%" -GasUrl "%REMOTE_GAS_URL%" -ClientName "%USERNAME%@%COMPUTERNAME%" -SessionToken "%REMOTE_TOKEN%" > "%PROJECT_ROOT%\Config\Logs\ad_streamer.log" 2>&1
            call "%RCSU%" -trace INFO "%self_name%" "started background remote log streamer with token"
        ) else (
            if defined RCSU call "%RCSU%" -trace INFO "%self_name%" "Remote log streamer was already started during splash screen."
        )
    ) else (
        if defined RCSU call "%RCSU%" -trace WARN "%self_name%" "REMOTE_TOKEN is not defined. Skipping streamer launch."
    )
) else (
    if defined RCSU call "%RCSU%" -trace INFO "%self_name%" "Remote debugging mode is not active."
)

:: [9] Watchdog Host Launch
if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
( if "%INTERCEPT_MODE%"=="1" (echo INTERCEPT) else (echo NORMAL) ) > "%runtime_ipc_dir%\.mode"

rem Pass IPC_DIR to WD as an argument (bypassed in debug mode to avoid nested wait/blocking)
if not "%IS_DEBUG_MODE%"=="1" (
    call "%src_debug_dir%\Watchdog_Host.bat" "%runtime_ipc_dir%" "AstralDivide[v0.1.1]"
)


:: [A] Cleanup Temporary Files
rem TODO del /q "%runtime_ipc_dir%\*.tmp" 2>nul
rem TODO exit /b %RC%

:: [B] Normal Exit
goto :ExitRun

:: [C] Not Determined Yet

:: [D] Not Determined Yet

:: [E] Not Determined Yet

:: [F] Not Determined Yet

:: [1A] Extra Sections

:: [1B] Extra Sections

:: ...


rem=============================================== Main Flow end ===============================================

rem//============================ Developer console (optional; keep off in release) ==========================//
set /p command="" & %command%
if "%command%"=="" (goto :eof)
rem//=========================================================================================================//

rem!========================================== Error & Exit sections ==========================================!
:: Initialization failure
:FailFirstRun
rem 直前のRCを人間可読表示
set "FAIL_RC=%errorlevel%"
call "%RCSU%" -pretty %FAIL_RC%
call "%RCSU%" -trace ERR Run "first-run failed rc=%FAIL_RC%"
echo %esc%[31m[E1300]%esc%[0m 初期設定に失敗しました。保存先や権限をご確認ください。
pause >nul
goto :ExitRun

:: Fatal launcher damage
:FailRun
if /i "%~1"=="-mode" if /i "%~2"=="debug" (
	rem Debug mode: Show detailed error info in console
	echo %esc%[31m[FATAL E1301]%esc%[0m Launcher is not working properly. Please try reinstalling.
	echo Error code: %RCS_FALLBACK%
	echo Missing component: %RCS_MISSING_TAG%
	if defined RCSU (
		call "%RCSU%" -trace ERR [Run] "FATAL startup rc=%RCS_FALLBACK%"
		call "%RCSU%" -trace ERR [Run] "missing component=%RCS_MISSING_TAG%"
	) else (
		echo [FATAL] missing component=%RCS_MISSING_TAG% (code=%RCS_FALLBACK%) >> "%PROJECT_ROOT%\boot_fatal.log"
	)
	pause >nul
	goto :ExitRun
) else (
	rem Normal mode: Show minimal error info
	echo %esc%[31m[FATAL E1301]%esc%[0m Launcher is not working properly. Please try reinstalling.
	echo Error code: %RCS_FALLBACK%
	pause >nul
	goto :ExitRun
)

:: Common exit(Utility)
:ExitRun
call "%RCSU%" -trace INFO Run "exit"
if "%IS_DEBUG_MODE%"=="1" (
    :: In debug mode, use exit /b to avoid closing the VSCode terminal session
    exit /b 0
)
pause >nul
exit
rem!===========================================================================================================!

rem?================================================= Helpers =================================================?
:: Legacy code has been removed.
:: Reason for removal: Each module is now self-contained using RCS.
rem?===========================================================================================================?

rem ****************************Share: Naming Conventions for This Project****************************

rem *Command: Use lowercase consistently (command)
rem - Commands are used frequently, so using lowercase consistently reduces visual noise and improves readability.
rem - The Windows Command Prompt is case-insensitive, so using lowercase consistently works without issues.

rem *Variable name: Snake case (snake_case)
rem - Long names are easier to read and are easily distinguished from batch special characters (% and !), improving readability.
rem - As an exception, using uppercase consistently for debug variables makes them easier to distinguish from other variables.

rem *File name: Pascal case (PascalCase)
rem - Consistent filename naming makes it easier to organize the entire project.
rem - The file name is structurally easy to understand even if the operating system environment (e.g., Windows) does not distinguish between uppercase and lowercase letters.

rem *Folder name: PascalCase
rem - Visual consistency makes management easier.
rem - It is consistent with the file name to maintain consistency throughout the project.
rem - Folder names help organize the hierarchical structure, making them more convenient when containing multiple files or functions.

rem *************************************Shared: Return Code List*************************************

rem **Standard Batch File Exit Codes**
rem errlvl  /     mean
rem 0       /     Successful completion
rem 1       /     General error
rem 2       /     The specified file was not found
rem 3       /     Path not found
rem 4       /     The system cannot perform the requested operation
rem 5       /     Access denied
rem 6       /     Invalid handle
rem 10      /     The environment is not configured correctly
rem 87      /     Invalid parameter
rem 123     /     An invalid name was specified
rem 9009    /     Command not found

rem **************************************************************************************************
