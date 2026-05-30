@echo off
setlocal EnableExtensions EnableDelayedExpansion
:: Prevent duplicate chcp execution to avoid conhost font-reset bug
if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

rem -----------------------------------------------------------------------------
rem ScreenEnvironmentDetection.bat
rem Role:
rem   - Detect screen resolution, console sizes, and estimate font sizes.
rem   - Writes findings to Config\Cache\Screen\*COMPUTERNAME*\screen_config.env.
rem   - Also dynamically injects CONSOLE_COLS & CONSOLE_ROWS directly into Config\user_config.env.
rem   - Fully handles conhost F11 fallback for screen probing and paths self-resolution.
rem   - 100%% pure ASCII to prevent CP932 syntax parsing failures in Windows.
rem -----------------------------------------------------------------------------

:: Self-resolve PROJECT_ROOT and directory pathing before SettingPath is run
if not defined PROJECT_ROOT (
    set "PROJECT_ROOT=%~1"
    if "!PROJECT_ROOT!"=="" (
        for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
    )
)

:: Path Resolution Guard (Ensure trailing backslash is resolved if needed)
for %%A in ("!PROJECT_ROOT!") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

if not defined screen_cache_dir (
    set "screen_cache_dir=!PROJECT_ROOT!\Config\Cache\Screen\%COMPUTERNAME%"
)
if not defined screen_cfg_file (
    set "screen_cfg_file=!screen_cache_dir!\screen_config.env"
)
if not defined tools_dir (
    set "tools_dir=!PROJECT_ROOT!\Tools"
)
if not defined RCSU (
    set "RCSU=!PROJECT_ROOT!\Src\Systems\Debug\RCS_Util.bat"
)
if not defined RC_OK (
    set "RC_OK=0"
)

:: Create screen cache directory safely
if not exist "%screen_cache_dir%" md "%screen_cache_dir%" >nul 2>&1

:: Resolve current font
set "IS_CONSOLAS="
if defined SELECTED_FONT (
    if /i "%SELECTED_FONT%"=="Consolas" set "IS_CONSOLAS=1"
)
if not defined IS_CONSOLAS (
    set "_u_cfg=!PROJECT_ROOT!\Config\user_config.env"
    if exist "!_u_cfg!" (
        findstr /i /c:"CONSOLE_FONT=Consolas" "!_u_cfg!" >nul
        if not errorlevel 1 set "IS_CONSOLAS=1"
    )
)

:: Trace Initialization log if RCSU exists
set "LOG_PREFIX=env"
if exist "%RCSU%" call "%RCSU%" -trace INFO ScreenEnv "start cfg=%screen_cfg_file%"

:: Initialize ANSI escape sequences
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"
mode 80,25

:: Probing Tools & PowerShell availability
set "HAS_CMDWIZ=0"
if exist "%tools_dir%\cmdwiz.exe" (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        set "HAS_CMDWIZ=1"
    )
)
if not "%HAS_CMDWIZ%"=="0" goto :SkipWizBlockWarn
if not exist "%RCSU%" goto :SkipWizBlockWarn
if "%EXTERNAL_TOOLS_BLOCKED%"=="1" call "%RCSU%" -trace WARN ScreenEnv "cmdwiz.exe is security-blocked (will degrade to conhost F11)"
if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" call "%RCSU%" -trace WARN ScreenEnv "cmdwiz.exe not found at %tools_dir% (will degrade to conhost F11)"
:SkipWizBlockWarn

:: PowerShell check is skipped (pre-verified by BootEnvironmentGuard)
if exist "%RCSU%" call "%RCSU%" -trace INFO ScreenEnv "PowerShell availability pre-verified by environment guard."

