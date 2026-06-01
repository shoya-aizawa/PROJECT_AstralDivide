@echo off
:: ==============================================================================
:: BootEnvironmentGuard.bat
:: Core security and permissions verification subsystem for AstralDivide.
:: Performs a robust check of multi-instance lock, PowerShell policy,
:: disk write permissions, and firewall-blocked external executable engines.
:: Logs all step transitions utilizing RCSU.
:: Line endings must be CRLF, Encoding must be UTF-8.
:: ==============================================================================
setlocal EnableDelayedExpansion

set "PROJECT_ROOT=%~1"
if "%PROJECT_ROOT%"=="" (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)

:: Path Resolution Guard
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
set "LAUNCH_GUARD=%PROJECT_ROOT%\Src\Systems\Launcher\LaunchGuard.bat"
set "TOOL_CHECKER=%PROJECT_ROOT%\Src\Systems\Launcher\ToolChecker.ps1"
set "TOOLS_DIR=%PROJECT_ROOT%\Tools"
set "USER_CONFIG=%PROJECT_ROOT%\Config\user_config.env"

:: Load user config to detect current font selection
set "IS_CONSOLAS="
if defined SELECTED_FONT (
    if /i "%SELECTED_FONT%"=="Consolas" set "IS_CONSOLAS=1"
)
if not defined IS_CONSOLAS (
    if exist "%USER_CONFIG%" (
        findstr /i /c:"CONSOLE_FONT=Consolas" "%USER_CONFIG%" >nul
        if not errorlevel 1 set "IS_CONSOLAS=1"
    )
)

if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Starting Environment Guard validation."

:: -----------------------------------------------------------------------------
:: Step 1: Multi-instance Check (LaunchGuard.bat)
:: -----------------------------------------------------------------------------
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Step 1: Checking multi-instance guard lock."
if not exist "%LAUNCH_GUARD%" goto :NoLaunchGuard

call "%LAUNCH_GUARD%"
set "guard_rc=%errorlevel%"
if not "%guard_rc%"=="0" goto :ErrLaunchGuard
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "LaunchGuard check passed successfully."
goto :Step1End

:NoLaunchGuard
if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "LaunchGuard.bat not found. Skipping multi-instance lock check."

:Step1End

:: -----------------------------------------------------------------------------
:: Step 2: PowerShell Availability & Policy Check
:: -----------------------------------------------------------------------------
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Step 2: Testing PowerShell engine availability."
if "%IS_CONSOLAS%"=="1" (
    powershell -NoProfile -NonInteractive -InputFormat None -Command "$PSVersionTable.PSVersion" > "%TEMP%\ad_ps_ver.tmp" 2>&1
    if exist "%TEMP%\ad_ps_ver.tmp" del "%TEMP%\ad_ps_ver.tmp" >nul 2>&1
) else (
    powershell -NoProfile -NonInteractive -InputFormat None -Command "$PSVersionTable.PSVersion" >nul 2>&1
)
if errorlevel 1 goto :ErrPowerShell
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "PowerShell verification completed successfully."

:: -----------------------------------------------------------------------------
:: Step 3: Disk Write Permissions Check (Config & Saves)
:: -----------------------------------------------------------------------------
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Step 3: Checking directory write permissions."

:: 3a. Verify Config folder write access
set "CONFIG_TEST=%PROJECT_ROOT%\Config\.write_test.tmp"
echo test > "%CONFIG_TEST%" 2>nul
if not exist "%CONFIG_TEST%" goto :ErrConfigWrite
del "%CONFIG_TEST%" >nul 2>&1

:: 3b. Verify Saves folder write access
if not exist "%PROJECT_ROOT%\Saves" md "%PROJECT_ROOT%\Saves" >nul 2>&1
set "SAVES_TEST=%PROJECT_ROOT%\Saves\.write_test.tmp"
echo test > "%SAVES_TEST%" 2>nul
if not exist "%SAVES_TEST%" goto :ErrSavesWrite
del "%SAVES_TEST%" >nul 2>&1

if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Directory write permissions verified successfully."

:: -----------------------------------------------------------------------------
:: Step 4: External CLI Executables Check (Timeout-monitored ToolChecker)
:: -----------------------------------------------------------------------------
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "Step 4: Scanning external CLI modules for firewall or SmartScreen blocks."

set "TEMP_OUT=%TEMP%\ad_boot_diag.tmp"
if exist "%TEMP_OUT%" del "%TEMP_OUT%" >nul 2>&1

set "ANY_FAILED=0"

