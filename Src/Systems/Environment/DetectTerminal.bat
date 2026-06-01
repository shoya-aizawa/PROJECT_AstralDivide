@echo off
setlocal EnableExtensions
chcp 65001 >nul

rem -----------------------------------------------------------------------------
rem DetectTerminal.bat
rem Role:
rem   - Detects if running under Windows Terminal (WT) and recommends conhost.exe.
rem   - Coexists perfectly with "start cmd" debugging window detachment by 
rem     directly targeting the active OS Console window class name via Win32 APIs 
rem     (GetConsoleWindow + GetClassName).
rem   - Windows Terminal (ConPTY) allocates "PseudoConsoleWindow" for active cmd sessions.
rem   - Legacy Command Prompt allocates "ConsoleWindowClass".
rem   - Any exception fails-safe to conhost (exit 0) to avoid false positives.
rem   - Logs to RCSU and handles return codes.
rem RC:
rem   FLOW/SYS/OTHER/000 : 1-06-90-000 : OK
rem -----------------------------------------------------------------------------

if defined RCSU (
    call "%RCSU%" -trace INFO DetectTerminal "Starting terminal environment check."
)

:: Load user config to detect current font selection
set "DT_PROJECT_ROOT=%PROJECT_ROOT%"
if "%DT_PROJECT_ROOT%"=="" (
    for %%A in ("%~dp0..\..\..") do set "DT_PROJECT_ROOT=%%~fA"
)
for %%A in ("%DT_PROJECT_ROOT%") do set "DT_PROJECT_ROOT=%%~fA"
set "IS_CONSOLAS="
if defined SELECTED_FONT (
    if /i "%SELECTED_FONT%"=="Consolas" set "IS_CONSOLAS=1"
)
if not defined IS_CONSOLAS (
    if exist "%DT_PROJECT_ROOT%\Config\user_config.env" (
        findstr /i /c:"CONSOLE_FONT=Consolas" "%DT_PROJECT_ROOT%\Config\user_config.env" >nul
        if not errorlevel 1 set "IS_CONSOLAS=1"
    )
)

:: Win32 API call via PowerShell inside a robust try-catch block.
:: Returns exit 1 on PseudoConsoleWindow (Windows Terminal).
:: Returns exit 0 on ConsoleWindowClass (conhost) or any exceptions/headless environments.
set "IS_WT=0"
if "%IS_CONSOLAS%"=="1" goto IsConsolasCheck
goto IsNormalCheck

:IsConsolasCheck
set "PS_SCRIPT=%TEMP%\ad_ps_wt.ps1"

echo try {> "%PS_SCRIPT%"
echo     $c = '[DllImport("kernel32.dll")]public static extern IntPtr GetConsoleWindow^(^);[DllImport("user32.dll")]public static extern int GetClassName^(IntPtr h, System.Text.StringBuilder sb, int m^);'>> "%PS_SCRIPT%"
echo     $t = Add-Type -MemberDefinition $c -Name W -Namespace N -PassThru>> "%PS_SCRIPT%"
echo     $h = $t::GetConsoleWindow^(^)>> "%PS_SCRIPT%"
echo     if ^($h -eq [IntPtr]::Zero^) { exit 0 }>> "%PS_SCRIPT%"
echo     $sb = New-Object System.Text.StringBuilder^(256^)>> "%PS_SCRIPT%"
echo     $null = $t::GetClassName^($h, $sb, 256^)>> "%PS_SCRIPT%"
echo     $n = $sb.ToString^(^)>> "%PS_SCRIPT%"
echo     if ^($n -eq 'PseudoConsoleWindow'^) { exit 1 } else { exit 0 }>> "%PS_SCRIPT%"
echo } catch { exit 0 }>> "%PS_SCRIPT%"

start /min /wait powershell.exe -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass -File "%PS_SCRIPT%" > "%TEMP%\ad_ps_wt.tmp" 2>nul
set "ps_rc=%errorlevel%"

if "%ps_rc%"=="1" (
    set "IS_WT=1"
) else (
    set "IS_WT=0"
)

if exist "%TEMP%\ad_ps_wt.tmp" del "%TEMP%\ad_ps_wt.tmp" >nul 2>&1
if exist "%PS_SCRIPT%" del "%PS_SCRIPT%" >nul 2>&1
goto WTCheckDone

:IsNormalCheck
powershell -NoProfile -NonInteractive -InputFormat None -Command "try { $c = '[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern int GetClassName(IntPtr h, System.Text.StringBuilder sb, int m);'; $t = Add-Type -MemberDefinition $c -Name W -Namespace N -PassThru; $h = $t::GetConsoleWindow(); if ($h -eq [IntPtr]::Zero) { exit 0 }; $sb = New-Object System.Text.StringBuilder(256); $null = $t::GetClassName($h, $sb, 256); $n = $sb.ToString(); if ($n -eq 'PseudoConsoleWindow') { exit 1 } else { exit 0 } } catch { exit 0 }" >nul 2>&1
set "ps_rc=%errorlevel%"

if "%ps_rc%"=="1" set "IS_WT=1"
goto WTCheckDone

:WTCheckDone

:: If not Windows Terminal
if "%IS_WT%"=="0" (
    if defined RCSU (
        call "%RCSU%" -trace INFO DetectTerminal "Environment is confirmed as conhost.exe {Recommended}"
        call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000
    )
    exit /b %RC_OK%
)

:: If Windows Terminal is detected
if defined RCSU (
    call "%RCSU%" -trace WARN DetectTerminal "Windows Terminal execution environment detected via PseudoConsoleWindow class."
)

if "%SPLASH_RUNNING%"=="1" (
    >> "%TEMP%\splash_ui_req.tmp" echo NEED_WT_WARN
    if defined RCSU call "%RCSU%" -trace WARN DetectTerminal "Queued WT warning for splash frontend."
    exit /b %RC_OK%
)

:: Get ANSI escape sequence for styling
if not defined esc (
    for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"
)

echo %esc%[93m=====================================================================%esc%[0m
echo %esc%[93m  [WARNING] Windows Terminal {wt.exe} Detected%esc%[0m
echo %esc%[93m=====================================================================%esc%[0m
echo.
echo   This game (Astral Divide) is designed and optimized for
echo   %esc%[92mconhost.exe {Standard Windows Command Prompt}%esc%[0m.
echo.
echo   Running under Windows Terminal may cause:
echo     1. Window size adjustments (mode command) being ignored.
echo     2. Text UI and layout rendering misalignments.
echo     3. Misbehavior in external console utility tools.
echo.
echo   %esc%[93m-----------------------------------------------------------------%esc%[0m
echo   %esc%[92m  [Recommendation] Close this window and relaunch via conhost.exe.%esc%[0m
echo     *To force launch under Windows Terminal, press any key to continue...
echo   %esc%[93m=====================================================================%esc%[0m
echo.

pause >nul

if defined RCSU (
    call "%RCSU%" -trace INFO DetectTerminal "User acknowledged the WT warning and proceeded."
    call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000
)

exit /b 0
