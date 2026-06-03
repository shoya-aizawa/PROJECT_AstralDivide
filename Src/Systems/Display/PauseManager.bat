@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

if not defined src_audio_dir set "src_audio_dir=%PROJECT_ROOT%\Src\Systems\Audio"
if not defined src_display_dir set "src_display_dir=%PROJECT_ROOT%\Src\Systems\Display"
if not defined tools_dir set "tools_dir=%PROJECT_ROOT%\Tools"
if not defined RCSU set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "ACTION=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=FULL"

if /i "%ACTION%"=="POLL" goto :Poll
if /i "%ACTION%"=="ENTER" goto :Enter
if /i "%ACTION%"=="RESUME" goto :Resume
if /i "%ACTION%"=="RESET" exit /b 0
exit /b 0

:Poll
call :PollPauseKey
if "!pause_key_hit!"=="1" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause key detected mode=%MODE% key=%pause_key_code%"
    call "%~f0" ENTER %MODE%
    exit /b !errorlevel!
)
exit /b 0

:Enter
if /i "%MODE%"=="FULL" goto :EnterFull
exit /b 0

:EnterFull
if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "enter full pause"
set "PAUSE_BGM_VOLUME=%BGM_VOLUME%"
if not defined PAUSE_BGM_VOLUME set "PAUSE_BGM_VOLUME=30"
set "PAUSE_BGM_PATH=%CURRENT_BGM_PATH%"
set "PAUSE_BGM_MODE=%CURRENT_BGM_MODE%"
if not defined PAUSE_BGM_MODE set "PAUSE_BGM_MODE=repeat"
set "PAUSE_SETTINGS_TOUCHED=0"
call :PauseBgm
set "pause_selected=1"

:PauseMenuLoop
call :RenderFullPauseMenu
call :PollPauseMenuKey

if "!pause_menu_action!"=="UP" (
    set /a pause_selected-=1
    if !pause_selected! LSS 1 set "pause_selected=5"
    goto :PauseMenuLoop
)
if "!pause_menu_action!"=="DOWN" (
    set /a pause_selected+=1
    if !pause_selected! GTR 5 set "pause_selected=1"
    goto :PauseMenuLoop
)
if "!pause_menu_action!"=="RESUME" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause resume selected"
    call :ResumeBgm
    exit /b 0
)
if "!pause_menu_action!"=="SETTINGS" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause settings selected"
    set "PAUSE_SUPPRESS_BGM_PREVIEW=1"
    set "PAUSE_SETTINGS_TOUCHED=1"
    call "%src_display_dir%\SettingsMenu.bat"
    set "PAUSE_SUPPRESS_BGM_PREVIEW="
    goto :PauseMenuLoop
)
if "!pause_menu_action!"=="TITLE" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause return-to-title selected"
    call :ConfirmDanger "Return to title?" "Unsaved progress will be lost."
    if not "!pause_confirm_ok!"=="1" goto :PauseMenuLoop
    call :StopBgm
    exit /b 641
)
if "!pause_menu_action!"=="EXIT" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause exit selected"
    call :ConfirmDanger "Exit game?" "Unsaved progress will be lost."
    if not "!pause_confirm_ok!"=="1" goto :PauseMenuLoop
    call :StopBgm
    exit /b 642
)
if "!pause_menu_action!"=="DISABLED" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause disabled item selected"
    if exist "%src_audio_dir%\Play_SE.bat" if defined assets_sounds_fx_dir (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
    )
    goto :PauseMenuLoop
)
goto :PauseMenuLoop

:PauseBgm
if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause bgm fadeout start"
if exist "%src_audio_dir%\BgmPlayer.bat" (
    call "%src_audio_dir%\BgmPlayer.bat" VOLUME 0 220 >nul 2>&1
    if exist "%tools_dir%\cmdwiz.exe" (
        call "%tools_dir%\cmdwiz.exe" delay 240 >nul 2>&1
    ) else (
        timeout /t 1 /nobreak >nul
    )
    call "%src_audio_dir%\BgmPlayer.bat" PAUSE >nul 2>&1
)
if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause bgm paused"
exit /b 0

