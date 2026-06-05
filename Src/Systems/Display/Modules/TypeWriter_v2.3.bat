@echo off

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

setlocal EnableDelayedExpansion
set "line=%~1"
set "speed=%~2"
call :MainWrapper "!line!" "!speed!"
set "RC=%errorlevel%"
endlocal & (
    set "SCENARIO_SKIP_ACTIVE=%SCENARIO_SKIP_ACTIVE%"
    exit /b %RC%
)

:MainWrapper
set "line=%~1"
set "speed=%~2"
if not defined speed set "speed=100"

set "CMDWIZ=%tools_dir%\cmdwiz.exe"
set "PAUSE_MANAGER=%src_display_dir%\PauseManager.bat"
set /a "accelerated_speed=%speed% / 4"
if !accelerated_speed! lss 10 set "accelerated_speed=10"

set "tw_accel_mode=0"
set "tw_skip_line=0"
if "%SCENARIO_SKIP_ACTIVE%"=="1" set "tw_skip_line=1"
set /a i=0

call :InitTypeSe

if exist "%CMDWIZ%" "%CMDWIZ%" flushkeys >nul 2>&1

:main_loop
call :PollInput

set "prefix=!line:~%i%,2!"
if "!prefix!"=="!ESC![" (
    set "seq="
    :read_seq
    set "next=!line:~%i%,1!"
    if not defined next goto :done
    set "seq=!seq!!next!"
    set /a i+=1
    echo !next! | findstr /r "[A-Za-z]" >nul && (
        <nul set /p="!seq!"
        goto :main_loop
    )
    goto :read_seq
)

set "char=!line:~%i%,1!"
if not defined char goto :done

"%CMDWIZ%" print "!char!"
call :MaybePlayTypeSe "!char!"
set /a i+=1

if "!tw_skip_line!"=="1" goto :main_loop

if "!tw_accel_mode!"=="1" (
    "%CMDWIZ%" delay !accelerated_speed! >nul 2>&1
) else (
    "%CMDWIZ%" delay !speed! >nul 2>&1
)
goto :main_loop

:InitTypeSe
set "tw_se_spec=%TYPEWRITER_SE_PROFILE%"
set "tw_se_profile=%tw_se_spec%"
if /i "!tw_se_profile!"=="off" set "tw_se_profile=none"
if /i "!tw_se_profile!"=="silent" set "tw_se_profile=none"

set "tw_se_trigger=late"
for /f "tokens=1,2 delims=:" %%a in ("!tw_se_profile!") do (
    set "tw_se_profile=%%a"
    if not "%%b"=="" set "tw_se_trigger=%%b"
)

set "tw_se_file="
set "tw_se_stride=2"
set /a "tw_se_counter=0"
set /a "tw_se_play_count=0"
set "tw_se_max_plays=0"

if defined assets_sounds_fx_dir (
    set "tw_se_root=%assets_sounds_fx_dir%"
) else (
    if defined PROJECT_ROOT (
        set "tw_se_root=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect"
    ) else (
        set "tw_se_root=%~dp0..\..\..\Assets\Sounds\_SoundEffect"
    )
)

if /i "!tw_se_profile!"=="default" (
    set "tw_se_file=!tw_se_root!\TextSE.wav"
    set "tw_se_stride=8"
    set "tw_se_max_plays=3"
)
if /i "!tw_se_profile!"=="tick_soft" (
    set "tw_se_file=!tw_se_root!\TextSE.wav"
    set "tw_se_stride=8"
    set "tw_se_max_plays=3"
)
if /i "!tw_se_profile!"=="narration_soft" (
    set "tw_se_file=!tw_se_root!\TextSE.wav"
    set "tw_se_stride=12"
    set "tw_se_max_plays=1"
)
if /i "!tw_se_profile!"=="tick_hard" (
    set "tw_se_file=!tw_se_root!\TextSE2.wav"
    set "tw_se_stride=10"
    set "tw_se_max_plays=2"
)
if /i "!tw_se_profile!"=="beep" (
    set "tw_se_file=!tw_se_root!\Beep.wav"
    set "tw_se_stride=12"
    set "tw_se_max_plays=1"
)
if /i "!tw_se_profile!"=="none" set "tw_se_file="

if not defined tw_se_file if not "!tw_se_profile!"=="" if /i not "!tw_se_profile!"=="none" (
    set "tw_se_file=!tw_se_profile!"
    if not exist "!tw_se_file!" set "tw_se_file=!tw_se_root!\!tw_se_profile!"
    if not exist "!tw_se_file!" (
        echo !tw_se_profile! | findstr /r "\.[A-Za-z0-9][A-Za-z0-9]*$" >nul
        if errorlevel 1 set "tw_se_file=!tw_se_root!\!tw_se_profile!.wav"
    )
    if not exist "!tw_se_file!" set "tw_se_file="
    if defined tw_se_file (
        set "tw_se_stride=8"
        set "tw_se_max_plays=3"
    )
)

