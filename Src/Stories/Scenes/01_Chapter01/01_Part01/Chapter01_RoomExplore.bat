@echo off
if /i "%~1"=="__RUN__" goto :ROOM_START_BRIDGE
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
set "CMDGFX_INPUT=%PROJECT_ROOT%\Tools\cmdgfx_input.exe"
set "CMDGFX_BRIDGE=%PROJECT_ROOT%\Src\Systems\Debug\CmdgfxInputBridge.ps1"
set "ROOM_HOVER_SE=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect\Move.wav"
set "ROOM_LOG_DIR=%PROJECT_ROOT%\Logs"
set "ROOM_INPUT_LOG=%ROOM_LOG_DIR%\Chapter01_RoomExplore_Input.log"
set "ROOM_BRIDGE_LOG=%ROOM_LOG_DIR%\Chapter01_RoomExplore_Bridge.log"
set "CMDGFX_INPUT_FLAGS=M13nW15xR"
if exist "%CMDGFX_INPUT%" if exist "%CMDGFX_BRIDGE%" goto :ROOM_LAUNCH_BRIDGE
set "ROOM_INPUT_MODE=legacy"
goto :ROOM_START

:ROOM_LAUNCH_BRIDGE
set "ROOM_INPUT_MODE=bridge"
if not exist "%ROOM_LOG_DIR%" mkdir "%ROOM_LOG_DIR%" >nul 2>&1
break > "%ROOM_BRIDGE_LOG%"
set "ROOM_BRIDGE_STOP=%TEMP%\AstralDivide_Chapter01_RoomExplore_%RANDOM%_%RANDOM%.stop"
if exist "%ROOM_BRIDGE_STOP%" del /q "%ROOM_BRIDGE_STOP%" >nul 2>&1
set "CMDGFX_BRIDGE_LOG=%ROOM_BRIDGE_LOG%"
call "%CMDGFX_INPUT%" %CMDGFX_INPUT_FLAGS% | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CMDGFX_BRIDGE%" | call "%~f0" __RUN__
if exist "%ROOM_BRIDGE_STOP%" del /q "%ROOM_BRIDGE_STOP%" >nul 2>&1
exit /b %errorlevel%

:ROOM_START_BRIDGE
set "ROOM_INPUT_MODE=bridge"

:ROOM_START
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "CURRENT_SKIP_POLICY=1"
set "ROOM_LAYOUT_FILE=%PROJECT_ROOT%\Assets\Layouts\01_Chapter01\01_Part01\Chapter01_RoomExplore.layout.bat"
set "ROOM_TEXT_DIR=%src_text_chapter01_dir%\01_Part01\RoomExplore"
set "current_location=王都エリュシオン - 自室"
set "current_page="
set "current_spot="
set "prev_spot=0"
set "room_exit_confirmed=0"
set "LAST_ROOM_BG="
set "last_bridge_mouse_signal=0"
set "last_bridge_left_signal=0"
set "room_overlay_mode="
set /a room_input_log_count=0

if not exist "%ROOM_LOG_DIR%" mkdir "%ROOM_LOG_DIR%" >nul 2>&1
break > "%ROOM_INPUT_LOG%"

call :LoadLayout
call "%tools_dir%\cmdwiz.exe" setquickedit 0 <nul >nul 2>&1
call :SetCurrentPageFromSpot %current_spot%
call :ApplyCurrentBackground
call :RenderStatic
call :RenderDynamic

