@echo off
chcp 65001 >nul
setlocal EnableExtensions

if /i "%~1"=="__RUN__" goto :START

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
call "%~dp0..\Environment\SettingPath.bat" SILENT >nul 2>&1
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "CMDWIZ=%tools_dir%\cmdwiz.exe"
set "CMDGFX_INPUT=%tools_dir%\cmdgfx_input.exe"
set "CMDGFX_BRIDGE=%PROJECT_ROOT%\Src\Systems\Debug\CmdgfxInputBridge.ps1"
set "ROOM_LAYOUT_FILE=%PROJECT_ROOT%\Assets\Layouts\01_Chapter01\01_Part01\Chapter01_RoomExplore.layout.bat"
set "LOG_DIR=%PROJECT_ROOT%\Logs"
set "LOG_FILE=%LOG_DIR%\Chapter01_RoomExplore_MouseProbe.log"
if not defined MOUSE_PROBE_LOG set "MOUSE_PROBE_LOG=0"
if not defined PROBE_DEBUG_PANEL set "PROBE_DEBUG_PANEL=0"

if not exist "%CMDGFX_INPUT%" (
    echo cmdgfx_input.exe not found: "%CMDGFX_INPUT%"
    exit /b 1
)
if not exist "%CMDGFX_BRIDGE%" (
    echo Cmdgfx bridge not found: "%CMDGFX_BRIDGE%"
    exit /b 1
)
if not exist "%ROOM_LAYOUT_FILE%" (
    echo Layout file not found: "%ROOM_LAYOUT_FILE%"
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
break > "%LOG_FILE%"

mode 240,67 >nul 2>&1
"%CMDWIZ%" showcursor 0 >nul 2>&1
"%CMDWIZ%" setquickedit 0 >nul 2>&1
title Chapter01 Room Mouse Probe
call "%CMDGFX_INPUT%" M0uw4 | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CMDGFX_BRIDGE%" | call "%~f0" __RUN__
title input:Q
"%CMDWIZ%" showcursor 1 >nul 2>&1
"%CMDWIZ%" setquickedit 1 >nul 2>&1
exit /b 0

:START
powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1
setlocal EnableDelayedExpansion
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
call "%~dp0..\Environment\SettingPath.bat" SILENT >nul 2>&1
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "ROOM_LAYOUT_FILE=%PROJECT_ROOT%\Assets\Layouts\01_Chapter01\01_Part01\Chapter01_RoomExplore.layout.bat"
set "LOG_FILE=%PROJECT_ROOT%\Logs\Chapter01_RoomExplore_MouseProbe.log"
set "LAST_ROOM_BG="
set "current_page="
set "current_spot="
set "prev_spot=0"
set "status_msg=Mouse probe started."
set "last_input="
set "last_mouse_values="
set "last_key_values="
set /a log_count=0
set /a exit_requested=0
set /a last_mouse_signal=0
set "needs_status_redraw=1"

call :LoadLayout
call :SetCurrentPageFromSpot %current_spot%
call :ApplyCurrentBackground
call :RenderStatic
call :RenderDynamic

:INPUT_LOOP
if !exit_requested! NEQ 0 goto :EXIT_PROBE
set "INPUT="
set /p "INPUT=" || goto :EXIT_PROBE
if not defined INPUT goto :INPUT_LOOP
set "last_input=!INPUT!"
call :AppendLog "!INPUT!"
call :HandleInput
goto :INPUT_LOOP

:EXIT_PROBE
title input:Q
endlocal
exit /b 0

:AppendLog
if /i not "%MOUSE_PROBE_LOG%"=="1" exit /b 0
if !log_count! GEQ 300 exit /b 0
>> "%LOG_FILE%" echo %date% %time% ^| %~1
set /a log_count+=1
exit /b 0

:LoadLayout
call "%ROOM_LAYOUT_FILE%"
if not defined current_spot call set "current_spot=%%page_default_spot_1%%"
if not defined current_page call set "current_page=%%page_id_1%%"
if not defined current_spot set "current_spot=1"
exit /b 0

:SetCurrentPageFromSpot
set "lookup_idx=%~1"
call set "current_page=%%spot_page_%lookup_idx%%%"
if not defined current_page call set "current_page=%%page_id_1%%"
exit /b 0

:ApplyCurrentBackground
set "page_bg_name="
for /l %%i in (1,1,%page_count%) do (
    call set "page_id_value=%%page_id_%%i%%%"
    if /i "!page_id_value!"=="%current_page%" call set "page_bg_name=%%page_bg_%%i%%%"
)
if not defined page_bg_name exit /b 0
set "ROOM_BG_FILE=%assets_images_dir%\%page_bg_name%"
if not exist "%ROOM_BG_FILE%" exit /b 0
if /i "%LAST_ROOM_BG%"=="%ROOM_BG_FILE%" exit /b 0
%tools_dir%\cmdbkg.exe "%ROOM_BG_FILE%" /b >nul 2>&1
set "LAST_ROOM_BG=%ROOM_BG_FILE%"
exit /b 0

:HandleInput
set "input_head=!INPUT:~0,10!"
if /i "!input_head!"=="NO_EVENT 0" exit /b 0
if /i not "!input_head!"=="KEY_EVENT " (
    call :AppendLog "DROP_FRAGMENT !INPUT!"
    exit /b 0
)
if "!INPUT:MOUSE_EVENT=!"=="!INPUT!" (
    call :AppendLog "DROP_NO_MOUSE !INPUT!"
    exit /b 0
)
if "!INPUT:LEFT_DOUBLE=!"=="!INPUT!" (
    call :AppendLog "DROP_SHORT !INPUT!"
    exit /b 0
)
call :HandleMouseEvent
call :HandleKeyEvent
exit /b 0

:HandleMouseEvent
set "M_EVT="
set "M_X="
set "M_Y="
set "M_A="
set "M_B="
set "M_C="
set "M_D="
set "mouse_part=!INPUT:*MOUSE_EVENT=MOUSE_EVENT!"
for /f "tokens=2,4,6,8,10,12,14" %%A in ("!mouse_part!") do (
    set /a M_EVT=%%A, M_X=%%B, M_Y=%%C, M_A=%%D, M_B=%%E, M_C=%%F, M_D=%%G 2>nul
)
if not defined M_X exit /b 0
set "last_mouse_values=evt=!M_EVT! x=!M_X! y=!M_Y! a=!M_A! b=!M_B! c=!M_C! d=!M_D!"
set "mouse_target="
call :FindSpotUnderMouse !M_X! !M_Y!
set "mouse_changed=0"
if defined mouse_target (
    if not "!current_spot!"=="!mouse_target!" (
        set "prev_spot=!current_spot!"
        set "current_spot=!mouse_target!"
        set "mouse_changed=1"
        if /i "%PROBE_DEBUG_PANEL%"=="1" set "needs_status_redraw=1"
    )
)
set /a mouse_signal=0
for %%V in (!M_A! !M_B! !M_C! !M_D!) do (
    if not "%%~V"=="" if %%~V NEQ 0 set /a mouse_signal=1
)
if !mouse_signal! NEQ 0 if !last_mouse_signal! EQU 0 (
    call :InspectCurrent
    set "needs_status_redraw=1"
)
set /a last_mouse_signal=mouse_signal
if "!mouse_changed!"=="1" call :RenderDynamic
exit /b 0

:HandleKeyEvent
set "K_EVT="
set "K_DOWN="
set "KEY="
set "key_part=!INPUT:*KEY_EVENT=KEY_EVENT!"
for /f "tokens=2,4,6" %%A in ("!key_part!") do (
    set /a K_EVT=%%A, K_DOWN=%%B, KEY=%%C 2>nul
)
set "last_key_values=evt=!K_EVT! down=!K_DOWN! key=!KEY!"
if not defined KEY exit /b 0
if "!KEY!"=="0" exit /b 0
set "needs_status_redraw=1"
if "!K_DOWN!"=="1" (
    if "!KEY!"=="27" set /a exit_requested=1
    if "!KEY!"=="81" set /a exit_requested=1
    if "!KEY!"=="113" set /a exit_requested=1
    if "!KEY!"=="87" call :MoveUp
    if "!KEY!"=="119" call :MoveUp
    if "!KEY!"=="72" call :MoveUp
    if "!KEY!"=="65" call :MoveLeft
    if "!KEY!"=="97" call :MoveLeft
    if "!KEY!"=="75" call :MoveLeft
    if "!KEY!"=="83" call :MoveDown
    if "!KEY!"=="115" call :MoveDown
    if "!KEY!"=="80" call :MoveDown
    if "!KEY!"=="68" call :MoveRight
    if "!KEY!"=="100" call :MoveRight
    if "!KEY!"=="77" call :MoveRight
    if "!KEY!"=="70" call :InspectCurrent
    if "!KEY!"=="102" call :InspectCurrent
    if "!KEY!"=="13" call :InspectCurrent
)
call :RenderDynamic
exit /b 0

:MoveUp
call set "next_spot=%%spot_up_%current_spot%%%"
if defined next_spot (
    set "prev_spot=!current_spot!"
    set "current_spot=!next_spot!"
)
exit /b 0

:MoveDown
call set "next_spot=%%spot_down_%current_spot%%%"
if defined next_spot (
    set "prev_spot=!current_spot!"
    set "current_spot=!next_spot!"
)
exit /b 0

:MoveLeft
call set "next_spot=%%spot_left_%current_spot%%%"
if defined next_spot (
    set "prev_spot=!current_spot!"
    set "current_spot=!next_spot!"
)
exit /b 0

:MoveRight
call set "next_spot=%%spot_right_%current_spot%%%"
if defined next_spot (
    set "prev_spot=!current_spot!"
    set "current_spot=!next_spot!"
)
exit /b 0

:InspectCurrent
call set "action=%%spot_action_%current_spot%%%"
call set "target=%%spot_target_%current_spot%%%"
call set "spot_id=%%spot_id_%current_spot%%%"
call :DescribeSpot "%spot_id%"
if /i "%action%"=="page" (
    if defined target (
        set "prev_spot=0"
        set "current_spot=!target!"
        call :SetCurrentPageFromSpot !target!
        call :ApplyCurrentBackground
        set "status_msg=View changed to !current_page!."
        set "last_mouse_values="
        call :RenderStatic
        set "needs_status_redraw=1"
    )
    exit /b 0
)
if /i "%action%"=="exit" (
    set "status_msg=Door selected. Exit transition is disabled in probe."
    exit /b 0
)
set "status_msg=Inspect: %spot_display_name%"
exit /b 0

:FindSpotUnderMouse
set "mouse_target="
for /l %%i in (1,1,%spot_count%) do (
    if not defined mouse_target call :CheckSpotHit %%i %~1 %~2
)
exit /b 0

:CheckSpotHit
setlocal EnableDelayedExpansion
set "idx=%~1"
set /a "mx=%~2"
set /a "my=%~3"
call set "spot_page=%%spot_page_%idx%%%"
if /i not "!spot_page!"=="%current_page%" exit /b 0
call set /a sx=%%spot_x_%idx%%%
call set /a sy=%%spot_y_%idx%%%
call set /a sw=%%spot_hit_w_%idx%%%
call set /a sh=%%spot_hit_h_%idx%%%
if !sw! LSS 1 set /a sw=1
if !sh! LSS 1 set /a sh=1
set /a left=sx - (sw / 2)
set /a right=sx + (sw / 2)
set /a top=sy - (sh / 2)
set /a bottom=sy + (sh / 2)
if !mx! GEQ !left! if !mx! LEQ !right! if !my! GEQ !top! if !my! LEQ !bottom! (
    endlocal & set "mouse_target=%~1" & exit /b 0
)
endlocal
exit /b 0

:RenderStatic
cls
call :DrawTitle
for /l %%i in (1,1,%spot_count%) do (
    call set "spot_page=%%spot_page_%%i%%%"
    if /i "!spot_page!"=="%current_page%" call :DrawSpot %%i
)
exit /b 0

:RenderDynamic
if not "%prev_spot%"=="0" call :DrawSpot %prev_spot%
call :DrawSpot %current_spot%
if "%needs_status_redraw%"=="1" call :DrawStatus
set "prev_spot=0"
set "needs_status_redraw=0"
exit /b 0

:DrawTitle
<nul set /p ="%ESC%[2;4H%ESC%[97mChapter01 Room Mouse Probe%ESC%[0m"
<nul set /p ="%ESC%[3;4H%ESC%[90mEsc/Q: exit  WASD: move  F/Enter: inspect  Mouse: hover/select, candidate click logs enabled%ESC%[0m"
exit /b 0

:DrawSpot
setlocal EnableDelayedExpansion
set "idx=%~1"
call set "sx=%%spot_x_%idx%%%"
call set "sy=%%spot_y_%idx%%%"
call set "spot_id=%%spot_id_%idx%%%"
call set "marker_type=%%spot_marker_%idx%%%"
set "mark_color=%ESC%[90m"
call :ResolveMarker "!marker_type!" normal mark
if "%idx%"=="%current_spot%" (
    set "mark_color=%ESC%[96m"
    call :ResolveMarker "!marker_type!" active mark
)
set /a draw_x=sx-1
<nul set /p ="%ESC%[!sy!;!draw_x!H!mark_color!!mark!%ESC%[0m"
endlocal
exit /b 0

:ResolveMarker
setlocal
set "marker_type=%~1"
set "variant=%~2"
set "mark=*"
if /i "%marker_type%"=="nav_right" set "mark=R"
if /i "%marker_type%"=="nav_left" set "mark=L"
if /i "%marker_type%"=="door" set "mark=D"
if /i "%variant%"=="active" (
    if /i "%marker_type%"=="diamond" set "mark=[*]"
    if /i "%marker_type%"=="nav_right" set "mark=[R]"
    if /i "%marker_type%"=="nav_left" set "mark=[L]"
    if /i "%marker_type%"=="door" set "mark=[D]"
)
endlocal & set "%~3=%mark%"
exit /b 0

:DrawStatus
call set "spot_id=%%spot_id_%current_spot%%%"
call :DescribeSpot "%spot_id%"
set "page_label=Left"
if /i "%current_page%"=="room_right" set "page_label=Right"
if /i "%PROBE_DEBUG_PANEL%"=="1" (
    <nul set /p ="%ESC%[56;4H%ESC%[0K%ESC%[93mPage:%ESC%[0m %page_label%  (%current_page%)"
    <nul set /p ="%ESC%[57;4H%ESC%[0K%ESC%[93mSpot:%ESC%[0m %spot_display_name%"
    <nul set /p ="%ESC%[58;4H%ESC%[0K%ESC%[90m%spot_display_hint%%ESC%[0m"
    <nul set /p ="%ESC%[59;4H%ESC%[0K%ESC%[93mStatus:%ESC%[0m %status_msg%"
    <nul set /p ="%ESC%[60;4H%ESC%[0K%ESC%[93mMouse:%ESC%[0m %last_mouse_values%"
    <nul set /p ="%ESC%[61;4H%ESC%[0K%ESC%[93mKey:%ESC%[0m %last_key_values%"
    <nul set /p ="%ESC%[62;4H%ESC%[0K%ESC%[93mRaw:%ESC%[0m %last_input%"
    <nul set /p ="%ESC%[63;4H%ESC%[0K%ESC%[90mLog file: %LOG_FILE%%ESC%[0m"
    exit /b 0
)
<nul set /p ="%ESC%[62;4H%ESC%[0K%ESC%[93mPage:%ESC%[0m %page_label%  %ESC%[93mSpot:%ESC%[0m %spot_display_name%"
<nul set /p ="%ESC%[63;4H%ESC%[0K%ESC%[90m%status_msg%%ESC%[0m"
exit /b 0

:DescribeSpot
set "spot_display_name=%~1"
set "spot_display_hint="
if /i "%~1"=="window" (
    set "spot_display_name=Window"
    set "spot_display_hint=Morning light enters from the royal capital side."
)
if /i "%~1"=="desk" (
    set "spot_display_name=Desk"
    set "spot_display_hint=Textbooks and notes are spread across the desk."
)
if /i "%~1"=="banner" (
    set "spot_display_name=Banner"
    set "spot_display_hint=The Star Guide crest hangs on the wall."
)
if /i "%~1"=="wood_sword" (
    set "spot_display_name=Wood Sword"
    set "spot_display_hint=A practice sword received from the hero's father."
)
if /i "%~1"=="nav_right" (
    set "spot_display_name=Look Right"
    set "spot_display_hint=Switch to the door side of the room."
)
if /i "%~1"=="nav_left" (
    set "spot_display_name=Look Left"
    set "spot_display_hint=Switch to the window and desk side."
)
if /i "%~1"=="shelf" (
    set "spot_display_name=Shelf"
    set "spot_display_hint=Textbooks and starcraft books are lined up."
)
if /i "%~1"=="trunk" (
    set "spot_display_name=Trunk"
    set "spot_display_hint=Packed gear and travel traces remain here."
)
if /i "%~1"=="bed" (
    set "spot_display_name=Bed"
    set "spot_display_hint=It still looks tempting after waking up."
)
if /i "%~1"=="door" (
    set "spot_display_name=Door"
    set "spot_display_hint=The exit leading downstairs."
)
exit /b 0