:ResumeBgm
set "pause_resume_volume=%BGM_VOLUME%"
if not defined pause_resume_volume set "pause_resume_volume=%PAUSE_BGM_VOLUME%"
if not defined pause_resume_volume set "pause_resume_volume=30"
if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause bgm resume start vol=%pause_resume_volume% touched=%PAUSE_SETTINGS_TOUCHED%"
if exist "%src_audio_dir%\BgmPlayer.bat" (
    call "%src_audio_dir%\BgmPlayer.bat" RESUME >nul 2>&1
    if exist "%tools_dir%\cmdwiz.exe" (
        call "%tools_dir%\cmdwiz.exe" delay 90 >nul 2>&1
    ) else (
        timeout /t 1 /nobreak >nul
    )
    call "%src_audio_dir%\BgmPlayer.bat" VOLUME %pause_resume_volume% 220 >nul 2>&1
)
exit /b 0

:StopBgm
if exist "%RCSU%" call "%RCSU%" -trace INFO PauseManager "pause bgm stop"
if exist "%src_audio_dir%\BgmPlayer.bat" (
    call "%src_audio_dir%\BgmPlayer.bat" STOP 180 >nul 2>&1
)
exit /b 0

:RenderFullPauseMenu
cls
echo %ESC%[18;84H%ESC%[96mPAUSED%ESC%[0m
echo %ESC%[20;72H%ESC%[90mW/S or Arrow Keys  F/Enter: Select  Q/Esc/P: Resume%ESC%[0m
call :RenderPauseItem 1 "Resume"
call :RenderPauseItem 2 "Settings"
call :RenderPauseItem 3 "Return to Title"
call :RenderPauseItem 4 "Exit Game"
call :RenderPauseItem 5 "Save and Exit [Unavailable]"
exit /b 0

:RenderPauseItem
setlocal EnableDelayedExpansion
set "item_idx=%~1"
set "item_text=%~2"
set /a item_row=24 + (item_idx - 1) * 2
set "prefix=  "
set "color=%ESC%[37m"
if "%item_idx%"=="5" set "color=%ESC%[90m"
if "!item_idx!"=="%pause_selected%" (
    set "prefix=> "
    if "%item_idx%"=="5" (
        set "color=%ESC%[90m"
    ) else (
        set "color=%ESC%[93m"
    )
)
echo !ESC![!item_row!;76H!color!!prefix!!item_text!%ESC%[0m
endlocal
exit /b 0

:ConfirmDanger
set "pause_confirm_ok=0"
call :RenderFullPauseMenu
call :RenderConfirmDialog "%~1" "%~2"

:ConfirmDangerLoop
call "%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "confirm_key=%errorlevel%"
if "%confirm_key%"=="0" (
    call "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :ConfirmDangerLoop
)

if /i "%confirm_key%"=="89" set "pause_confirm_ok=1"
if /i "%confirm_key%"=="121" set "pause_confirm_ok=1"
if "%confirm_key%"=="13" set "pause_confirm_ok=1"
if "%confirm_key%"=="28" set "pause_confirm_ok=1"
if "%confirm_key%"=="78" set "pause_confirm_ok=0"
if "%confirm_key%"=="110" set "pause_confirm_ok=0"
if "%confirm_key%"=="27" set "pause_confirm_ok=0"
if "%confirm_key%"=="1" set "pause_confirm_ok=0"
exit /b 0

:RenderConfirmDialog
setlocal EnableDelayedExpansion
set "dialog_title=%~1"
set "dialog_text=%~2"
set /a "left=64"
set /a "top=27"
set /a "width=56"
set /a "right=left + width - 1"
set /a "bottom=top + 6"
set /a "text_row=top + 2"
set /a "confirm_row=top + 4"
set /a "cancel_row=top + 5"
set /a "text_col=left + 2"

for /l %%r in (!top!,1,!bottom!) do (
    echo !ESC![%%r;!left!H!ESC![48;5;236m                                                        !ESC![0m
)

echo !ESC![!top!;!left!H!ESC![97;41m+------------------------------------------------------+!ESC![0m
echo !ESC![!bottom!;!left!H!ESC![97;41m+------------------------------------------------------+!ESC![0m
echo !ESC![!top!;!text_col!H!ESC![97;41m!dialog_title!!ESC![0m
echo !ESC![!text_row!;!text_col!H!ESC![97m!dialog_text!!ESC![0m
echo !ESC![!confirm_row!;!text_col!H!ESC![93mY / Enter: Confirm!ESC![0m
echo !ESC![!cancel_row!;!text_col!H!ESC![90mN / Esc: Cancel!ESC![0m
endlocal
exit /b 0

:PollPauseKey
set "pause_key_hit=0"
if not exist "%tools_dir%\cmdwiz.exe" exit /b 0
call "%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "pause_key_code=%errorlevel%"
if "%pause_key_code%"=="0" exit /b 0
if "%pause_key_code%"=="27" set "pause_key_hit=1"
if "%pause_key_code%"=="112" set "pause_key_hit=1"
if "%pause_key_code%"=="1" set "pause_key_hit=1"
if "%pause_key_code%"=="25" set "pause_key_hit=1"
exit /b 0

:PollPauseMenuKey
set "pause_menu_action="
if not exist "%tools_dir%\cmdwiz.exe" (
    set "pause_menu_action=RESUME"
    exit /b 0
)

:PauseMenuPollLoop
call "%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "pause_menu_key=%errorlevel%"
if "%pause_menu_key%"=="0" (
    call "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :PauseMenuPollLoop
)

if "%pause_menu_key%"=="87" set "pause_menu_action=UP"
if "%pause_menu_key%"=="119" set "pause_menu_action=UP"
if "%pause_menu_key%"=="72" set "pause_menu_action=UP"
if "%pause_menu_key%"=="23" set "pause_menu_action=UP"
if "%pause_menu_key%"=="83" set "pause_menu_action=DOWN"
if "%pause_menu_key%"=="115" set "pause_menu_action=DOWN"
if "%pause_menu_key%"=="80" if not defined pause_menu_action set "pause_menu_action=DOWN"
if "%pause_menu_key%"=="19" if not defined pause_menu_action set "pause_menu_action=DOWN"

if "%pause_menu_key%"=="81" set "pause_menu_action=RESUME"
if "%pause_menu_key%"=="113" set "pause_menu_action=RESUME"
if "%pause_menu_key%"=="27" set "pause_menu_action=RESUME"
if "%pause_menu_key%"=="1" set "pause_menu_action=RESUME"
if "%pause_menu_key%"=="112" if not defined pause_menu_action set "pause_menu_action=RESUME"
if "%pause_menu_key%"=="25" if not defined pause_menu_action set "pause_menu_action=RESUME"

if "%pause_menu_key%"=="70" set "pause_menu_action=SELECT"
if "%pause_menu_key%"=="102" set "pause_menu_action=SELECT"
if "%pause_menu_key%"=="13" set "pause_menu_action=SELECT"
if "%pause_menu_key%"=="28" set "pause_menu_action=SELECT"
if "%pause_menu_key%"=="33" set "pause_menu_action=SELECT"

if not defined pause_menu_action goto :PauseMenuPollLoop

if "%pause_menu_action%"=="SELECT" (
    if "%pause_selected%"=="1" set "pause_menu_action=RESUME"
    if "%pause_selected%"=="2" set "pause_menu_action=SETTINGS"
    if "%pause_selected%"=="3" set "pause_menu_action=TITLE"
    if "%pause_selected%"=="4" set "pause_menu_action=EXIT"
    if "%pause_selected%"=="5" set "pause_menu_action=DISABLED"
)
exit /b 0
