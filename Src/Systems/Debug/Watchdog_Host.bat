@echo off & setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
mode con cols=87 lines=25

:: =============================================================================
:: Watchdog_Host.bat
:: Safe processes monitor called asynchronously by Run.bat.
:: Upgraded with custom cyber-security HUD boot animation and framed logging.
:: =============================================================================

rem ===== Args: 1=IPC_DIR(optional) 2=TITLE(optional) =====
if "%~1"=="" (
  if defined runtime_ipc_dir (set "IPC_DIR=%runtime_ipc_dir%") else set "IPC_DIR=%PROJECT_ROOT%\Runtime\IPC"
) else (
  set "IPC_DIR=%~1"
)
for %%A in ("%IPC_DIR%") do set "IPC_DIR=%%~fA"

set "TITLE=%~2"
if not defined TITLE set "TITLE=AstralDivide[v0.1.0]"

:: Confirm IPC directory existence
if not exist "%IPC_DIR%" md "%IPC_DIR%" >nul 2>&1

:: Get ESC character for ANSI graphics
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"

:: Define color codes
set "C_GREEN=!esc![38;5;82m"
set "C_CYAN=!esc![38;5;51m"
set "C_WARN=!esc![38;5;208m"
set "C_TEXT=!esc![38;5;250m"
set "C_BORDER=!esc![38;5;239m"
set "C_RESET=!esc![0m"

cls
:: Draw outer console GUI frame matching Splash (cols=85)
echo !C_BORDER!╔═════════════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo ║                                                                                     ║
)
echo ╚═════════════════════════════════════════════════════════════════════════════════════╝!C_RESET!

:: Header title (Centered for cols=85: Header is 51 chars, (85-51)/2 = 17)
echo !esc![4;18H!C_CYAN!▲ ASTRAL DIVIDE - SECURE WATCHDOG SUBSYSTEM v0.1a ▲!C_RESET!
echo !esc![5;8H!C_BORDER!─────────────────────────────────────────────────────────────────────!C_RESET!

:: Boot sequence text (Typewriter logs)
call :LogLine 7  "Initializing system surveillance..."
call :LogLine 9  "Accessing pseudo IPC directory..."
call :LogLine 10 "  - IPC Location: !IPC_DIR!"
call :LogLine 12 "Resolving host target process..."
call :LogLine 13 "  - Target Host : [!TITLE!]"
call :LogLine 15 "Injecting local process interception hooks..."

:: Sleek radar spinning animation for activation
echo !esc![17;24H!C_WARN!INITIATING WATCHDOG SENSORS ...!C_RESET!
for /L %%i in (1,1,4) do (
    echo !esc![17;60H!C_CYAN!/!C_RESET!  & for /L %%d in (1,1,6) do sc query >nul
    echo !esc![17;60H!C_CYAN!-!C_RESET!  & for /L %%d in (1,1,6) do sc query >nul
    echo !esc![17;60H!C_CYAN!\!C_RESET!  & for /L %%d in (1,1,6) do sc query >nul
    echo !esc![17;60H!C_CYAN!^|!C_RESET!  & for /L %%d in (1,1,6) do sc query >nul
)
echo !esc![17;24H!esc![K!C_GREEN!➔ [ OK ] WATCHDOG SYSTEM INITIATED. (Sensors Online)!C_RESET!

:: Active prompt (Centered for cols=85: Text is 56 chars, (85-56)/2 = 14.5 -> 15)
echo !esc![19;15H!C_CYAN!ACTIVE SURVEILLANCE RUNNING... (Ctrl+C to terminate host)!C_RESET!
echo !esc![20;8H!C_BORDER!─────────────────────────────────────────────────────────────────────!C_RESET!
echo !esc![22;12H!C_TEXT![MONITOR LOG] !C_RESET!

:: Primary surveillance loop
:loop
tasklist /v /fi "IMAGENAME eq cmd.exe" | findstr /I /L /C:"%TITLE%" >nul
if errorlevel 1 (
  echo !esc![22;26H!esc![K!C_WARN![!time!] Target offline: Game process terminated.!C_RESET!
) else (
  echo !esc![22;26H!esc![K!C_GREEN![!time!] Target alive  : Game process healthy.!C_RESET!
)

if exist "%IPC_DIR%\.stop" goto :stop
timeout /t 1 >nul
goto :loop

:stop
echo !esc![22;26H!esc![K!C_CYAN![!time!] Stop signal received. Shutting down WD.!C_RESET!
timeout /t 2 >nul
exit /b 0


:: =============================================================================
:: Subroutine: LogLine (Cool hack-terminal typewriter output)
:: =============================================================================
:LogLine
set "line_y=%~1"
set "text_str=%~2"
set "char_idx=0"

<nul set /p ="!esc![!line_y!;12H!C_TEXT![INFO] "

:TypeLoop
set "char_char=!text_str:~%char_idx%,1!"
if "!char_char!"=="" (
    echo !C_RESET!
    exit /b
)
<nul set /p ="!char_char!"
for /L %%d in (1,1,3) do rem /? >nul
set /a "char_idx+=1"
goto TypeLoop
