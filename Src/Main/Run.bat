::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

@chcp 65001 >nul
@echo off
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")
@prompt $G
@mode 90,35

rem================================================= Main Flow =================================================

set "REMOTE_GAS_URL=https://script.google.com/macros/s/AKfycbwIOTx9BM2IwcIoHPyKJN529AkBUk7Kbadwxb4HzxYrHMUrV_2PX2BpbaPVhLuWphhK/exec"
set "REMOTE_ADMIN_KEY=admin"


if /i "%~1"=="-mode" if /i "%~2"=="remotewatch" (
    if not defined REMOTE_GAS_URL (
        echo [E2001] REMOTE_GAS_URL not set.
        pause >nul
        exit /b 2001
    )
    if not defined REMOTE_ADMIN_KEY (
        echo [E2002] REMOTE_ADMIN_KEY not set.
        pause >nul
        exit /b 2002
    )
    echo Starting remote log watcher [ADMIN]...
    powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Src\Systems\Debug\LogWatcher.ps1" -GasUrl "%REMOTE_GAS_URL%" -AdminKey "%REMOTE_ADMIN_KEY%"
    goto :eof
)






:: [0] Mode Interpretation (Default=RUN) (*RUN*/DEBUG/INTERCEPT)
set "BUILD_PROFILE=release" & set "INTERCEPT_MODE=0"
if /i "%~1"=="-mode" if /i "%~2"=="debug"     set "BUILD_PROFILE=dev"
if /i "%~1"=="-mode" if /i "%~2"=="intercept" set "BUILD_PROFILE=dev" & set "INTERCEPT_MODE=1"
if /i not "%BUILD_PROFILE%"=="dev" (@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof)

:: [1] LaunchGuard
call "%~dp0..\Systems\Launcher\LaunchGuard.bat"
set "LG_RC=%errorlevel%"
if %LG_RC% neq 0 (
	rem --- LG already printed user-facing message ---
    rem --- Run.bat only performs controlled exit for upper logic ---
    pause >nul
    exit 900000%LG_RC%
)

:: [2] RCS Bootstrap
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
	rem RCS_Util.bat not found : ERR/Systems/IO/case001
	set "RCS_MISSING_TAG=RCS_Util.bat"
	set "RCS_FALLBACK=90610001"
	goto :FailRun
)
call "%RCSU%" -trace INFO "%~n0" "RCS bootstrap start"

call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat" || (
	rem RCS_Const.bat not found or failed to load : ERR/Systems/IO/case002
	set "RCS_MISSING_TAG=RCS_Const.bat"
	set "RCS_FALLBACK=90610002"
	goto :FailRun
)
call "%RCSU%" -build %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000
call "%RCSU%" -trace INFO "%~n0" "RCS ready [rc=%errorlevel%]"




:: [DEV] Remote Debug Tail (optional; if REMOTE_DEBUG=1)
for /f %%d in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd')"') do set "date_tag=%%d"

rem if文内で変数を展開するための応急処置
set "logfile=%PROJECT_ROOT%\Config\Logs\AstralDivide_Session_%date_tag%.log"


if /i "%~1"=="-mode" if /i "%~2"=="remote" (
    set "logfile=%PROJECT_ROOT%\Config\Logs\AstralDivide_Session_%date_tag%.log"
    start "" powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Src\Systems\Debug\LogTailToGAS.ps1" -LogPath "%logfile%" -GasUrl "%REMOTE_GAS_URL%"
    call "%RCSU%" -trace INFO Run "remote tail started logfile=%logfile%"
	echo 同期処理のため停止中... Enterキーで復帰
	pause >nul
)


:: [3] First-Run Initialization Steps
call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileInitializer.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCSU%" -trace INFO "%~n0" "bootstrap ok"

:: [4] Path Setup
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCSU%" -trace INFO Run "paths ready root=%root_dir%"

:: [5] Resource Migration (Logs/IPC)
if exist "%PROJECT_ROOT%\Logs" (
	if not exist "%config_logs_dir%" md "%config_logs_dir%" >nul 2>&1
	move /y "%PROJECT_ROOT%\Logs\*" "%config_logs_dir%" >nul 2>&1
	dir /b "%PROJECT_ROOT%\Logs" | findstr /r /c:"^." >nul || rd "%PROJECT_ROOT%\Logs"
	call "%RCSU%" -trace INFO Run "migrated Logs -> %config_logs_dir%"
)
if exist "%PROJECT_ROOT%\Runtime\ipc" (
	if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
	move /y "%PROJECT_ROOT%\Runtime\ipc\*" "%runtime_ipc_dir%" >nul 2>&1
	call "%RCSU%" -trace INFO Run "migrated Runtime\ipc -> %runtime_ipc_dir%"
)

:: [6] Environment Detection
call "%src_env_dir%\ScreenEnvironmentDetection.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCSU%" -trace INFO Run "screen env ok"

:: [7] Security Verification
rem TODO call "%PROJECT_ROOT%\Src\Systems\Security\VerifySignatures.bat"

:: [8] Initiate Main.bat
start /d "%src_main_dir%" Main.bat 65001 "AstralDivide[v0.1.0]"
set launch_time=%time%
call "%RCSU%" -trace INFO Run "main launched time=%launch_time%"

:: [9] Watchdog Host Launch
if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
( if "%INTERCEPT_MODE%"=="1" (echo INTERCEPT) else (echo NORMAL) ) > "%runtime_ipc_dir%\.mode"

rem Pass IPC_DIR to WD as an argument
call "%src_debug_dir%\Watchdog_Host.bat" "%runtime_ipc_dir%" "AstralDivide[v0.1.0]"


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
call "%RCSU%" -pretty %errorlevel%
call "%RCSU%" -trace ERR Run "first-run failed rc=%errorlevel%"
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
pause >nul
exit /b
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