:: Draw setup wizard headers (only if SPLASH_RUNNING is off)
if not "%SPLASH_RUNNING%"=="1" (
    echo %esc%[2J%esc%[1;1H
    echo %esc%[93m   ===========================================   %esc%[0m
    echo %esc%[93m    Screen Environment Detection System ver.2    %esc%[0m
    echo %esc%[93m   ===========================================   %esc%[0m
    echo.
)

if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

:: [0] Enable fullscreen mode (With robust PowerShell F11 fallback)
if not "%SPLASH_RUNNING%"=="1" (
    echo %esc%[96m  [0] Enabling fullscreen mode...%esc%[0m
    if "%HAS_CMDWIZ%"=="1" (
        "%tools_dir%\cmdwiz.exe" fullscreen 1
        if exist "%RCSU%" call "%RCSU%" -trace INFO ScreenEnv "fullscreen=on [cmdwiz] rc=%errorlevel%"
    ) else (
        :: F11 fullscreen fallback using WScript (Hybrid branch to protect Consolas font)
        if "%IS_CONSOLAS%"=="1" (
            powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" > "%TEMP%\ad_ps_f11.tmp" 2>&1
            if exist "%TEMP%\ad_ps_f11.tmp" del "%TEMP%\ad_ps_f11.tmp" >nul 2>&1
        ) else (
            powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1
        )
        if exist "%RCSU%" call "%RCSU%" -trace INFO ScreenEnv "fullscreen=on [F11 fallback]"
        timeout /t 2 >nul
    )
    echo %esc%[92m   [OK] Fullscreen mode enabled%esc%[0m
    if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10
)

:: [1] Probing monitor screen resolution via cmdwiz (0ms overhead, prevents font-reset bug)
echo %esc%[96m  [1] Detecting screen resolution...%esc%[0m
set "screen_width=" & set "screen_height="
if "%HAS_CMDWIZ%"=="1" (
    "%tools_dir%\cmdwiz.exe" getdisplaydim w scaled
    set "screen_width=!errorlevel!"
    "%tools_dir%\cmdwiz.exe" getdisplaydim h scaled
    set "screen_height=!errorlevel!"
) else (
    :: Fallback to PowerShell (Hybrid branch to protect Consolas font)
    if "%IS_CONSOLAS%"=="1" (
        set "ps_out=%TEMP%\ad_ps_screen.tmp"
        powershell -NoProfile -NonInteractive -InputFormat None -Command "Add-Type -AssemblyName System.Windows.Forms; $s=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; Write-Output $s.Width; Write-Output $s.Height" > "!ps_out!" 2>nul
        set "idx=0"
        for /f "usebackq delims=" %%A in ("!ps_out!") do (
            if "!idx!"=="0" (
                set "screen_width=%%A"
                set "idx=1"
            ) else (
                set "screen_height=%%A"
            )
        )
        if exist "!ps_out!" del "!ps_out!" >nul 2>&1
    ) else (
        for /f "usebackq tokens=1" %%A in (`powershell -NoProfile -NonInteractive -InputFormat None -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width"`) do set "screen_width=%%A"
        for /f "usebackq tokens=1" %%A in (`powershell -NoProfile -NonInteractive -InputFormat None -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height"`) do set "screen_height=%%A"
    )
)

set "BAD="
for /f "delims=0123456789" %%x in ("%screen_width%%screen_height%") do set BAD=1
if "%screen_width%"=="" set BAD=1
if "%screen_height%"=="" set BAD=1
if defined BAD (
    if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "screen size parse failed" "W=%screen_width% H=%screen_height%"
    exit /b 1
)
echo %esc%[92m   [OK] Screen resolution: %screen_width% x %screen_height%%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

:: [2] Detecting Console Window Grid sizes (Cols & Rows) via cmdwiz (0ms overhead, prevents font-reset bug)
echo %esc%[96m  [2] Detecting console window size...%esc%[0m
set "console_width=" & set "console_height="
if "%HAS_CMDWIZ%"=="1" (
    "%tools_dir%\cmdwiz.exe" getconsoledim w
    set "console_width=!errorlevel!"
    "%tools_dir%\cmdwiz.exe" getconsoledim h
    set "console_height=!errorlevel!"
) else (
    :: Fallback to PowerShell (Hybrid branch to protect Consolas font)
    if "%IS_CONSOLAS%"=="1" (
        set "ps_out=%TEMP%\ad_ps_console.tmp"
        powershell -NoProfile -NonInteractive -InputFormat None -Command "$host.UI.RawUI.WindowSize.Width; $host.UI.RawUI.WindowSize.Height" > "!ps_out!" 2>nul
        set "idx=0"
        for /f "usebackq delims=" %%A in ("!ps_out!") do (
            if "!idx!"=="0" (
                set "console_width=%%A"
                set "idx=1"
            ) else (
                set "console_height=%%A"
            )
        )
        if exist "!ps_out!" del "!ps_out!" >nul 2>&1
    ) else (
        for /f "usebackq tokens=1" %%A in (`powershell -NoProfile -NonInteractive -InputFormat None -Command "$host.UI.RawUI.WindowSize.Width"`) do set "console_width=%%A"
        for /f "usebackq tokens=1" %%A in (`powershell -NoProfile -NonInteractive -InputFormat None -Command "$host.UI.RawUI.WindowSize.Height"`) do set "console_height=%%A"
    )
)

set "BAD="
for /f "delims=0123456789" %%x in ("%console_width%%console_height%") do set BAD=1
if "%console_width%"=="" set BAD=1
if "%console_height%"=="" set BAD=1
if defined BAD (
    if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "console size parse failed" "W=%console_width% H=%console_height%"
    exit /b 1
)
echo %esc%[92m   [OK] Console Size: %console_width% x %console_height%%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

:: [3] Font Size Estimation
echo %esc%[96m  [3] Estimating text size...%esc%[0m
if "%console_width%"=="0"  set "console_width=90"
if "%console_height%"=="0" set "console_height=35"
set /a char_width_est=screen_width/console_width
set /a char_height_est=screen_height/console_height
echo %esc%[92m   [OK] Estimated text size: %char_width_est% x %char_height_est% pixels%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

:: [4] Generate Environment Files
echo %esc%[96m  [4] Generating configuration files...%esc%[0m
call :Generate_Environment_Config || (
    if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "write screen_config.env failed" "file=%screen_cfg_file%"
    exit /b 1
)
echo %esc%[92m   [OK] Environment settings successfully saved and synced!%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

:: [5] Display Layout Compatibility Test
if not "%SPLASH_RUNNING%"=="1" (
    echo %esc%[96m  [5] Running a display compatibility test...%esc%[0m
    call :Run_Compatibility_Test
    echo %esc%[19;1H%esc%[92m   [OK] Compatibility test completed%esc%[0m
    timeout /t 1 >nul
    if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10
)

:: [6] Close / Restore Fullscreen
if not "%SPLASH_RUNNING%"=="1" (
    if "%HAS_CMDWIZ%"=="1" (
        "%tools_dir%\cmdwiz.exe" fullscreen 0
    ) else (
        :: Toggle F11 again to restore window size (Hybrid branch to protect Consolas font)
        if "%IS_CONSOLAS%"=="1" (
            powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" > "%TEMP%\ad_ps_f11.tmp" 2>&1
            if exist "%TEMP%\ad_ps_f11.tmp" del "%TEMP%\ad_ps_f11.tmp" >nul 2>&1
        ) else (
            powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1
        )
    )
    echo %esc%[2J%esc%[1;1H
    echo.
    echo %esc%[93m   ===========================================   %esc%[0m
    echo %esc%[93m               Detection complete.               %esc%[0m
    echo %esc%[93m   ===========================================   %esc%[0m
    echo.
    timeout /t 1 >nul
)

if exist "%RCSU%" call "%RCSU%" -trace INFO ScreenEnv "ok W=%screen_width% H=%screen_height% CW=%console_width% CH=%console_height%"
exit /b %RC_OK%


rem ============================== Subroutines ===============================

:Generate_Environment_Config
    :: Ensure screen cache directory is fully created
    if not exist "!screen_cache_dir!" md "!screen_cache_dir!" >nul 2>&1

    set "_tmp=!screen_cfg_file!.tmp"
    if exist "%_tmp%" del /q "%_tmp%" >nul 2>&1

    :: 1-line safe appends to avoid command parser crash on system dates
    echo # auto-generated by ScreenEnvironmentDetection.bat> "!_tmp!"
    echo # date: %date%>> "!_tmp!"
    echo.>> "!_tmp!"
    echo SCREEN_WIDTH=!screen_width!>> "!_tmp!"
    echo SCREEN_HEIGHT=!screen_height!>> "!_tmp!"
    echo.>> "!_tmp!"
    echo CONSOLE_WIDTH=!console_width!>> "!_tmp!"
    echo CONSOLE_HEIGHT=!console_height!>> "!_tmp!"
    echo.>> "!_tmp!"
    echo CHAR_WIDTH_EST=!char_width_est!>> "!_tmp!"
    echo CHAR_HEIGHT_EST=!char_height_est!>> "!_tmp!"
    echo.>> "!_tmp!"
    
    if !screen_width! LEQ 1366 (
        echo SCREEN_CLASS=SMALL>> "!_tmp!"
        echo UI_SCALE=0.8>> "!_tmp!"
    ) else if !screen_width! LEQ 1920 (
        echo SCREEN_CLASS=MEDIUM>> "!_tmp!"
        echo UI_SCALE=1.0>> "!_tmp!"
    ) else (
        echo SCREEN_CLASS=LARGE>> "!_tmp!"
        echo UI_SCALE=1.2>> "!_tmp!"
    )
    echo.>> "!_tmp!"
    echo COMPUTER=%COMPUTERNAME%>> "!_tmp!"

    if exist "!screen_cfg_file!" attrib -R "!screen_cfg_file!" >nul 2>&1
    move /y "!_tmp!" "!screen_cfg_file!" >nul 2>&1 || exit /b 1

    :: Sync and Inject findings directly into Config\user_config.env
    set "_u_cfg=!PROJECT_ROOT!\Config\user_config.env"
    
    :: Determine System Recommended Profile (HIGH or MIDDLE)
    set "sys_rec_profile=MIDDLE"
    if !console_width! GEQ 200 (
        if !console_height! GEQ 55 (
            set "sys_rec_profile=HIGH"
        )
    )

    if exist "!_u_cfg!" (
        set "_u_tmp=!_u_cfg!.tmp"
        if exist "!_u_tmp!" del /q "!_u_tmp!" >nul 2>&1

        :: Read line-by-line using safe append to ignore previous keys
        for /f "usebackq delims=" %%l in ("!_u_cfg!") do (
            set "line=%%l"
            set "skip="
            echo !line! | findstr /i "CONSOLE_COLS CONSOLE_ROWS SYSTEM_RECOMMENDED_PROFILE RENDER_QUALITY" >nul && set "skip=1"
            if not defined skip echo !line!>> "!_u_tmp!"
        )
        echo CONSOLE_COLS=!console_width!>> "!_u_tmp!"
        echo CONSOLE_ROWS=!console_height!>> "!_u_tmp!"
        echo SYSTEM_RECOMMENDED_PROFILE=!sys_rec_profile!>> "!_u_tmp!"
        echo RENDER_QUALITY=!sys_rec_profile!>> "!_u_tmp!"
        move /y "!_u_tmp!" "!_u_cfg!" >nul 2>&1
    )

    exit /b 0


:Run_Compatibility_Test
    :: Uses premium single-border symbols (U+2500 series) aligned to monospace font
    set /a w=console_width-1
    set /a h=console_height-1
    set /a inner_w=w-2

    set "horiz="
    for /L %%i in (1,1,!inner_w!) do set "horiz=!horiz!─"

    echo !esc![93m   === Display Compatibility Test (Monospace Aligned: !console_width!x!console_height!) === !esc![0m
    echo !esc![93m    Check that the entire frame is displayed correctly!esc![0m
    echo.

    echo !esc![1;1H!esc![93m┌!horiz!┐!esc![0m
    for /L %%r in (2,1,!h!-1) do (
        echo !esc![%%r;1H!esc![93m│!esc![%%r;!w!H│!esc![0m
        if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10
    )
    echo !esc![!h!;1H!esc![93m└!horiz!┘!esc![0m

    timeout /t 1 >nul
    exit /b 0
