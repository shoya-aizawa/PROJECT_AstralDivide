@echo off 
setlocal EnableExtensions EnableDelayedExpansion
::------------------------------------------------------------------------------
:: Splash.bat
:: HedgeHogSoft Splash Screen Sequence with Native System Loading Synchronization.
::
:: Arguments:
::   %1 - PROJECT_ROOT directory path.
::------------------------------------------------------------------------------

set "PROJECT_ROOT=%~1"
if "%PROJECT_ROOT%"=="" (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)

:: Load user config if exists to apply saved font
set "USER_CONFIG_FILE=%PROJECT_ROOT%\Config\user_config.env"
if exist "%USER_CONFIG_FILE%" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%USER_CONFIG_FILE%") do (
        set "%%A=%%B"
    )
)

:: Apply user-configured font automatically at startup if it exists and not blocked
if defined CONSOLE_FONT (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        if exist "%PROJECT_ROOT%\Tools\cmdwiz.exe" (
            call "%PROJECT_ROOT%\Tools\cmdwiz.exe" setfont "%PROJECT_ROOT%\Tools\%CONSOLE_FONT%.fnt" >nul 2>&1
        )
    )
)

:: Get ESC character
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"

:: Hide the blinking cursor for a cleaner look
echo !esc![?25l

:: Call Context to load constants
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Context.bat"

:: Start test BGM playback using native PresentationCore player
if exist "%SPLASH_BGM%" (
    call "%BGM_PLAYER%" PLAY "%SPLASH_BGM%" 100 0 1
)

:: Set standard window size to ensure layout is centered
mode con cols=80 lines=25
echo !esc![2J

:: Draw initial static border GUI frame
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Initialize Progress System and temporary variables
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Progress.bat" init

:: Background Task & IPC (Inter-Process Communication)
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
    exit /b 90610001
)
call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat"
if not "%errorlevel%"=="0" (
    exit /b 90610002
)

set "SPLASH_RUNNING=1"

:: Start the background initialization process
start "" /b cmd /c call "%INITIALIZER%" "!PROGRESS_FILE!" "%PROJECT_ROOT%"

set "pct=0"
set "actual_pct=0"
set "frame=0"
set "state=0"
set "keep_frame=0"
set "cmdwiz_path=%PROJECT_ROOT%\Tools\cmdwiz.exe"

:ProgressLoop
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.UpdateState.bat"

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.RemoteState.bat"
if "!errorlevel!"=="1" exit /b 1
if "!errorlevel!"=="2" exit /b 2

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.WizardRouter.bat"

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Progress.bat" read
if not "!splash_exit_code!"=="0" goto LoopExit

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.RenderFrame.bat"

:: FLUSH FRAME BUFFER ATOMICALLY (Swaps buffer in a single write call!)
set "FRAME_RENDER=!FRAME_RENDER!!esc![24;80H!esc![?25l"
<nul set /p ="!FRAME_RENDER!"

:: Precise delay to smooth out rendering and make the animation fully enjoyable!
for /L %%d in (1,1,11) do rem /? >nul 2>&1

:: State-specific Loop Control
if !state! LSS 2 (
    goto ProgressLoop
) else (
    if exist "!cmdwiz_path!" (
        "!cmdwiz_path!" getch noWait >nul 2>&1
        if errorlevel 1 goto LoopExit
    ) else (
        pause >nul
        goto LoopExit
    )
    goto ProgressLoop
)
:LoopExit
:: Cleanup progress file
if exist "!PROGRESS_FILE!" del "!PROGRESS_FILE!" >nul 2>&1
if exist "!STATUS_FILE!" del "!STATUS_FILE!" >nul 2>&1

:: 1. BGM STOP (Fade out and stop the BGM with robust retry logic)
if exist "%SPLASH_BGM%" (
    set "bgm_stopped=0"
    for /L %%r in (1,1,3) do (
        if "!bgm_stopped!"=="0" (
            call "%BGM_PLAYER%" STOP 1500
            if !ERRORLEVEL! == 0 (
                set "bgm_stopped=1"
            ) else (
                :: Wait a moment before retrying
                for /L %%d in (1,1,10) do sc query >nul
                if %%r == 3 (
                    :: Last resort: force close the background Powershell player to prevent dangling audio
                    taskkill /f /im powershell.exe >nul 2>&1
                    set "bgm_stopped=1"
                )
            )
        )
    )
)

:: 2. Maximize and Animation (Trigger Fullscreen and the immersive cosmic warp transition!)
:: [Bypassed] Managed by Main.bat instead to allow parent window to serve as WatchDog.

:: 3. End (Restore cursor and clear screen to transition to game)
echo !esc![?25h!esc![2J!esc![1;1H
endlocal & exit /b %splash_exit_code%