if not exist "%TOOL_CHECKER%" goto :NoToolChecker

powershell -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass -File "%TOOL_CHECKER%" "%TOOLS_DIR%" > "%TEMP_OUT%" 2>nul
if not exist "%TEMP_OUT%" goto :ErrDiagnostics

:: Loop ONLY to capture variables to avoid nested parenthesis call bugs
for /f "usebackq tokens=*" %%L in ("%TEMP_OUT%") do (
    set "LINE=%%L"
    for /f "tokens=1,2,3,4 delims=|" %%A in ("!LINE!") do (
        set "T_NAME=%%A"
        set "T_STATUS=%%B"
        set "T_TIME=%%C"
        set "T_MSG=%%D"
        
        set "STATUS_!T_NAME!=!T_STATUS!"
        set "TIME_!T_NAME!=!T_TIME!"
        set "MSG_!T_NAME!=!T_MSG!"
        
        if not "!T_STATUS!"=="OK" set "ANY_FAILED=1"
    )
)
del "%TEMP_OUT%" >nul 2>&1

:: Safely write logs OUTSIDE of the parenthesis blocks (Fully flattened to prevent parsing bugs!)
set "ST=!STATUS_cmdgfx.exe!" & set "TI=!TIME_cmdgfx.exe!"
if "!ST!"=="OK" (
    if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "External tool cmdgfx.exe - functional - !TI! ms."
) else (
    if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "External tool cmdgfx.exe - BLOCKED/UNUSABLE - Status !ST!."
)

set "ST=!STATUS_cmdwiz.exe!" & set "TI=!TIME_cmdwiz.exe!"
if "!ST!"=="OK" (
    if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "External tool cmdwiz.exe - functional - !TI! ms."
) else (
    if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "External tool cmdwiz.exe - BLOCKED/UNUSABLE - Status !ST!."
)

set "ST=!STATUS_cmdbkg.exe!" & set "TI=!TIME_cmdbkg.exe!"
if "!ST!"=="OK" (
    if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "External tool cmdbkg.exe - functional - !TI! ms."
) else (
    if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "External tool cmdbkg.exe - BLOCKED/UNUSABLE - Status !ST!."
)

set "ST=!STATUS_Insertbmp.exe!" & set "TI=!TIME_Insertbmp.exe!"
if "!ST!"=="OK" (
    if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "External tool Insertbmp.exe - functional - !TI! ms."
) else (
    if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "External tool Insertbmp.exe - BLOCKED/UNUSABLE - Status !ST!."
)
goto :Step4End

:NoToolChecker
set "ANY_FAILED=1"
if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "ToolChecker.ps1 not found. Skipping external tool diagnostics."
goto :Step4End

:ErrDiagnostics
set "ANY_FAILED=1"
if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "No response from ToolChecker.ps1. Diagnostics failed."

:Step4End

:: -----------------------------------------------------------------------------
:: Step 5: Save Results & Configure System Fallbacks
:: -----------------------------------------------------------------------------
set "NEED_FALLBACK=0"
if "!ANY_FAILED!"=="1" (
    if defined RCSU call "%RCSU%" -trace WARN BootEnvGuard "Active block or missing executable detected. Writing fallback flags to user_config.env."
    set "NEED_FALLBACK=1"
) else (
    if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "All external tools verified successfully."
)

if "%NEED_FALLBACK%"=="1" goto :DoFallback
call :UpdateConfigSuccess
goto :DoGuardEnd

:DoFallback
call :UpdateConfigFallback

:DoGuardEnd
if defined RCSU call "%RCSU%" -trace INFO BootEnvGuard "BootEnvironmentGuard check complete."
endlocal & exit /b 0


:: =============================================================================
:: EXITS & ERRORS (Handled outside parenthesis blocks)
:: =============================================================================

:ErrLaunchGuard
if defined RCSU call "%RCSU%" -trace ERR BootEnvGuard "FATAL: LaunchGuard verification failed (RC=%guard_rc%)."
endlocal & exit /b %guard_rc%

:ErrPowerShell
if defined RCSU (
    call "%RCSU%" -trace ERR BootEnvGuard "FATAL: PowerShell execution failed or is blocked by system policies."
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_COMPAT% 021 "PowerShell unavailable or execution blocked"
)
endlocal & exit /b %errorlevel%

:ErrConfigWrite
if defined RCSU (
    call "%RCSU%" -trace ERR BootEnvGuard "FATAL: Write access denied in Config folder."
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "Config directory is not writable"
)
endlocal & exit /b %errorlevel%

