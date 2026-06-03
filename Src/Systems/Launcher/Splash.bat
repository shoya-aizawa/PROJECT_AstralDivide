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
set "splash_stage=Booting"
set "splash_stage_start=0"
set "splash_stage_end=100"
set "last_title_pct="
set "last_title_stage="
set "title_tick=0"
call :GetTimeCs splash_start_cs
set "stage_start_cs=%splash_start_cs%"
call :Update_Title

:ProgressLoop
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.UpdateState.bat"

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.RemoteState.bat"
if "!errorlevel!"=="1" exit /b 1
if "!errorlevel!"=="2" exit /b 2

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.WizardRouter.bat"

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Progress.bat" read
if not "!splash_exit_code!"=="0" goto LoopExit
call :Update_Title

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.RenderFrame.bat"

:: FLUSH FRAME BUFFER ATOMICALLY (Swaps buffer in a single write call!)
set "FRAME_RENDER=!FRAME_RENDER!!esc![24;80H!esc![?25l"
<nul set /p ="!FRAME_RENDER!"

:: Precise delay to smooth out rendering and make the animation fully enjoyable!
for /L %%d in (1,1,6) do rem /? >nul 2>&1

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

:Update_Title
set /a title_tick+=1
if defined last_title_stage if not "!last_title_stage!"=="!splash_stage!" call :GetTimeCs stage_start_cs
if defined last_title_pct if "!last_title_pct!"=="!pct!" if defined last_title_stage if "!last_title_stage!"=="!splash_stage!" if !title_tick! lss 10 exit /b 0
set "last_title_pct=!pct!"
set "last_title_stage=!splash_stage!"
set "title_tick=0"

if /i "!splash_stage!"=="Setup Wizard" (
    title Astral Divide - Loading... [!splash_stage!] waiting for user input...
    exit /b 0
)
if !pct! lss 10 (
    title Astral Divide - Loading... [!splash_stage!] calculating...
    exit /b 0
)
if !pct! geq 100 (
    title Astral Divide - Loading... [!splash_stage!] almost done...
    exit /b 0
)

call :GetTimeCs splash_now_cs
set /a "elapsed_cs=splash_now_cs-stage_start_cs"
if !elapsed_cs! lss 0 set /a "elapsed_cs+=8640000"
set /a "elapsed_secs=(elapsed_cs + 50) / 100"
if !elapsed_secs! lss 1 set /a "elapsed_secs=1"
set /a "stage_span=splash_stage_end-splash_stage_start"
set /a "stage_done=pct-splash_stage_start"
if !stage_span! leq 0 set /a "stage_span=100"
if !stage_done! leq 0 (
    title Astral Divide - Loading... [!splash_stage!] calculating...
    exit /b 0
)
set /a "stage_left=splash_stage_end-pct"
if !stage_left! lss 0 set /a "stage_left=0"
set /a "eta_secs=(elapsed_secs * stage_left) / stage_done"
if !eta_secs! lss 1 set /a "eta_secs=1"
title Astral Divide - Loading... [!splash_stage!] maybe !eta_secs! sec left...
exit /b 0

:GetTimeCs
setlocal EnableDelayedExpansion
set "t=!time: =0!"
set /a "hh=1!t:~0,2! - 100"
set /a "mm=1!t:~3,2! - 100"
set /a "ss=1!t:~6,2! - 100"
set /a "cc=1!t:~9,2! - 100"
set /a "cs=((hh*3600)+(mm*60)+ss)*100+cc"
endlocal & set "%~1=%cs%"
exit /b 0