:room_loop
call :PollInput
if "%pick%"=="0" (
    if /i "%ROOM_INPUT_MODE%"=="bridge" (
        "%tools_dir%\cmdwiz.exe" delay 1 >nul 2>&1
    ) else (
        "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    )
    goto :room_loop
)
if "%pick%"=="PAUSE" (
    if /i "%ROOM_INPUT_MODE%"=="bridge" (
        call :EnterBridgePause
        goto :room_loop
    )
    call "%src_display_dir%\PauseManager.bat" ENTER FULL
    set "pause_rc=!errorlevel!"
    if "!pause_rc!"=="641" goto :exit_to_title
    if "!pause_rc!"=="642" goto :exit_game
    call :ApplyCurrentBackground
    call :RenderStatic
    set "prev_spot=0"
    set "last_bridge_mouse_signal=0"
    call :RenderDynamic
    goto :room_loop
)
if "%pick%"=="STREAM_END" goto :exit_game
if "%pick%"=="SCENE_ACK" (
    call :FinishSceneAck
    goto :room_loop
)
if "%pick%"=="PAUSE_RESUME" (
    call :ResumeBridgePause
    goto :room_loop
)
if "%pick%"=="LEAVE_CANCEL" (
    call :CancelLeaveConfirm
    goto :room_loop
)
if "%pick%"=="LEAVE_ACCEPT" (
    call :AcceptLeaveConfirm
    if "!room_exit_confirmed!"=="1" goto :exit_room
    goto :room_loop
)
if "%pick%"=="1" call :MoveUp & goto :room_loop
if "%pick%"=="2" call :MoveLeft & goto :room_loop
if "%pick%"=="3" call :MoveDown & goto :room_loop
if "%pick%"=="4" call :MoveRight & goto :room_loop
if "%pick%"=="5" (
    call :InspectCurrent
    if "!room_exit_confirmed!"=="1" goto :exit_room
    goto :room_loop
)
goto :room_loop

:PollInput
set "pick=0"
if /i "%ROOM_INPUT_MODE%"=="bridge" (
    call :PollInputBridge
    exit /b 0
)
call :PollInputLegacy
exit /b 0

:PollInputLegacy
call "%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "key_code=%errorlevel%"
if not "%key_code%"=="0" goto :PollInputKeyDone
call :HandleMouseClick
:PollInputKeyDone
if "%key_code%"=="87" set "pick=1"
if "%key_code%"=="119" set "pick=1"
if "%key_code%"=="72" set "pick=1"
if "%key_code%"=="65" set "pick=2"
if "%key_code%"=="97" set "pick=2"
if "%key_code%"=="75" if "%pick%"=="0" set "pick=2"
if "%key_code%"=="83" set "pick=3"
if "%key_code%"=="115" set "pick=3"
if "%key_code%"=="80" if "%pick%"=="0" set "pick=3"
if "%key_code%"=="68" set "pick=4"
if "%key_code%"=="100" set "pick=4"
if "%key_code%"=="77" if "%pick%"=="0" set "pick=4"
if "%key_code%"=="70" set "pick=5"
if "%key_code%"=="102" set "pick=5"
if "%key_code%"=="13" if "%pick%"=="0" set "pick=5"
if "%key_code%"=="28" if "%pick%"=="0" set "pick=5"
if "%key_code%"=="27" set "pick=PAUSE"
if "%key_code%"=="112" if "%pick%"=="0" set "pick=PAUSE"
if "%key_code%"=="25" if "%pick%"=="0" set "pick=PAUSE"
exit /b 0

:PollInputBridge
set "INPUT="
set /p "INPUT=" || (
    set "pick=STREAM_END"
    exit /b 0
)
if not defined INPUT exit /b 0
call :HandleBridgeInput
exit /b 0

:HandleBridgeInput
set "TOK1="
set "VAL2="
set "TOK3="
set "VAL4="
set "TOK5="
set "VAL6="
set "TOK7="
set "VAL8="
set "TOK9="
set "VAL10="
set "TOK11="
set "VAL12="
set "TOK13="
set "VAL14="
set "TOK15="
set "VAL16="
set "TOK17="
set "VAL18="
set "TOK19="
set "VAL20="
set "TOK21="
set "VAL22="
for /f "tokens=1-22" %%A in ("!INPUT!") do (
    set "TOK1=%%A"
    set "VAL2=%%B"
    set "TOK3=%%C"
    set "VAL4=%%D"
    set "TOK5=%%E"
    set "VAL6=%%F"
    set "TOK7=%%G"
    set "VAL8=%%H"
    set "TOK9=%%I"
    set "VAL10=%%J"
    set "TOK11=%%K"
    set "VAL12=%%L"
    set "TOK13=%%M"
    set "VAL14=%%N"
    set "TOK15=%%O"
    set "VAL16=%%P"
    set "TOK17=%%Q"
    set "VAL18=%%R"
    set "TOK19=%%S"
    set "VAL20=%%T"
    set "TOK21=%%U"
    set "VAL22=%%V"
)
if /i "!TOK1!"=="NO_EVENT" exit /b 0
if /i not "!TOK1!"=="KEY_EVENT" exit /b 0
if /i not "!TOK3!"=="DOWN" exit /b 0
if /i not "!TOK5!"=="VALUE" exit /b 0
if /i not "!TOK7!"=="MOUSE_EVENT" exit /b 0
if /i not "!TOK9!"=="X" exit /b 0
if /i not "!TOK11!"=="Y" exit /b 0
if /i not "!TOK13!"=="LEFT" exit /b 0
if /i not "!TOK15!"=="RIGHT" exit /b 0
if /i not "!TOK17!"=="LEFT_DOUBLE" exit /b 0
if /i not "!TOK19!"=="RIGHT_DOUBLE" exit /b 0
if /i not "!TOK21!"=="WHEEL" exit /b 0
set /a K_EVT=VAL2, K_DOWN=VAL4, KEY=VAL6, M_EVT=VAL8, M_X=VAL10, M_Y=VAL12, M_A=VAL14, M_B=VAL16, M_C=VAL18, M_D=VAL20, M_WHEEL=VAL22 2>nul
call :HandleBridgeMouseEvent
call :HandleBridgeKeyEvent
exit /b 0

:HandleBridgeMouseEvent
if not defined M_X exit /b 0
set "mouse_target="
call :FindSpotUnderMouse !M_X! !M_Y!
set /a left_signal=0
if defined M_A if !M_A! NEQ 0 set /a left_signal=1
if defined mouse_target (
    if !left_signal! NEQ 0 if !last_bridge_left_signal! EQU 0 (
        if not "!current_spot!"=="!mouse_target!" (
            set "prev_spot=!current_spot!"
            set "current_spot=!mouse_target!"
            call :RenderDynamic
        )
        if /i not "!room_overlay_mode!"=="scene_ack" if /i not "!room_overlay_mode!"=="leave_confirm" if /i not "!room_overlay_mode!"=="pause_menu" (
            call :InspectCurrent
            if "!room_exit_confirmed!"=="1" set "pick=LEAVE_ACCEPT"
        )
        set /a last_bridge_left_signal=left_signal
        exit /b 0
    )
    if not "!current_spot!"=="!mouse_target!" (
        set "prev_spot=!current_spot!"
        set "current_spot=!mouse_target!"
        call :PlayHoverSE
        call :RenderDynamic
    )
)
set /a mouse_signal=0
for %%V in (!M_A! !M_B! !M_C! !M_D!) do (
    if not "%%~V"=="" if %%~V NEQ 0 set /a mouse_signal=1
)
if !mouse_signal! NEQ 0 if !last_bridge_mouse_signal! EQU 0 (
    if /i not "!room_overlay_mode!"=="scene_ack" if /i not "!room_overlay_mode!"=="leave_confirm" if /i not "!room_overlay_mode!"=="pause_menu" (
        rem legacy button edge fallback
    )
)
set /a last_bridge_left_signal=left_signal
set /a last_bridge_mouse_signal=mouse_signal
exit /b 0

:HandleBridgeKeyEvent
if "!KEY!"=="0" exit /b 0
if not "!K_DOWN!"=="1" exit /b 0
if /i "!room_overlay_mode!"=="pause_menu" (
    if "!KEY!"=="80" set "pick=PAUSE_RESUME"
    if "!KEY!"=="112" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    if "!KEY!"=="81" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    if "!KEY!"=="113" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    if "!KEY!"=="27" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    if "!KEY!"=="88" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    if "!KEY!"=="120" if "!pick!"=="0" set "pick=PAUSE_RESUME"
    exit /b 0
)
if /i "!room_overlay_mode!"=="scene_ack" (
    if "!KEY!"=="32" set "pick=SCENE_ACK"
    if "!KEY!"=="13" if "!pick!"=="0" set "pick=SCENE_ACK"
    if "!KEY!"=="70" if "!pick!"=="0" set "pick=SCENE_ACK"
    if "!KEY!"=="102" if "!pick!"=="0" set "pick=SCENE_ACK"
    if "!KEY!"=="27" if "!pick!"=="0" set "pick=SCENE_ACK"
    if "!KEY!"=="112" if "!pick!"=="0" set "pick=SCENE_ACK"
    if "!KEY!"=="25" if "!pick!"=="0" set "pick=SCENE_ACK"
    exit /b 0
)
if /i "!room_overlay_mode!"=="leave_confirm" (
    if "!KEY!"=="70" set "pick=LEAVE_ACCEPT"
    if "!KEY!"=="102" set "pick=LEAVE_ACCEPT"
    if "!KEY!"=="13" if "!pick!"=="0" set "pick=LEAVE_ACCEPT"
    if "!KEY!"=="81" if "!pick!"=="0" set "pick=LEAVE_CANCEL"
    if "!KEY!"=="113" if "!pick!"=="0" set "pick=LEAVE_CANCEL"
    if "!KEY!"=="27" if "!pick!"=="0" set "pick=LEAVE_CANCEL"
    exit /b 0
)
if "!KEY!"=="87" set "pick=1"
if "!KEY!"=="119" set "pick=1"
if "!KEY!"=="72" set "pick=1"
if "!KEY!"=="65" set "pick=2"
if "!KEY!"=="97" set "pick=2"
if "!KEY!"=="75" if "!pick!"=="0" set "pick=2"
if "!KEY!"=="83" set "pick=3"
if "!KEY!"=="115" set "pick=3"
if "!KEY!"=="80" if "!pick!"=="0" set "pick=3"
if "!KEY!"=="68" set "pick=4"
if "!KEY!"=="100" set "pick=4"
if "!KEY!"=="77" if "!pick!"=="0" set "pick=4"
if "!KEY!"=="70" set "pick=5"
if "!KEY!"=="102" set "pick=5"
if "!KEY!"=="13" if "!pick!"=="0" set "pick=5"
if "!KEY!"=="28" if "!pick!"=="0" set "pick=5"
if "!KEY!"=="27" set "pick=PAUSE"
if "!KEY!"=="112" if "!pick!"=="0" set "pick=PAUSE"
if "!KEY!"=="25" if "!pick!"=="0" set "pick=PAUSE"
exit /b 0

:AppendRoomInputLog
if !room_input_log_count! GEQ 400 exit /b 0
if /i "%~1"=="RAW" (
    >> "%ROOM_INPUT_LOG%" echo %date% %time% ^| RAW ^| !INPUT!
) else (
    >> "%ROOM_INPUT_LOG%" echo %date% %time% ^| %*
)
set /a room_input_log_count+=1
exit /b 0

:HandleMouseClick
call "%tools_dir%\cmdwiz.exe" getmouse 0 >nul 2>&1
set "mouse_code=%errorlevel%"
if "%mouse_code%"=="-1" exit /b 0
set /a "mouse_x=(mouse_code >> 10) & 2047"
set /a "mouse_y=(mouse_code >> 21) & 1023"
set /a "mouse_left_click=mouse_code & 2"
if "%mouse_left_click%"=="0" exit /b 0
set "mouse_target="
call :FindSpotUnderMouse %mouse_x% %mouse_y%
if defined mouse_target (
    if not "%current_spot%"=="%mouse_target%" (
        set "prev_spot=%current_spot%"
        set "current_spot=%mouse_target%"
        call :PlayHoverSE
        call :RenderDynamic
    )
    set "pick=5"
)
exit /b 0

:FindSpotUnderMouse
setlocal EnableDelayedExpansion
set "mouse_target="
set /a "mx=%~1"
set /a "my=%~2"
for /l %%i in (1,1,%spot_count%) do (
    call set "spot_page=%%spot_page_%%i%%%"
    if /i "!spot_page!"=="%current_page%" (
        call set /a sx=%%spot_x_%%i%%%
        call set /a sy=%%spot_y_%%i%%%
        call set /a sw=%%spot_hit_w_%%i%%%
        call set /a sh=%%spot_hit_h_%%i%%%
        if !sw! LSS 1 set "sw=1"
        if !sh! LSS 1 set "sh=1"
        set /a "left=sx - (sw / 2)"
        set /a "right=sx + (sw / 2)"
        set /a "top=sy - (sh / 2)"
        set /a "bottom=sy + (sh / 2)"
        set /a inside_x=0
        set /a inside_y=0
        if !mx! GEQ !left! if !mx! LEQ !right! set /a inside_x=1
        if !my! GEQ !top! if !my! LEQ !bottom! set /a inside_y=1
        if !inside_x! EQU 1 if !inside_y! EQU 1 (
            set "mouse_target=%%i"
            goto :FindSpotUnderMouseDone
        )
    )
)
:FindSpotUnderMouseDone
endlocal & set "mouse_target=%mouse_target%"
exit /b 0

:LoadLayout
if not exist "%ROOM_LAYOUT_FILE%" (
    echo Missing room layout file: "%ROOM_LAYOUT_FILE%"
    exit /b 1
)
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
%tools_dir%\cmdbkg.exe "%ROOM_BG_FILE%" /b <nul >nul 2>&1
set "LAST_ROOM_BG=%ROOM_BG_FILE%"
exit /b 0

:MoveUp
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_up_%current_spot%%%"
if not defined current_spot set "current_spot=%prev_spot%"
call :PlayHoverSE
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveDown
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_down_%current_spot%%%"
if not defined current_spot set "current_spot=%prev_spot%"
call :PlayHoverSE
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveLeft
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_left_%current_spot%%%"
if not defined current_spot set "current_spot=%prev_spot%"
call :PlayHoverSE
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveRight
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_right_%current_spot%%%"
if not defined current_spot set "current_spot=%prev_spot%"
call :PlayHoverSE
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:PlayHoverSE
if "%prev_spot%"=="%current_spot%" exit /b 0
if not exist "%ROOM_HOVER_SE%" exit /b 0
call "%src_audio_dir%\Play_SE.bat" "%ROOM_HOVER_SE%"
exit /b 0

:EnterBridgePause
set "room_overlay_mode=pause_menu"
call :DrawBridgePause
set "last_bridge_mouse_signal=0"
set "last_bridge_left_signal=0"
exit /b 0

:ResumeBridgePause
set "room_overlay_mode="
call :ApplyCurrentBackground
call :RenderStatic
set "prev_spot=0"
set "last_bridge_mouse_signal=0"
set "last_bridge_left_signal=0"
call :RenderDynamic
exit /b 0

:DrawBridgePause
<nul set /p="%ESC%[58;28H%ESC%[0K%ESC%[93mPAUSED%ESC%[0m"
<nul set /p="%ESC%[59;28H%ESC%[0K%ESC%[90mP/Q/Esc/X: resume%ESC%[0m"
<nul set /p="%ESC%[60;28H%ESC%[0K%ESC%[90mBridge mode uses an internal pause handler.%ESC%[0m"
exit /b 0

:AnimateMove
setlocal EnableDelayedExpansion
set "from=%~1"
set "to=%~2"
if "%from%"=="%to%" exit /b 0
call set /a ox=%%spot_x_%from%%%
call set /a oy=%%spot_y_%from%%%
call set /a nx=%%spot_x_%to%%%
call set /a ny=%%spot_y_%to%%%
set /a dx=nx-ox
set /a dy=ny-oy
set "lastx="
set "lasty="
for /l %%s in (1,1,3) do (
    set /a tx=ox + dx * %%s / 4
    set /a ty=oy + dy * %%s / 4
    if defined lastx <nul set /p="%ESC%[!lasty!;!lastx!H "
    <nul set /p="%ESC%[!ty!;!tx!H%ESC%[96m•%ESC%[0m"
    if /i "%ROOM_INPUT_MODE%"=="bridge" (
        %tools_dir%\cmdwiz.exe delay 8 >nul 2>&1
    ) else (
        %tools_dir%\cmdwiz.exe delay 24 >nul 2>&1
    )
    set "lastx=!tx!"
    set "lasty=!ty!"
)
if defined lastx <nul set /p="%ESC%[!lasty!;!lastx!H "
endlocal
exit /b 0

:InspectCurrent
call set "action=%%spot_action_%current_spot%%%"
call set "target=%%spot_target_%current_spot%%%"
call set "scene_file=%%spot_scene_%current_spot%%%"
call set "spot_id=%%spot_id_%current_spot%%%"
if /i "%action%"=="page" (
    if defined target (
        set "prev_spot=0"
        set "current_spot=%target%"
        call :SetCurrentPageFromSpot %target%
        call :ApplyCurrentBackground
        call :RenderStatic
        set "last_bridge_mouse_signal=0"
        call :RenderDynamic
    )
    exit /b 0
)
if /i "%action%"=="exit" (
    call :TryLeaveRoom
    exit /b 0
)
if /i "%action%"=="scene" (
    call set "seen_value=%%chapter01_room_seen_%spot_id%%%"
    if not defined seen_value set "chapter01_room_seen_%spot_id%=1"
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
    call :Display
    call :Scene "%scene_file%"
    <nul set /p="%ESC%[65;86H%ESC%[90m何かキーを押して自室探索に戻る%ESC%[0m"
    if /i "%ROOM_INPUT_MODE%"=="bridge" (
        set "room_overlay_mode=scene_ack"
    ) else (
        set "LAST_ROOM_BG="
        "%tools_dir%\cmdwiz.exe" getch >nul 2>&1
        call :ApplyCurrentBackground
        call :RenderStatic
        set "prev_spot=0"
        set "last_bridge_mouse_signal=0"
        call :RenderDynamic
    )
    exit /b 0
)
exit /b 0

:TryLeaveRoom
set "room_exit_confirmed=0"
call :DrawLeaveConfirm
if /i "%ROOM_INPUT_MODE%"=="bridge" (
    set "room_overlay_mode=leave_confirm"
    exit /b 0
)
choice /c FQ /n >nul
if "%errorlevel%"=="2" (
    call :CancelLeaveConfirm
    exit /b 0
)
call :AcceptLeaveConfirm
exit /b 0

:FinishSceneAck
set "room_overlay_mode="
set "LAST_ROOM_BG="
call :ApplyCurrentBackground
call :RenderStatic
set "prev_spot=0"
set "last_bridge_mouse_signal=0"
call :RenderDynamic
exit /b 0

:CancelLeaveConfirm
set "room_overlay_mode="
call :ClearLeaveConfirm
call :RenderDynamic
exit /b 0

:AcceptLeaveConfirm
set "room_overlay_mode="
call :ClearLeaveConfirm
set "room_exit_confirmed=1"
exit /b 0

:DrawLeaveConfirm
<nul set /p="%ESC%[12;154H%ESC%[90m< 階下へ向かいますか？ [F/Q]%ESC%[0m"
exit /b 0

:ClearLeaveConfirm
<nul set /p="%ESC%[12;154H                                      %ESC%[12;194H"
exit /b 0

:RenderStatic
call :Display
for /l %%i in (1,1,%spot_count%) do (
    call set "spot_page=%%spot_page_%%i%%%"
    if /i "!spot_page!"=="%current_page%" call :DrawSpot %%i
)
exit /b 0

:RenderDynamic
if not "%prev_spot%"=="0" call :DrawSpot %prev_spot%
call :DrawSpot %current_spot%
call :DrawExploreStatus
call :DrawObjectivePanel
call :DrawExploreFooter
exit /b 0

:DrawSpot
setlocal EnableDelayedExpansion
set "idx=%~1"
call set "spot_page=%%spot_page_%idx%%%"
if /i not "!spot_page!"=="%current_page%" exit /b 0
call set "sx=%%spot_x_%idx%%%"
call set "sy=%%spot_y_%idx%%%"
call set "spot_id=%%spot_id_%idx%%%"
call set "marker_type=%%spot_marker_%idx%%%"
call set "seen=%%chapter01_room_seen_!spot_id!%%"
set "mark_color=%ESC%[90m"
call :ResolveMarker "!marker_type!" normal mark
if defined seen set "mark_color=%ESC%[92m"
if "%idx%"=="%current_spot%" (
    set "mark_color=%ESC%[96m"
    call :ResolveMarker "!marker_type!" active mark
)
set /a draw_x=sx-1
<nul set /p="%ESC%[!sy!;!draw_x!H!mark_color!!mark!%ESC%[0m"
endlocal
exit /b 0

:ResolveMarker
setlocal
set "marker_type=%~1"
set "variant=%~2"
set "mark= ◇ "
if /i "%marker_type%"=="nav_right" set "mark= > "
if /i "%marker_type%"=="nav_left" set "mark= < "
if /i "%marker_type%"=="door" set "mark= □ "
if /i "%variant%"=="active" (
    if /i "%marker_type%"=="diamond" set "mark=[◇]"
    if /i "%marker_type%"=="nav_right" set "mark=[>]"
    if /i "%marker_type%"=="nav_left" set "mark=[<]"
    if /i "%marker_type%"=="door" set "mark=[□]"
)
endlocal & set "%~3=%mark%"
exit /b 0

:DrawExploreStatus
call set "spot_id=%%spot_id_%current_spot%%%"
call :DescribeSpot "%spot_id%"
<nul set /p="%ESC%[59;28H%ESC%[0K%ESC%[93m注目:%ESC%[0m %spot_display_name%"
<nul set /p="%ESC%[60;28H%ESC%[0K%ESC%[90m%spot_display_hint%%ESC%[0m"
<nul set /p="%ESC%[61;28H%ESC%[0K%ESC%[90mFで調べる。左右の矢印で視点を切り替え、扉から階下へ進める。%ESC%[0m"
exit /b 0

:DescribeSpot
set "spot_display_name=%~1"
set "spot_display_hint="
if /i "%~1"=="window" (
    set "spot_display_name=窓"
    set "spot_display_hint=王都の朝が見える。外の空気がもう動き始めている。"
)
if /i "%~1"=="desk" (
    set "spot_display_name=机"
    set "spot_display_hint=教本と書き付けが散らばっている。"
)
if /i "%~1"=="banner" (
    set "spot_display_name=壁掛け"
    set "spot_display_hint=この部屋でいちばん目につく、王国の紋章布だ。"
)
if /i "%~1"=="wood_sword" (
    set "spot_display_name=木剣"
    set "spot_display_hint=壁際に立てかけた、訓練用の木剣だ。"
)
if /i "%~1"=="nav_right" (
    set "spot_display_name=右を見る"
    set "spot_display_hint=寝台と扉のある側へ視界を移す。"
)
if /i "%~1"=="nav_left" (
    set "spot_display_name=左を見る"
    set "spot_display_hint=窓と机のある側へ視界を戻す。"
)
if /i "%~1"=="shelf" (
    set "spot_display_name=本棚"
    set "spot_display_hint=教本や星術書が差してある。"
)
if /i "%~1"=="trunk" (
    set "spot_display_name=装備箱"
    set "spot_display_hint=訓練道具を入れてある箱。"
)
if /i "%~1"=="bed" (
    set "spot_display_name=ベッド"
    set "spot_display_hint=まだ寝直せそうなくらい温かい。"
)
if /i "%~1"=="door" (
    set "spot_display_name=扉"
    set "spot_display_hint=階下へ続く。母さんの声もそちらから聞こえる。"
)
exit /b 0

:DrawExploreFooter
<nul set /p="%ESC%[64;92H%ESC%[0KWASD=移動  F=調べる/選択  Q/Esc=ポーズ%ESC%[0m"
exit /b 0

:DrawObjectivePanel
setlocal
set "objective_right=%CONSOLE_WIDTH%"
if not defined objective_right set "objective_right=%CONSOLE_COLS%"
if not defined objective_right set "objective_right=210"
set /a "objective_left=objective_right-20"
if %objective_left% LSS 158 set "objective_left=158"
<nul set /p="%ESC%[12;%objective_left%H%ESC%[0K%ESC%[93m目標%ESC%[0m"
<nul set /p="%ESC%[13;%objective_left%H%ESC%[0K%ESC%[90m──────────────────%ESC%[0m"
<nul set /p="%ESC%[14;%objective_left%H%ESC%[0K%ESC%[97m支度をして%ESC%[0m"
<nul set /p="%ESC%[15;%objective_left%H%ESC%[0K%ESC%[97m階下へ向かう%ESC%[0m"
<nul set /p="%ESC%[17;%objective_left%H%ESC%[0K%ESC%[90m次の進行%ESC%[0m"
<nul set /p="%ESC%[18;%objective_left%H%ESC%[0K%ESC%[90m──────────────────%ESC%[0m"
<nul set /p="%ESC%[19;%objective_left%H%ESC%[0K%ESC%[96m扉から次の場面へ%ESC%[0m"
<nul set /p="%ESC%[20;%objective_left%H%ESC%[0K%ESC%[96m進める%ESC%[0m"
<nul set /p="%ESC%[22;%objective_left%H%ESC%[0K%ESC%[90m任意確認%ESC%[0m"
<nul set /p="%ESC%[23;%objective_left%H%ESC%[0K%ESC%[90m──────────────────%ESC%[0m"
<nul set /p="%ESC%[24;%objective_left%H%ESC%[0K%ESC%[37m自室の気になる物を%ESC%[0m"
<nul set /p="%ESC%[25;%objective_left%H%ESC%[0K%ESC%[37m調べる%ESC%[0m"
endlocal
exit /b 0

:Display
cls
if /i "%ROOM_INPUT_MODE%"=="bridge" <nul set /p="%ESC%[1;1H%ESC%[93m[Mouse Test] マウス操作試験実装中%ESC%[0m"
call :DrawDialogueGuide
<nul set /p="%ESC%[64;24H%ESC%[0K"
exit /b 0

:Scene
set "scene_skipped=0"
set "RENDER_BG_T=33"
set "RENDER_BG_PATH="
call :DrawTextInputGuide
for /f "eol=# usebackq delims=" %%L in ("%ROOM_TEXT_DIR%\%~1") do (
    if "!SCENARIO_SKIP_ACTIVE!"=="1" (
        set "scene_skipped=1"
        goto :scene_skip_break
    )
    set "line=%%L"
    call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!line!"
    echo !line! | findstr /c:"{clear}" /c:"{bg:" /c:"{bg_t:" >nul
    if !errorlevel! == 0 (
        call :DrawDialogueGuide
        call :DrawTextInputGuide
    )
)
:scene_skip_break
set "SCENARIO_SKIP_ACTIVE="
if "%scene_skipped%"=="1" exit /b 8
exit /b 0

:DrawTextInputGuide
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[64;108H%ESC%[90mSpace: 早送り  P/Esc: ポーズ%ESC%[0m"
exit /b 0

:DrawDialogueGuide
<nul set /p="%ESC%[3;101H%ESC%[90m自室の探索%ESC%[0m"
<nul set /p="%ESC%[4;90H%ESC%[0K"
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: %current_location%%ESC%[0m"
<nul set /p="%ESC%[65;174H%ESC%[90mChapter1: 王都に生きる者%ESC%[0m"
exit /b 0

:exit_room
if exist "%RCSU%" call "%RCSU%" -trace INFO Chapter01_RoomExplore "exit normal current_spot=%current_spot%"
if /i "%ROOM_INPUT_MODE%"=="bridge" if defined ROOM_BRIDGE_STOP break > "%ROOM_BRIDGE_STOP%"
if /i "%ROOM_INPUT_MODE%"=="bridge" title input:Q
call "%tools_dir%\cmdwiz.exe" setquickedit 1 >nul 2>&1
endlocal & (
    set "chapter01_room_cleared=1"
)
exit /b 0

:exit_to_title
if /i "%ROOM_INPUT_MODE%"=="bridge" if defined ROOM_BRIDGE_STOP break > "%ROOM_BRIDGE_STOP%"
if /i "%ROOM_INPUT_MODE%"=="bridge" title input:Q
call "%tools_dir%\cmdwiz.exe" setquickedit 1 >nul 2>&1
endlocal
exit /b 641

:exit_game
if /i "%ROOM_INPUT_MODE%"=="bridge" if defined ROOM_BRIDGE_STOP break > "%ROOM_BRIDGE_STOP%"
if /i "%ROOM_INPUT_MODE%"=="bridge" title input:Q
call "%tools_dir%\cmdwiz.exe" setquickedit 1 >nul 2>&1
endlocal
exit /b 642