:ErrSavesWrite
if defined RCSU (
    call "%RCSU%" -trace ERR BootEnvGuard "FATAL: Write access denied in Saves folder."
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "Saves directory is not writable"
)
endlocal & exit /b %errorlevel%


:: =============================================================================
:: SUBROUTINES
:: =============================================================================

:UpdateConfigFallback
rem Safely write EXTERNAL_TOOLS_BLOCKED=1 and force STANDARD quality profiles to Config\user_config.env
if "%IS_CONSOLAS%"=="1" (
    powershell -NoProfile -Command "$cfg = '%USER_CONFIG%'.Replace('\', '/'); if (Test-Path $cfg) { $content = Get-Content $cfg; if ($content -match 'EXTERNAL_TOOLS_BLOCKED') { $content = $content -replace 'EXTERNAL_TOOLS_BLOCKED=.*', 'EXTERNAL_TOOLS_BLOCKED=1' } else { $content += 'EXTERNAL_TOOLS_BLOCKED=1' }; if ($content -match 'RENDER_QUALITY') { $content = $content -replace 'RENDER_QUALITY=.*', 'RENDER_QUALITY=MIDDLE' }; if ($content -match 'SYSTEM_RECOMMENDED_PROFILE') { $content = $content -replace 'SYSTEM_RECOMMENDED_PROFILE=.*', 'SYSTEM_RECOMMENDED_PROFILE=MIDDLE' }; Set-Content -Path $cfg -Value $content -Encoding UTF8 }" > "%TEMP%\ad_ps_cfg.tmp" 2>&1
    if exist "%TEMP%\ad_ps_cfg.tmp" del "%TEMP%\ad_ps_cfg.tmp" >nul 2>&1
) else (
    powershell -NoProfile -Command "$cfg = '%USER_CONFIG%'.Replace('\', '/'); if (Test-Path $cfg) { $content = Get-Content $cfg; if ($content -match 'EXTERNAL_TOOLS_BLOCKED') { $content = $content -replace 'EXTERNAL_TOOLS_BLOCKED=.*', 'EXTERNAL_TOOLS_BLOCKED=1' } else { $content += 'EXTERNAL_TOOLS_BLOCKED=1' }; if ($content -match 'RENDER_QUALITY') { $content = $content -replace 'RENDER_QUALITY=.*', 'RENDER_QUALITY=MIDDLE' }; if ($content -match 'SYSTEM_RECOMMENDED_PROFILE') { $content = $content -replace 'SYSTEM_RECOMMENDED_PROFILE=.*', 'SYSTEM_RECOMMENDED_PROFILE=MIDDLE' }; Set-Content -Path $cfg -Value $content -Encoding UTF8 }" >nul 2>&1
)
echo EXTERNAL_TOOLS_BLOCKED=1 > "%TEMP%\ad_boot_diag_result.env"
exit /b 0

:UpdateConfigSuccess
rem Safely clear block flags in user_config.env
if "%IS_CONSOLAS%"=="1" (
    powershell -NoProfile -Command "$cfg = '%USER_CONFIG%'.Replace('\', '/'); if (Test-Path $cfg) { $content = Get-Content $cfg; if ($content -match 'EXTERNAL_TOOLS_BLOCKED') { $content = $content -replace 'EXTERNAL_TOOLS_BLOCKED=.*', 'EXTERNAL_TOOLS_BLOCKED=0' } else { $content += 'EXTERNAL_TOOLS_BLOCKED=0' }; Set-Content -Path $cfg -Value $content -Encoding UTF8 }" > "%TEMP%\ad_ps_cfg.tmp" 2>&1
    if exist "%TEMP%\ad_ps_cfg.tmp" del "%TEMP%\ad_ps_cfg.tmp" >nul 2>&1
) else (
    powershell -NoProfile -Command "$cfg = '%USER_CONFIG%'.Replace('\', '/'); if (Test-Path $cfg) { $content = Get-Content $cfg; if ($content -match 'EXTERNAL_TOOLS_BLOCKED') { $content = $content -replace 'EXTERNAL_TOOLS_BLOCKED=.*', 'EXTERNAL_TOOLS_BLOCKED=0' } else { $content += 'EXTERNAL_TOOLS_BLOCKED=0' }; Set-Content -Path $cfg -Value $content -Encoding UTF8 }" >nul 2>&1
)
echo EXTERNAL_TOOLS_BLOCKED=0 > "%TEMP%\ad_boot_diag_result.env"
exit /b 0