if not defined tw_se_file exit /b 0

if /i "!tw_se_trigger!"=="now" set /a "tw_se_counter=tw_se_stride-1"
if /i "!tw_se_trigger!"=="instant" set /a "tw_se_counter=tw_se_stride-1"

if defined src_audio_dir (
    set "tw_play_se=%src_audio_dir%\Play_SE.bat"
)
if not defined tw_play_se if defined PROJECT_ROOT (
    set "tw_play_se=%PROJECT_ROOT%\Src\Systems\Audio\Play_SE.bat"
)
exit /b 0

:MaybePlayTypeSe
if "!tw_skip_line!"=="1" exit /b 0
if not defined tw_se_file exit /b 0
if not exist "!tw_se_file!" exit /b 0
if not defined tw_play_se exit /b 0

set "tw_candidate=%~1"
if "!tw_candidate!"=="" exit /b 0
if "!tw_candidate!"==" " exit /b 0
if "!tw_candidate!"=="." exit /b 0
if "!tw_candidate!"=="," exit /b 0
if "!tw_candidate!"=="!" exit /b 0
if "!tw_candidate!"=="?" exit /b 0
if "!tw_candidate!"=="-" exit /b 0
if "!tw_candidate!"=="=" exit /b 0
if "!tw_candidate!"=="(" exit /b 0
if "!tw_candidate!"==")" exit /b 0
if "!tw_candidate!"=="[" exit /b 0
if "!tw_candidate!"=="]" exit /b 0
if "!tw_candidate!"=="{" exit /b 0
if "!tw_candidate!"=="}" exit /b 0
if "!tw_candidate!"==":" exit /b 0
if "!tw_candidate!"==";" exit /b 0
if "!tw_candidate!"=="""" exit /b 0
if "!tw_candidate!"=="'" exit /b 0
if "!tw_candidate!"=="/" exit /b 0
if "!tw_candidate!"=="\" exit /b 0
if "!tw_candidate!"=="|" exit /b 0
if "!tw_candidate!"=="+" exit /b 0
if "!tw_candidate!"=="*" exit /b 0
if "!tw_candidate!"=="_" exit /b 0

if %tw_se_max_plays% GTR 0 (
    if !tw_se_play_count! GEQ %tw_se_max_plays% exit /b 0
)

set /a "tw_se_counter+=1"
set /a "tw_se_mod=tw_se_counter %% tw_se_stride"
if not "!tw_se_mod!"=="0" exit /b 0

call "!tw_play_se!" "!tw_se_file!" >nul 2>&1
set /a "tw_se_play_count+=1"
exit /b 0

:PollInput
set "tw_key=0"
if not exist "%CMDWIZ%" exit /b 0

"%CMDWIZ%" getch noWait >nul 2>&1
set "tw_key=%errorlevel%"
if "%tw_key%"=="0" exit /b 0

call :HandlePauseKey "%tw_key%"
if "!tw_pause_handled!"=="1" exit /b 0

call :HandleAdvanceKey "%tw_key%"
exit /b 0

:HandlePauseKey
set "incoming_key=%~1"
set "tw_pause_handled=0"
set "is_pause_key=0"

if "%incoming_key%"=="27" set "is_pause_key=1"
if "%incoming_key%"=="1" set "is_pause_key=1"
if "%incoming_key%"=="112" set "is_pause_key=1"
if "%incoming_key%"=="25" set "is_pause_key=1"

if "%is_pause_key%"=="0" exit /b 0

set "tw_pause_handled=1"
if exist "%PAUSE_MANAGER%" call "%PAUSE_MANAGER%" ENTER LITE TYPEWRITER
if "%errorlevel%"=="8" (
    set "SCENARIO_SKIP_ACTIVE=1"
    set "tw_skip_line=1"
)
exit /b 0

:HandleAdvanceKey
set "incoming_key=%~1"
set "is_advance_key=0"

if "%incoming_key%"=="13" set "is_advance_key=1"
if "%incoming_key%"=="28" set "is_advance_key=1"
if "%incoming_key%"=="32" set "is_advance_key=1"
if "%incoming_key%"=="33" set "is_advance_key=1"
if "%incoming_key%"=="57" set "is_advance_key=1"
if "%incoming_key%"=="70" set "is_advance_key=1"
if "%incoming_key%"=="102" set "is_advance_key=1"

if "%is_advance_key%"=="0" exit /b 0

if "%tw_accel_mode%"=="1" (
    set "tw_skip_line=1"
) else (
    set "tw_accel_mode=1"
)
exit /b 0

:done
exit /b
