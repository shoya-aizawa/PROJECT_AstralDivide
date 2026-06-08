@echo off
chcp 65001 >nul
:: Load static UI profile configurations
if exist "%src_display_tpl_dir%\StaticUIProfileSelector.bat" (
    call "%src_display_tpl_dir%\StaticUIProfileSelector.bat"
)
rem call "%tools_dir%\cmdwiz.exe" setfont "%tools_dir%\Consolas.fnt"
if not defined DEBUG_STATE set DEBUG_STATE=0
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if exist "%RCSU%" call "%RCSU%" -trace INFO MMM "start quality=%RENDER_QUALITY% debug=%DEBUG_STATE%"

if "%DEBUG_STATE%"=="1" (
    echo %esc%[K%esc%[93m [DEBUG-MMM] MMM Starting: DEBUG_STATE=%DEBUG_STATE% %esc%[0m
    timeout /t 2 >nul
)


:: ========== Debug Initialization ==========

:: Initialize key log storage.
set key_log_count=0
set key_log_line_1=
set key_log_line_2=
set key_log_line_3=
set key_log_line_4=
set key_log_line_5=



:: ========== State Initialization ==========

set UI_ACTION=
set UI_PARAM=

set current_selected_menu=1

set max_menu_items=4

if not defined RENDER_QUALITY set "RENDER_QUALITY=HIGH"
if not defined MENU_BOX_INNER_WIDTH set "MENU_BOX_INNER_WIDTH=20"
if not defined MMM_ANCHOR_COL set "MMM_ANCHOR_COL=1"
if not defined MMM_ANCHOR_ROW set "MMM_ANCHOR_ROW=1"
if not defined MMM_USE_DYNAMIC set "MMM_USE_DYNAMIC=0"

:: Set default colors by render quality.
if /i "%RENDER_QUALITY%"=="LOW" (
    set color_selected=7
    set color_available=7
    set color_unavailable=90
    set color_normal=0
) else if /i "%RENDER_QUALITY%"=="MIDDLE" (
    set color_selected=30;47
    set color_available=36
    set color_unavailable=90
    set color_normal=0
) else (
    set color_selected=30;46
    set color_available=96
    set color_unavailable=90
    set color_normal=0
)









:: ========== Main Loop ==========

:MainMenuLoop
    call :Initialize_Menu_Colors
    call :Display_MainMenu

:MenuInputLoop
    call :Update_Menu_Colors
    call :Quick_Update_Display
    call :GetChoice
    call :HandleKey %choice%
    if defined UI_ACTION (
        if "%DEBUG_STATE%"=="1" (
            echo %esc%[10;2H%esc%[K%esc%[91m[DEBUG-MMM] UI_ACTION: %UI_ACTION% %esc%[0m
            timeout /t 1 >nul
        )
        exit /b %RC_OK%
    )
    goto :MenuInputLoop































:: ========== Color Control ==========

:Initialize_Menu_Colors
    :: Reset all menu item colors to the available state.
    set menu_1_color=%color_available%
    set menu_2_color=%color_available%
    set menu_3_color=%color_available%
    set menu_4_color=%color_available%

    :: Highlight the first menu item by default.
    set menu_1_color=%color_selected%
    exit /b 0

:Update_Menu_Colors
    :: Reset all menu colors before applying selection state.
    set menu_1_color=%color_available%
    set menu_2_color=%color_available%
    set menu_3_color=%color_unavailable%
    set menu_4_color=%color_available%

    :: Apply the selected color to the active menu item.
    if "%current_selected_menu%"=="1" set menu_1_color=%color_selected%
    if "%current_selected_menu%"=="2" set menu_2_color=%color_selected%
    if "%current_selected_menu%"=="3" set menu_3_color=%color_selected%
    if "%current_selected_menu%"=="4" set menu_4_color=%color_selected%
    exit /b 0

:: ========== Main Menu Rendering ==========

:Display_MainMenu
    :: Clear the screen before drawing the menu.
    cls

    :: Render the menu based on the configured quality profile.
    if "%MMM_USE_DYNAMIC%"=="1" (
        call :Render_MainMenu_Dynamic
    ) else if /i "%RENDER_QUALITY%"=="LOW" (
        :: LOW: Load single-border static fallback template
        call :Render_Template_Anchored "%src_display_tpl_dir%\MainMenuDisplay_LOW.txt" %MMM_ANCHOR_COL% %MMM_ANCHOR_ROW%
    ) else (
        :: HIGH / MIDDLE: Load high-quality static templates (pre-rendered AA and borders)
        call :Render_Template_Anchored "%src_display_tpl_dir%\MainMenuDisplay_%RENDER_QUALITY%.txt" %MMM_ANCHOR_COL% %MMM_ANCHOR_ROW%
    )

    if "%DEBUG_STATE%"=="1" (
        :: Show the debug mode banner.
        echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m

        :: Draw the debug overlay after the first initialization pass.
        if not defined debug_initialized (
            call :Display_Debug_Info
            set debug_initialized=1
        )
        call :Display_Debug_Info
    ) else (
        set debug_initialized=
    )
    exit /b 0

:: ========== Key Input ==========

:GetChoice
    choice /n /c ABCDEFGHIJKLMNOPQRSTUVWXYZ >nul
    set choice=%errorlevel%
    exit /b 0

:: ========== Key Handling ==========

:HandleKey
    set key=%1
    call :Process_Common_Key_Tasks %key%
    call :Execute_Key_Action %key%
    if defined UI_ACTION exit /b 0
    exit /b 0

:Process_Common_Key_Tasks
    set key=%1
    if "%DEBUG_STATE%"=="1" (
        call :Add_Key_Log %key%
    )
    exit /b 0

:Execute_Key_Action
    set key=%1
    
    :: Handle the primary select key.
    if %key%==6 call :Handle_Select
    if defined UI_ACTION (exit /b 0)

    :: Ignore invalid lateral keys.
    if %key%==1 call :Handle_Invalid_Key %key%
    if %key%==4 call :Handle_Invalid_Key_With_Sequence %key%

    :: Handle vertical menu movement.
    if %key%==19 call :Handle_Move_Down
    if %key%==23 call :Handle_Move_Up

    :: Hidden debug commands were removed intentionally.
    call :Handle_Hidden_Sequence_Key %key%

    :: WIP keys remain disabled.
    call :Handle_WIP_Key %key%

    exit /b 0


:Handle_Select
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav" >nul 2>&1
    if "%DEBUG_STATE%"=="1" (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )
    :: Set UI_ACTION for the selected menu item.
    if "%current_selected_menu%"=="1" set "UI_ACTION=MAINMENU_NEWGAME"
    if "%current_selected_menu%"=="2" set "UI_ACTION=MAINMENU_CONTINUE"
    if "%current_selected_menu%"=="3" set "UI_ACTION=MAINMENU_SETTINGS"
    if "%current_selected_menu%"=="4" set "UI_ACTION=EXIT"
    if exist "%RCSU%" call "%RCSU%" -trace INFO MMM "select menu=%current_selected_menu% action=%UI_ACTION%"
    if "%DEBUG_STATE%"=="1" (
        echo %esc%[8;1H%esc%[K%esc%[91m [DEBUG-MMM] Handle_Select: Menu=%current_selected_menu% UI_ACTION=%UI_ACTION% %esc%[0m
        echo %esc%[9;1H%esc%[K%esc%[93m [DEBUG-MMM] About to exit with code: 0 %esc%[0m
        timeout /t 2 >nul
    )
    exit /b 0

:Handle_Move_Down
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav" >nul 2>&1
    call :Move_Down
    exit /b 0

:Handle_Move_Up
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav" >nul 2>&1
    call :Move_Up
    exit /b 0

:Handle_Invalid_Key
    set key_name=%~1
    :: Ignore invalid lateral keys.
    exit /b 0
:Handle_Invalid_Key_With_Sequence
    set key_name=%~1
    :: Hidden sequence handling was removed intentionally.
    exit /b 0

:Handle_Hidden_Sequence_Key
    :: Hidden debug commands were removed intentionally.
    exit /b 0

:Handle_WIP_Key
    set key=%1
    :: WIP keys remain disabled.
    exit /b 0

:: ========== Quick Display Update ==========

:Quick_Update_Display
    setlocal EnableDelayedExpansion
    set /a "menu_col=%MENU_POS_COL% + %MMM_ANCHOR_COL% - 1"
    set /a "menu_row_1=%MENU_POS_ROW_1% + %MMM_ANCHOR_ROW% - 1"
    set /a "menu_row_2=%MENU_POS_ROW_2% + %MMM_ANCHOR_ROW% - 1"
    set /a "menu_row_3=%MENU_POS_ROW_3% + %MMM_ANCHOR_ROW% - 1"
    set /a "menu_row_4=%MENU_POS_ROW_4% + %MMM_ANCHOR_ROW% - 1"
    set "menu_1_text=      New Game      "
    set "menu_2_text=      Continue      "
    set "menu_3_text=      Settings      "
    set "menu_4_text=        Quit        "
    echo !esc![!menu_row_1!;!menu_col!H!esc![%menu_1_color%m!menu_1_text:~0,%MENU_BOX_INNER_WIDTH%!!esc![0m
    echo !esc![!menu_row_2!;!menu_col!H!esc![%menu_2_color%m!menu_2_text:~0,%MENU_BOX_INNER_WIDTH%!!esc![0m
    echo !esc![!menu_row_3!;!menu_col!H!esc![%menu_3_color%m!menu_3_text:~0,%MENU_BOX_INNER_WIDTH%!!esc![0m
    echo !esc![!menu_row_4!;!menu_col!H!esc![%menu_4_color%m!menu_4_text:~0,%MENU_BOX_INNER_WIDTH%!!esc![0m
    endlocal
    if "%DEBUG_STATE%"=="1" (
        call :Update_All_Debug_Info
    )
    exit /b 0

:Render_Template_Anchored
    setlocal EnableDelayedExpansion
    set "template_file=%~1"
    set "anchor_col=%~2"
    set "anchor_row=%~3"
    if not defined anchor_col set "anchor_col=1"
    if not defined anchor_row set "anchor_row=1"
    set /a "pad_cols=anchor_col-1"
    set /a "pad_rows=anchor_row-1"
    set "spacer=                                                                                                                                                                                                                                                                                                                                "
    set "prefix=!spacer:~0,%pad_cols%!"
    for /l %%r in (1,1,!pad_rows!) do echo.
    for /f "usebackq delims= eol=#" %%a in ("!template_file!") do echo(!prefix!%%a
    endlocal
    exit /b 0

:Render_MainMenu_Dynamic
    setlocal EnableDelayedExpansion
    call :Draw_Box %MMM_FRAME_LEFT% %MMM_FRAME_TOP% %MMM_FRAME_RIGHT% %MMM_FRAME_BOTTOM%
    call :Print_Centered %MMM_TITLE_ROW% "ASTRAL DIVIDE"
    call :Print_Centered %MMM_SUBTITLE_ROW_1% "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    call :Print_Centered %MMM_SUBTITLE_ROW_2% "~ The Ones Who Sever the Stars ~"
    call :Print_Centered %MMM_SUBTITLE_ROW_3% "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    call :Draw_Box %MMM_MENU_BOX_LEFT% %MMM_MENU_BOX_TOP% %MMM_MENU_BOX_RIGHT% %MMM_MENU_BOX_BOTTOM%
    call :Draw_HLine %MMM_MENU_DIVIDER_ROW% %MMM_MENU_DIVIDER_LEFT% %MMM_MENU_DIVIDER_RIGHT% "-"
    call :Draw_Box %MMM_HELP_BOX_LEFT% %MMM_HELP_BOX_TOP% %MMM_HELP_BOX_RIGHT% %MMM_HELP_BOX_BOTTOM%
    echo !esc![%MMM_HELP_TEXT_ROW%;%MMM_HELP_TEXT_COL%HW/S: select  F: enter
    echo !esc![%MMM_FOOTER_ROW_1%;%MMM_FOOTER_LEFT_COL%H%app_title%
    echo !esc![%MMM_FOOTER_ROW_2%;%MMM_FOOTER_LEFT_COL%HVersion: %app_version_display%
    call :Print_Right %MMM_FOOTER_ROW_1% %MMM_FRAME_RIGHT% "Developed by HedgeHogSoft"
    call :Print_Right %MMM_FOOTER_ROW_2% %MMM_FRAME_RIGHT% "(c) 2024-2025 RPGGAME."
    endlocal
    exit /b 0

:Draw_Box
    setlocal EnableDelayedExpansion
    set "left=%~1"
    set "top=%~2"
    set "right=%~3"
    set "bottom=%~4"
    set /a "inner_width=right-left-1"
    set /a "inner_top=top+1"
    set /a "inner_bottom=bottom-1"
    set "line="
    for /l %%i in (1,1,!inner_width!) do set "line=!line!-"
    echo !esc![!top!;!left!H+!line!+
    for /l %%r in (!inner_top!,1,!inner_bottom!) do echo !esc![%%r;!left!H^|!esc![%%r;!right!H^|
    echo !esc![!bottom!;!left!H+!line!+
    endlocal
    exit /b 0

:Draw_HLine
    setlocal EnableDelayedExpansion
    set "row=%~1"
    set "left=%~2"
    set "right=%~3"
    set "char=%~4"
    if "%char%"=="" set "char=-"
    set /a "width=right-left+1"
    set "line="
    for /l %%i in (1,1,!width!) do set "line=!line!!char!"
    echo !esc![!row!;!left!H!line!
    endlocal
    exit /b 0

:Print_Centered
    setlocal EnableDelayedExpansion
    set "row=%~1"
    set "text=%~2"
    call :StrLen text text_len
    set /a "col=((%CONSOLE_COLS% - text_len) / 2) + 1"
    echo !esc![!row!;!col!H!text!
    endlocal
    exit /b 0

:Print_Right
    setlocal EnableDelayedExpansion
    set "row=%~1"
    set "right=%~2"
    set "text=%~3"
    call :StrLen text text_len
    set /a "col=right-text_len"
    if !col! LSS 1 set /a "col=1"
    echo !esc![!row!;!col!H!text!
    endlocal
    exit /b 0

:StrLen
    setlocal EnableDelayedExpansion
    set "s=!%~1!"
    set /a len=0
    :StrLenLoop
    if defined s (
        set "s=!s:~1!"
        set /a len+=1
        goto StrLenLoop
    )
    endlocal & set "%~2=%len%"
    exit /b 0

:Update_All_Debug_Info
    call :Render_Debug_Overlay
    exit /b 0
    echo %esc%[1;1H%esc%[K
    echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m
    
    :: Update the clock used by the debug overlay.
    set current_time=%time:~0,8%
    echo %esc%[2;1H%esc%[K%esc%[93m [%current_time%] Menu: %current_selected_menu%/%max_menu_items% LastKey: %key% %esc%[0m
    echo %esc%[3;1H%esc%[K%esc%[96m Available: %max_menu_items% KeyCount: %key_log_count% %esc%[0m
    echo %esc%[4;1H%esc%[K%esc%[97m DebugState: %DEBUG_STATE% Overlay: ACTIVE %esc%[0m

    :: Build a compact status summary for the current menu state.
    set status_line=
    if "%current_selected_menu%"=="1" set status_line=[*1][ 2][ 3][ 4]
    if "%current_selected_menu%"=="2" set status_line=[ 1][*2][ 3][ 4]
    if "%current_selected_menu%"=="3" set status_line=[ 1][ 2][*3][ 4]
    if "%current_selected_menu%"=="4" set status_line=[ 1][ 2][ 3][*4]

    echo %esc%[5;1H%esc%[K%esc%[95m MenuItems: %status_line% %esc%[0m
    echo %esc%[6;1H%esc%[K%esc%[94m Commands: W/S=Move F=Select %esc%[0m

    echo %esc%[8;1H%esc%[K%esc%[93m Overlay: simplified %esc%[0m

    :: Redraw the key history area.
    echo %esc%[20;1H%esc%[K%esc%[90m Key History (MainMenuModule): %esc%[0m
    echo %esc%[21;1H%esc%[K
    echo %esc%[22;1H%esc%[K
    echo %esc%[23;1H%esc%[K
    echo %esc%[24;1H%esc%[K
    echo %esc%[25;1H%esc%[K
    if defined key_log_line_1 echo %esc%[21;1H%esc%[97m %key_log_line_1% %esc%[0m
    if defined key_log_line_2 echo %esc%[22;1H%esc%[37m %key_log_line_2% %esc%[0m
    if defined key_log_line_3 echo %esc%[23;1H%esc%[37m %key_log_line_3% %esc%[0m
    if defined key_log_line_4 echo %esc%[24;1H%esc%[37m %key_log_line_4% %esc%[0m
    if defined key_log_line_5 echo %esc%[25;1H%esc%[37m %key_log_line_5% %esc%[0m

    exit /b 0

:Display_Debug_Info
    call :Render_Debug_Overlay
    exit /b 0
    set current_time=%time:~0,8%

    :: Draw the debug banner and current state lines.
    echo %esc%[1;1H%esc%[K
    echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m

    :: Display the current menu state, key, and counts.
    echo %esc%[2;1H%esc%[93m [%current_time%] Menu: %current_selected_menu%/%max_menu_items% LastKey: %key% %esc%[0m
    echo %esc%[3;1H%esc%[96m Available: %max_menu_items% KeyCount: %key_log_count% %esc%[0m
    echo %esc%[4;1H%esc%[K%esc%[97m DebugState: %DEBUG_STATE% Overlay: ACTIVE %esc%[0m

    :: Build a compact status summary for the current menu state.
    set status_line=
    if "%current_selected_menu%"=="1" set status_line=[*1][ 2][ 3][ 4]
    if "%current_selected_menu%"=="2" set status_line=[ 1][*2][ 3][ 4]
    if "%current_selected_menu%"=="3" set status_line=[ 1][ 2][*3][ 4]
    if "%current_selected_menu%"=="4" set status_line=[ 1][ 2][ 3][*4]

    echo %esc%[5;1H%esc%[95m MenuItems: %status_line% %esc%[0m
    echo %esc%[6;1H%esc%[94m Commands: W/S=Move F=Select %esc%[0m

    echo %esc%[8;1H%esc%[93m Overlay: simplified %esc%[0m

    :: Draw the key history block.
    echo %esc%[20;1H%esc%[90m Key History (MainMenuModule): %esc%[0m
    echo %esc%[21;1H%esc%[37m %esc%[0m
    echo %esc%[22;1H%esc%[37m %esc%[0m
    echo %esc%[23;1H%esc%[37m %esc%[0m
    echo %esc%[24;1H%esc%[37m %esc%[0m
    echo %esc%[25;1H%esc%[37m %esc%[0m

    exit /b 0

:Clear_Debug_Info
    :: Clear the debug area line by line.
    for /l %%i in (1,1,30) do (
        echo %esc%[%%i;1H%esc%[K
    )

    :: Reset key log buffers.
    set key_log_count=
    set key_log_line_1=
    set key_log_line_2=
    set key_log_line_3=
    set key_log_line_4=
    set key_log_line_5=

    exit /b 0

:Render_Debug_Overlay
    setlocal EnableDelayedExpansion
    set /a "dbg_col=%MMM_ANCHOR_COL% + 2"
    set /a "dbg_row=%MMM_ANCHOR_ROW% + 1"
    set /a "dbg_row_2=dbg_row+1"
    set /a "dbg_row_3=dbg_row+2"
    set /a "dbg_row_4=dbg_row+3"
    set /a "dbg_row_5=dbg_row+4"
    echo !esc![!dbg_row!;!dbg_col!H!esc![48;5;235m!esc![38;5;220m MMM DEBUG                     !esc![0m
    echo !esc![!dbg_row_2!;!dbg_col!H!esc![48;5;235m sel=!current_selected_menu! key=!key!             !esc![0m
    echo !esc![!dbg_row_3!;!dbg_col!H!esc![48;5;235m debug overlay active       !esc![0m
    echo !esc![!dbg_row_4!;!dbg_col!H!esc![48;5;235m anc=!MMM_ANCHOR_COL!,!MMM_ANCHOR_ROW!                    !esc![0m
    echo !esc![!dbg_row_5!;!dbg_col!H!esc![48;5;235m act=!UI_ACTION!                        !esc![0m
    endlocal
    exit /b 0


:Add_Key_Log
    set key_pressed=%1
    set /a key_log_count+=1

    :: Capture the current timestamp for the key history.
    set current_time=%time:~0,8%

    :: Map the pressed key to a readable label.
    set key_name=UNKNOWN
    if "%key_pressed%"=="1" set key_name=A(LEFT-INVALID)
    if "%key_pressed%"=="2" set key_name=B
    if "%key_pressed%"=="3" set key_name=C
    if "%key_pressed%"=="4" set key_name=D(RIGHT-INVALID)
    if "%key_pressed%"=="5" set key_name=E(WIP)
    if "%key_pressed%"=="6" set key_name=F(SELECT)
    if "%key_pressed%"=="7" set key_name=G(WIP)
    if "%key_pressed%"=="8" set key_name=H(WIP)
    if "%key_pressed%"=="9" set key_name=I
    if "%key_pressed%"=="10" set key_name=J(WIP)
    if "%key_pressed%"=="11" set key_name=K
    if "%key_pressed%"=="12" set key_name=L(WIP)
    if "%key_pressed%"=="13" set key_name=M(WIP)
    if "%key_pressed%"=="14" set key_name=N(WIP)
    if "%key_pressed%"=="15" set key_name=O
    if "%key_pressed%"=="16" set key_name=P
    if "%key_pressed%"=="17" set key_name=Q(WIP)
    if "%key_pressed%"=="18" set key_name=R
    if "%key_pressed%"=="19" set key_name=S(DOWN)
    if "%key_pressed%"=="20" set key_name=T(WIP)
    if "%key_pressed%"=="21" set key_name=U(WIP)
    if "%key_pressed%"=="22" set key_name=V(WIP)
    if "%key_pressed%"=="23" set key_name=W(UP)
    if "%key_pressed%"=="24" set key_name=X
    if "%key_pressed%"=="25" set key_name=Y
    if "%key_pressed%"=="26" set key_name=Z
    if "%key_pressed%"=="UNKNOWN_KEY" set key_name=(UNKNOWN)

    :: Keep the most recent five key log entries.
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=[%current_time%] #%key_log_count% %key_name% - Menu:%current_selected_menu%

    exit /b 0

:Refresh_Display
    :: Redraw the screen.
    cls
    call :Display_MainMenu
    exit /b 0

:: ========== Color Theme Helpers ==========

:Set_Color_Theme
    if "%1"=="classic" (
        set color_selected=7
        set color_available=32
        set color_unavailable=90
        set color_normal=0
    )
    if "%1"=="modern" (
        set color_selected=112
        set color_available=96
        set color_unavailable=8
        set color_normal=0
    )
    if "%1"=="neon" (
        set color_selected=207
        set color_available=51
        set color_unavailable=8
        set color_normal=0
    )

    call :Initialize_Menu_Colors
    exit /b 0

:: ========== Menu Availability ==========

:Set_Menu_Availability
    :: Arguments: menu number and availability state.
    set menu_num=%1
    set availability=%2

    if "%availability%"=="unavailable" (
        if "%menu_num%"=="1" set menu_1_base_color=%color_unavailable%
        if "%menu_num%"=="2" set menu_2_base_color=%color_unavailable%
        if "%menu_num%"=="3" set menu_3_base_color=%color_unavailable%
        if "%menu_num%"=="4" set menu_4_base_color=%color_unavailable%
    ) else (
        if "%menu_num%"=="1" set menu_1_base_color=%color_available%
        if "%menu_num%"=="2" set menu_2_base_color=%color_available%
        if "%menu_num%"=="3" set menu_3_base_color=%color_available%
        if "%menu_num%"=="4" set menu_4_base_color=%color_available%
    )

    call :Update_Menu_Colors
    exit /b 0

:: ========== Menu Navigation ==========

:Move_Up
    set /a new_menu=%current_selected_menu% - 1
    if %new_menu% lss 1 set new_menu=%max_menu_items%
    set current_selected_menu=%new_menu%
    call :Update_Menu_Colors
    call :Quick_Update_Display
    exit /b 0

:Move_Left
    exit /b 0

:Move_Down
    set /a new_menu=%current_selected_menu% + 1
    if %new_menu% gtr %max_menu_items% set new_menu=1
    set current_selected_menu=%new_menu%
    call :Update_Menu_Colors
    call :Quick_Update_Display
    exit /b 0

:Move_Right
    exit /b 0

:: ========== Errorlevel Helper Functions ==========

