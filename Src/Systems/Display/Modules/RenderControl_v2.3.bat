@echo off
chcp 65001 >nul

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

setlocal EnableDelayedExpansion
set "line=%~1"
if "%SCENARIO_SKIP_ACTIVE%"=="1" set "RENDERCONTROL_FAST_PREVIEW=1"
call :MainWrapper "!line!"
set "RC=%errorlevel%"
endlocal & (
    set "SCENARIO_SKIP_ACTIVE=%SCENARIO_SKIP_ACTIVE%"
    set "RENDER_BG_PATH=%RENDER_BG_PATH%"
    set "RENDER_BG_T=%RENDER_BG_T%"
    exit /b %RC%
)

:MainWrapper
set "line=%~1"
set "PAUSE_MANAGER=%src_display_dir%\PauseManager.bat"
if not defined RENDER_BG_T set "RENDER_BG_T=33"

echo !line! | findstr /c:"{id:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1* delims=}" %%a in ("!line!") do (
        set "line=%%b"
    )
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{bg_t:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1* delims=}" %%a in ("!line:*{bg_t:=!") do (
        set "bg_t_spec=%%a"
        set "line=%%b"
    )
    set "RENDER_BG_T=!bg_t_spec!"
    if not defined RENDER_BG_T set "RENDER_BG_T=33"
    if defined RENDER_BG_PATH if exist "!RENDER_BG_PATH!" %tools_dir%\cmdbkg.exe "!RENDER_BG_PATH!" /b /t !RENDER_BG_T! >nul 2>&1
    if defined line call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{bg:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1* delims=}" %%a in ("!line:*{bg:=!") do (
        set "bg_spec=%%a"
        set "line=%%b"
    )
    set "bg_path=!bg_spec!"
    if not exist "!bg_path!" set "bg_path=%assets_images_dir%\!bg_spec!"
    if exist "!bg_path!" (
        set "RENDER_BG_PATH=!bg_path!"
        if not defined RENDER_BG_T set "RENDER_BG_T=33"
        %tools_dir%\cmdbkg.exe "!bg_path!" /b /t !RENDER_BG_T! >nul 2>&1
    )
    if defined line call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{pos:" >nul
if !errorlevel! == 0 (
    for /f "tokens=2,3 delims=:{}" %%a in ("!line!") do (
        set "Y=%%a"
        set "X=%%b"
    )
    set "CURRENT_CURSOR_Y=!Y!"
    set "CURRENT_CURSOR_X=!X!"
    %tools_dir%\cmdwiz.exe print "%ESC%[!Y!;!X!H"
    set "line=!line:*}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

if "!line:~0,7!"=="{delay:" (
    for /f "tokens=2 delims=:{}" %%a in ("!line!") do (
        if not defined RENDERCONTROL_FAST_PREVIEW call :WaitDelayOrAdvance "%%a"
        set "line=!line:*}=!"
    )
    if defined line call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

if "!line!"=="{pause}" (
    if not defined RENDERCONTROL_FAST_PREVIEW call :WaitForAdvanceKey
    exit /b 0
)

echo !line! | findstr /b "{pause}" >nul
if !errorlevel! == 0 (
    if not defined RENDERCONTROL_FAST_PREVIEW call :WaitForAdvanceKey
    set "line=!line:*{pause}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

if "!line:~0,12!"=="{pause:auto:" (
    for /f "tokens=3 delims=:{}" %%a in ("!line!") do (
        set "pause_auto_ms=%%a"
    )
    if not defined RENDERCONTROL_FAST_PREVIEW call :WaitAutoOrAdvance "!pause_auto_ms!"
    set "line=!line:*}=!"
    if defined line call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

if "!line!"=="{clear}" (
    cls
    exit /b 0
)

echo !line! | findstr /b "{clear}" >nul
if !errorlevel! == 0 (
    cls
    set "line=!line:*{clear}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{player}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[36m[YOU]%ESC%[0m"
    set "line=!line:*{player}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{heroine}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[91m[HER]%ESC%[0m"
    set "line=!line:*{heroine}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{unknown}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[91m[???]%ESC%[0m"
    set "line=!line:*{unknown}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{player_name_tag}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[36m[%player_name%]%ESC%[0m"
    set "line=!line:*{player_name_tag}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{both}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[36m[BO%ESC%[91mTH]%ESC%[0m"
    set "line=!line:*{both}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /b "{se:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1* delims=}" %%a in ("!line:*{se:=!") do (
        set "TYPEWRITER_SE_PROFILE=%%a"
    )
    set "line=!line:*}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

echo !line! | findstr /c:"{type" >nul
if !errorlevel! == 0 (
    set "type_speed=100"
    echo !line! | findstr /c:"{type:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:}" %%a in ("!line!") do (
            set "type_spec=%%a"
            if /i "!type_spec!"=="slow" set "type_speed=250"
            if /i "!type_spec!"=="normal" set "type_speed=100"
            if /i "!type_spec!"=="fast" set "type_speed=30"
            echo !type_spec! | findstr "^[0-9][0-9]*$" >nul
            if !errorlevel! == 0 set "type_speed=!type_spec!"
        )
    )
    set "inner=!line:*}=!"
    set "inner=!inner:{/type}=!"
    call "%~dp0RenderMarkup_v2.3.bat" "!inner!" parsed
    if defined SPEAKER <nul set /p="!SPEAKER! "
    if defined RENDERCONTROL_FAST_PREVIEW (
        <nul set /p="!parsed!"
    ) else (
        call "%~dp0TypeWriter_v2.3.bat" "!parsed!" !type_speed!
    )
    exit /b 0
)

echo !line! | findstr /c:"{shake" >nul
if !errorlevel! == 0 (
    set "shake_count=5"
    echo !line! | findstr /c:"{shake:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:}" %%a in ("!line!") do (
            set "shake_count=%%a"
        )
    )
    set "inner=!line:*}=!"
    set "inner=!inner:{/shake}=!"
    call "%~dp0RenderMarkup_v2.3.bat" "!inner!" parsed
    if defined SPEAKER <nul set /p="!SPEAKER! "

    set "cur_x=!CURRENT_CURSOR_X!"
    set "cur_y=!CURRENT_CURSOR_Y!"
    if not defined cur_x set "cur_x=10"
    if not defined cur_y set "cur_y=10"

    set "last_sx="
    set "last_sy="

    for /l %%i in (1,1,!shake_count!) do (
        if defined last_sx if defined last_sy (
            <nul set /p="%ESC%[!last_sy!;!last_sx!H%ESC%[0K"
        )

        set /a offset_x=!random! %% 3 - 1
        set /a offset_y=!random! %% 3 - 1
        set /a sx=!cur_x! + !offset_x!
        set /a sy=!cur_y! + !offset_y!

        <nul set /p="%ESC%[!sy!;!sx!H!parsed!"
        %tools_dir%\cmdwiz.exe delay 90

        set "last_sx=!sx!"
        set "last_sy=!sy!"
    )

    if defined last_sx if defined last_sy (
        <nul set /p="%ESC%[!last_sy!;!last_sx!H%ESC%[0K"
    )
    <nul set /p="%ESC%[!cur_y!;!cur_x!H%ESC%[0K!parsed!"
    exit /b 0
)

call "%~dp0RenderMarkup_v2.3.bat" "!line!" parsed
if defined SPEAKER <nul set /p=!SPEAKER!
<nul set /p=!parsed!
exit /b 0

:WaitForAdvanceKey
if exist "%tools_dir%\cmdwiz.exe" (
    %tools_dir%\cmdwiz.exe flushkeys >nul 2>&1
    call :WaitForAdvanceLoop
) else (
    pause >nul
)
exit /b 0

:WaitForAdvanceLoop
%tools_dir%\cmdwiz.exe getch noWait >nul 2>&1
set "wait_key=%errorlevel%"
if "%wait_key%"=="0" (
    %tools_dir%\cmdwiz.exe delay 15 >nul 2>&1
    if "%SCENARIO_SKIP_ACTIVE%"=="1" exit /b 0
    goto :WaitForAdvanceLoop
)
call :HandleLitePauseKey "%wait_key%" "RENDER_WAIT"
if "%SCENARIO_SKIP_ACTIVE%"=="1" exit /b 0
if "!pause_key_consumed!"=="1" goto :WaitForAdvanceLoop
exit /b 0

:WaitAutoOrAdvance
set "pause_ms=%~1"
if not defined pause_ms set "pause_ms=0"
if not exist "%tools_dir%\cmdwiz.exe" (
    if %pause_ms% GTR 0 timeout /t 1 >nul
    exit /b 0
)

set /a "pause_remaining=%pause_ms%"
if !pause_remaining! LSS 1 exit /b 0
%tools_dir%\cmdwiz.exe flushkeys >nul 2>&1

:WaitAutoLoop
%tools_dir%\cmdwiz.exe getch noWait >nul 2>&1
set "wait_key=%errorlevel%"
if not "%wait_key%"=="0" (
    call :HandleLitePauseKey "%wait_key%" "RENDER_AUTO"
    if "%SCENARIO_SKIP_ACTIVE%"=="1" exit /b 0
    if "!pause_key_consumed!"=="1" goto :WaitAutoLoop
    exit /b 0
)

if !pause_remaining! LEQ 15 (
    %tools_dir%\cmdwiz.exe delay !pause_remaining! >nul 2>&1
    exit /b 0
)

%tools_dir%\cmdwiz.exe delay 15 >nul 2>&1
set /a "pause_remaining-=15"
goto :WaitAutoLoop

:WaitDelayOrAdvance
set "pause_ms=%~1"
if not defined pause_ms set "pause_ms=0"
if not exist "%tools_dir%\cmdwiz.exe" (
    if %pause_ms% GTR 0 timeout /t 1 >nul
    exit /b 0
)

set /a "pause_remaining=%pause_ms%"
if !pause_remaining! LSS 1 exit /b 0
%tools_dir%\cmdwiz.exe flushkeys >nul 2>&1

:WaitDelayLoop
%tools_dir%\cmdwiz.exe getch noWait >nul 2>&1
set "wait_key=%errorlevel%"
if not "%wait_key%"=="0" (
    call :HandleLitePauseKey "%wait_key%" "RENDER_DELAY"
    if "%SCENARIO_SKIP_ACTIVE%"=="1" exit /b 0
    if "!pause_key_consumed!"=="1" goto :WaitDelayLoop
    call :HandleAdvanceKey "%wait_key%"
    if "!advance_key_consumed!"=="1" exit /b 0
)

if !pause_remaining! LEQ 15 (
    %tools_dir%\cmdwiz.exe delay !pause_remaining! >nul 2>&1
    exit /b 0
)

%tools_dir%\cmdwiz.exe delay 15 >nul 2>&1
set /a "pause_remaining-=15"
goto :WaitDelayLoop

:HandleLitePauseKey
set "incoming_key=%~1"
set "pause_source=%~2"
set "pause_key_consumed=0"
set "is_pause_key=0"

if "%incoming_key%"=="27" set "is_pause_key=1"
if "%incoming_key%"=="1" set "is_pause_key=1"
if "%incoming_key%"=="112" set "is_pause_key=1"
if "%incoming_key%"=="25" set "is_pause_key=1"

if "%is_pause_key%"=="0" exit /b 0

set "pause_key_consumed=1"
if exist "%PAUSE_MANAGER%" call "%PAUSE_MANAGER%" ENTER LITE "%pause_source%"
if "%errorlevel%"=="8" (
    set "SCENARIO_SKIP_ACTIVE=1"
)
exit /b 0

:HandleAdvanceKey
set "incoming_key=%~1"
set "advance_key_consumed=0"
set "is_advance_key=0"

if "%incoming_key%"=="13" set "is_advance_key=1"
if "%incoming_key%"=="28" set "is_advance_key=1"
if "%incoming_key%"=="32" set "is_advance_key=1"
if "%incoming_key%"=="33" set "is_advance_key=1"
if "%incoming_key%"=="57" set "is_advance_key=1"
if "%incoming_key%"=="70" set "is_advance_key=1"
if "%incoming_key%"=="102" set "is_advance_key=1"

if "%is_advance_key%"=="0" exit /b 0

set "advance_key_consumed=1"
exit /b 0
