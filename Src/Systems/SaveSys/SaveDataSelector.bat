@echo off
:: Load static UI profile configurations
if exist "%src_display_tpl_dir%\StaticUIProfileSelector.bat" (
    call "%src_display_tpl_dir%\StaticUIProfileSelector.bat"
)
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"


:: Normal initialization and branching
set "selector_mode=%1"
if "%selector_mode%"=="" set "selector_mode=CONTINUE"
if not defined esc for /f "delims=" %%a in ('echo prompt $E^| cmd /d') do set "esc=%%a"
if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "start mode=%selector_mode% quality=%RENDER_QUALITY%"

:: Initialize return value
set retcode=0

:: Inherit debug state
if not defined DEBUG_STATE set DEBUG_STATE=0

:: Initialize key logs
set key_log_count=0
set key_log_line_1=
set key_log_line_2=
set key_log_line_3=
set key_log_line_4=
set key_log_line_5=

:: Initialize the color system
:: Currently selected slots (1-12 compatible, 3 actual operation)

set current_selected_slot=1

:: Initialize return values / actions
set UI_ACTION=
set UI_PARAM=

:: Display settings
set max_available_slots=12
set max_total_slots=12
set slots_per_row=3

:: Default render quality settings
if not defined RENDER_QUALITY set "RENDER_QUALITY=HIGH"
if not defined SLOT_BOX_WIDTH set "SLOT_BOX_WIDTH=22"
if not defined SLOT_ROW_PITCH set "SLOT_ROW_PITCH=9"
if not defined SLOT_TEXT_WIDTH set "SLOT_TEXT_WIDTH=16"
if not defined SDS_ANCHOR_COL set "SDS_ANCHOR_COL=1"
if not defined SDS_ANCHOR_ROW set "SDS_ANCHOR_ROW=1"
if not defined SDS_DIALOG_COL set "SDS_DIALOG_COL=92"
if not defined SDS_DIALOG_ROW set "SDS_DIALOG_ROW=20"
if not defined SDS_USE_DYNAMIC set "SDS_USE_DYNAMIC=0"

:: Define color codes based on render quality
if /i "%RENDER_QUALITY%"=="LOW" (
    set color_selected=7
    set color_available=7
    set color_coming_soon=90
    set color_normal=0
) else if /i "%RENDER_QUALITY%"=="MIDDLE" (
    set color_selected=30;47
    set color_available=36
    set color_coming_soon=90
    set color_normal=0
) else (
    set color_selected=30;46
    set color_available=96
    set color_coming_soon=90
    set color_normal=0
)


:: ========== Pre-processing by mode ==========

:: CONTINUE mode
if "%selector_mode%"=="CONTINUE" (
    call :Check_Continue_Prerequisites
    goto :Process_Continue_Result
)

:: DELETE mode
if "%selector_mode%"=="DELETE" (
    call :Check_Continue_Prerequisites
    goto :Process_Continue_Result
)

:: NEWGAME mode
if "%selector_mode%"=="NEWGAME" (
    call :Check_NewGame_Prerequisites
    goto :MainLoop
)

:: UNDEFINED mode
echo [DEBUG] Unexpected selector_mode=[%selector_mode%]
echo Undefined!?
pause
exit /b 2099

:Process_Continue_Result
    set prereq_result=%errorlevel%

    if %prereq_result%==0 (
        :: No save data found (message displayed and UI_ACTION=CANCEL already set)
        exit /b %RC_OK%
    )
    if %prereq_result%==1 goto :MainLoop

    :: Unexpected case
    set "UI_ACTION=CANCEL"
    exit /b %RC_OK%


:: ========== Check CONTINUE prerequisites ==========

:Check_Continue_Prerequisites
    set save_data_found=0

    for /l %%i in (1,1,%max_available_slots%) do (
        if exist "%saves_active_dir%\SaveData_%%i.txt" (
            for %%f in ("%saves_active_dir%\SaveData_%%i.txt") do (
                if %%~zf GTR 50 (
                    set save_data_found=1
                )
            )
        )
    )

    if %save_data_found%==0 (
        goto :Display_NoSaveData_Message
        exit /b 0
    )

    exit /b 1

:Display_NoSaveData_Message
    if "%SDS_USE_DYNAMIC%"=="1" goto :Display_NoSaveData_Message_Dynamic
    cls
    echo.
    echo. %esc%[91m┌─────────────────────────────────────────────┐%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[93m         セーブデータが見つかりません        %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[97m    まずは「はじめから」でゲームを開始して   %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[97m        セーブデータを作成してください       %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m└─────────────────────────────────────────────┘%esc%[0m
    echo.
    echo. %esc%[96mpress any key to continue%esc%[0m
    pause >nul
    set "UI_ACTION=CANCEL"
    exit /b %RC_OK%

:Display_NoSaveData_Message_Dynamic
    cls
    call :Render_SaveDataSelector_Dynamic
    call :Print_Centered 18 "セーブデータが見つかりません。"
    call :Print_Centered 20 "まずは「はじめから」でセーブデータを作成してください。"
    call :Print_Centered 23 "キーを押して続ける"
    pause >nul
    set "UI_ACTION=CANCEL"
    exit /b %RC_OK%


:: ========== Check NEWGAME prerequisites ==========

:Check_NewGame_Prerequisites
    exit /b 1
    :: Nothing is done here for now
    :: Future expansion plan -- TBD





:: ================================
:: ========== Main loop =========
:: ================================

:MainLoop
    call :Load_All_Slots_Cache
    call :Initialize_Slot_Colors
    :: Display all only on first run
    call :Display_SaveDataSelector

:SaveDataSelectLoop
    call :Update_Slot_Colors
    call :Quick_Update_Display
    call :GetChoice
    call :HandleKey %choice%
    if defined UI_ACTION exit /b %RC_OK%
    goto :SaveDataSelectLoop



:: ========== Color management system ==========

:Initialize_Slot_Colors
    for /l %%i in (1,1,%max_total_slots%) do (
        set slot_%%i_color=%color_available%
    )
    set slot_1_color=%color_selected%
    exit /b 0

:Update_Slot_Colors
    for /l %%i in (1,1,%max_total_slots%) do (
        set slot_%%i_color=%color_available%
    )
    :: Highlight the selected slot
    if "%current_selected_slot%"=="1" set slot_1_color=%color_selected%
    if "%current_selected_slot%"=="2" set slot_2_color=%color_selected%
    if "%current_selected_slot%"=="3" set slot_3_color=%color_selected%
    if "%current_selected_slot%"=="4" set slot_4_color=%color_selected%
    if "%current_selected_slot%"=="5" set slot_5_color=%color_selected%
    if "%current_selected_slot%"=="6" set slot_6_color=%color_selected%
    if "%current_selected_slot%"=="7" set slot_7_color=%color_selected%
    if "%current_selected_slot%"=="8" set slot_8_color=%color_selected%
    if "%current_selected_slot%"=="9" set slot_9_color=%color_selected%
    if "%current_selected_slot%"=="10" set slot_10_color=%color_selected%
    if "%current_selected_slot%"=="11" set slot_11_color=%color_selected%
    if "%current_selected_slot%"=="12" set slot_12_color=%color_selected%

    exit /b 0


:: ========== Display and input system ==========

:Display_SaveDataSelector
    :: Render entire display only on first run
    cls
    if "%SDS_USE_DYNAMIC%"=="1" (
        call :Render_SaveDataSelector_Dynamic
        if "%DEBUG_STATE%"=="1" (
            call :Display_Debug_Info
        )
        exit /b 0
    )
    if /i "%RENDER_QUALITY%"=="LOW" (
        :: LOW: Load single-border static fallback template
        call :Render_Template_Anchored "%src_display_tpl_dir%\SelectSaveDataDisplay_LOW.txt" %SDS_ANCHOR_COL% %SDS_ANCHOR_ROW%
    ) else (
        :: HIGH / MIDDLE: Load high-quality static templates (pre-rendered borders and title)
        call :Render_Template_Anchored "%src_display_tpl_dir%\SelectSaveDataDisplay_%RENDER_QUALITY%.txt" %SDS_ANCHOR_COL% %SDS_ANCHOR_ROW%
    )
    if "%selector_mode%"=="DELETE" (
        call :Override_Header_For_Delete
    )
    if "%DEBUG_STATE%"=="1" (
        call :Display_Debug_Info
    )
    exit /b 0

:Override_Header_For_Delete
    setlocal EnableDelayedExpansion
    set /a "anchor_row=SDS_ANCHOR_ROW - 1"
    if /i "%RENDER_QUALITY%"=="HIGH" (
        :: Generate 237 spaces dynamically
        set "spaces_237="
        for /l %%i in (1,1,237) do set "spaces_237=!spaces_237! "

        :: Clear rows 6 to 10
        for /l %%r in (6,1,10) do (
            set /a "target_row=%%r + anchor_row"
            echo !esc![!target_row!;2H!spaces_237!
        )
        set /a "title_row=8 + anchor_row"
        call :Print_Centered !title_row! "!esc![91mDELETE SAVE DATA!esc![0m"
    ) else (
        set /a "title_row=4 + anchor_row"
        if /i "%RENDER_QUALITY%"=="LOW" (
            call :Print_Centered !title_row! "DELETE SAVE DATA"
        ) else (
            call :Print_Centered !title_row! "!esc![91mDELETE SAVE DATA!esc![0m"
        )
    )
    endlocal
    exit /b 0

:Quick_Update_Display
    if "%SDS_USE_DYNAMIC%"=="1" goto :Quick_Update_Display_Dynamic
    setlocal EnableDelayedExpansion
    set /a "anchor_col=%SDS_ANCHOR_COL% - 1"
    set /a "anchor_row=%SDS_ANCHOR_ROW% - 1"
    for /l %%i in (1,1,12) do (
        set /a "col_idx=(%%i - 1) %% 3"
        set /a "row_idx=(%%i - 1) / 3"
        set /a "s_row=SLOT_POS_ROW + anchor_row + (row_idx * %SLOT_ROW_PITCH%)"
        if "!col_idx!"=="0" set /a "s_col=%SLOT_POS_COL_1% + anchor_col"
        if "!col_idx!"=="1" set /a "s_col=%SLOT_POS_COL_2% + anchor_col"
        if "!col_idx!"=="2" set /a "s_col=%SLOT_POS_COL_3% + anchor_col"
        set /a "s_col_right=s_col + (%SLOT_BOX_WIDTH% - 1)"
        set /a "r0=s_row"
        set /a "r1=s_row+1"
        set /a "r2=s_row+2"
        set /a "r3=s_row+3"
        set /a "r4=s_row+4"
        set /a "r5=s_row+5"
        set /a "r6=s_row+6"
        set /a "r7=s_row+7"
        set "s_color=!slot_%%i_color!"
        echo !esc![!r0!;!s_col!H!esc![!s_color!m┌────────────────────┐!esc![0m
        echo !esc![!r1!;!s_col!H!esc![!s_color!m│!esc![0m[%%i] !slot_%%i_line_name!!esc![!s_color!m!esc![!r1!;!s_col_right!H│!esc![0m
        echo !esc![!r2!;!s_col!H!esc![!s_color!m│!esc![0m    !slot_%%i_line_level!!esc![!s_color!m!esc![!r2!;!s_col_right!H│!esc![0m
        echo !esc![!r3!;!s_col!H!esc![!s_color!m│!esc![0m    !slot_%%i_line_route!!esc![!s_color!m!esc![!r3!;!s_col_right!H│!esc![0m
        echo !esc![!r4!;!s_col!H!esc![!s_color!m│                    !esc![!s_color!m!esc![!r4!;!s_col_right!H│!esc![0m
        echo !esc![!r5!;!s_col!H!esc![!s_color!m│                    !esc![!s_color!m!esc![!r5!;!s_col_right!H│!esc![0m
        echo !esc![!r6!;!s_col!H!esc![!s_color!m│                    !esc![!s_color!m!esc![!r6!;!s_col_right!H│!esc![0m
        echo !esc![!r7!;!s_col!H!esc![!s_color!m└────────────────────┘!esc![0m
    )
    endlocal
    if "%DEBUG_STATE%"=="1" (
        call :Update_All_Debug_Info
    )
    exit /b 0

:Quick_Update_Display_Dynamic
    setlocal EnableDelayedExpansion
    for /l %%i in (1,1,12) do (
        set /a "col_idx=(%%i - 1) %% 3"
        set /a "row_idx=(%%i - 1) / 3"
        set /a "s_row=SLOT_POS_ROW + (row_idx * %SLOT_ROW_PITCH%)"
        if "!col_idx!"=="0" set /a "s_col=%SLOT_POS_COL_1%"
        if "!col_idx!"=="1" set /a "s_col=%SLOT_POS_COL_2%"
        if "!col_idx!"=="2" set /a "s_col=%SLOT_POS_COL_3%"
        set /a "s_col_right=s_col + (%SLOT_BOX_WIDTH% - 1)"
        set /a "r0=s_row"
        set /a "r1=s_row+1"
        set /a "r2=s_row+2"
        set /a "r3=s_row+3"
        set /a "r4=s_row+4"
        set /a "r5=s_row+5"
        set "s_color=!slot_%%i_color!"
        echo !esc![!r0!;!s_col!H!esc![!s_color!m+--------------------+!esc![0m
        echo !esc![!r1!;!s_col!H!esc![!s_color!m^|!esc![0m[%%i] !slot_%%i_line_name!!esc![!s_color!m!esc![!r1!;!s_col_right!H^|!esc![0m
        echo !esc![!r2!;!s_col!H!esc![!s_color!m^|!esc![0m    !slot_%%i_line_level!!esc![!s_color!m!esc![!r2!;!s_col_right!H^|!esc![0m
        echo !esc![!r3!;!s_col!H!esc![!s_color!m^|!esc![0m    !slot_%%i_line_route!!esc![!s_color!m!esc![!r3!;!s_col_right!H^|!esc![0m
        echo !esc![!r4!;!s_col!H!esc![!s_color!m^|                    ^|!esc![0m
        echo !esc![!r5!;!s_col!H!esc![!s_color!m+--------------------+!esc![0m
    )
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

:Render_SaveDataSelector_Dynamic
    setlocal EnableDelayedExpansion
    call :Draw_Box %SDS_FRAME_LEFT% %SDS_FRAME_TOP% %SDS_FRAME_RIGHT% %SDS_FRAME_BOTTOM%
    if "%selector_mode%"=="DELETE" (
        call :Print_Centered %SDS_TITLE_ROW_1% "DELETE SAVE DATA"
        call :Print_Centered %SDS_TITLE_ROW_2% "~ Select slot to delete ~"
    ) else (
        call :Print_Centered %SDS_TITLE_ROW_1% "SAVE DATA SELECT"
        call :Print_Centered %SDS_TITLE_ROW_2% "~ Select save data ~"
    )
    if "%SDS_SHOW_HELP_BOX%"=="1" (
        call :Draw_Box %SDS_HELP_BOX_LEFT% %SDS_HELP_BOX_TOP% %SDS_HELP_BOX_RIGHT% %SDS_HELP_BOX_BOTTOM%
        call :Print_Centered %SDS_HELP_TEXT_ROW% "WASD: 移動  F: 決定  Q: 戻る"
    ) else (
        call :Print_Centered %SDS_HELP_TEXT_ROW% "WASD: 移動  F: 決定  Q: 戻る"
    )
    if "%SDS_SHOW_FOOTER%"=="1" (
        echo !esc![%SDS_FOOTER_ROW_1%;%SDS_FOOTER_LEFT_COL%H%app_title%
        echo !esc![%SDS_FOOTER_ROW_2%;%SDS_FOOTER_LEFT_COL%HVersion: %app_version%
        call :Print_Right %SDS_FOOTER_ROW_1% %SDS_FRAME_RIGHT% "Developed by HedgeHogSoft"
        call :Print_Right %SDS_FOOTER_ROW_2% %SDS_FRAME_RIGHT% "(c) 2021-2026 RPGGAME."
    )
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

:GetChoice
    choice /n /c ABCDEFGHIJKLMNOPQRSTUVWXYZ >nul
    set choice=%errorlevel%
    exit /b 0

:: ========== Input processing system ==========


:HandleKey
    set key=%1

    :: Unified debug and log processing
    call :Process_Common_Key_Tasks %key%

    :: Execute key-specific action
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

    :: Primary function keys (return immediately)
    if %key%==6 call :Handle_Select
    if defined UI_ACTION (exit /b 0)

    if %key%==17 call :Handle_Back
    if defined UI_ACTION (exit /b 0)

    :: Move keys (unified processing)
    if %key%==1 call :Handle_Move_Left
    if %key%==4 call :Handle_Move_Right
    if %key%==19 call :Handle_Move_Down
    if %key%==23 call :Handle_Move_Up

    :: WIP keys (for future extension, do nothing for now)
    call :Handle_WIP_Key %key%

    exit /b 0

:Handle_Select
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav"
    if "%DEBUG_STATE%"=="1" (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )
    call :HandleSelection
    exit /b 0

:Handle_Back
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
    if "%DEBUG_STATE%"=="1" (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )

    set "UI_ACTION=CANCEL"
    set "UI_PARAM="
    if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "back mode=%selector_mode%"
    exit /b 0

:Handle_Move_Left
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Left_1
    exit /b 0

:Handle_Move_Right
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Right_1
    exit /b 0

:Handle_Move_Down
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Down_3
    exit /b 0

:Handle_Move_Up
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Up_3
    exit /b 0

:Handle_WIP_Key
    :: WIP keys are intentionally ignored.
    exit /b 0

:: ========== Move processing function ==========

:Move_Up_3
    set /a new_slot=%current_selected_slot% - 3
    if %new_slot% lss 1 set new_slot=%current_selected_slot%
    set current_selected_slot=%new_slot%
    exit /b 0

:Move_Left_1
    set /a new_slot=%current_selected_slot% - 1
    if %new_slot% lss 1 set new_slot=%max_total_slots%
    set current_selected_slot=%new_slot%
    exit /b 0

:Move_Down_3
    set /a new_slot=%current_selected_slot% + 3
    if %new_slot% gtr %max_total_slots% set new_slot=%current_selected_slot%
    set current_selected_slot=%new_slot%
    exit /b 0

:Move_Right_1
    set /a new_slot=%current_selected_slot% + 1
    if %new_slot% gtr %max_total_slots% set new_slot=1
    set current_selected_slot=%new_slot%
    exit /b 0

:: ========== Selection processing system ==========

:HandleSelection
    if "%selector_mode%"=="CONTINUE" (
        call :Handle_Continue_Selection
        exit /b 0
    ) else if "%selector_mode%"=="NEWGAME" (
        call :Handle_NewGame_Selection
        if "%DEBUG_STATE%"=="1" (
            echo %esc%[29;2H%esc%[K[%current_time%]%esc%[0m
            call echo %%esc%%[30;2H%%esc%%[K%%esc%%[91m[DEBUG] UI_ACTION from Handle_NewGame_Selection = %%UI_ACTION%% %%esc%%[0m
        )
        exit /b 0
    ) else if "%selector_mode%"=="DELETE" (
        call :Handle_Delete_Selection
        exit /b 0
    )
    exit /b 0

:Handle_Delete_Selection
    :: Slot range check
    if %current_selected_slot% gtr %max_available_slots% (
        exit /b 0
    )

    :: Save file existence check
    if not exist "%saves_active_dir%\SaveData_%current_selected_slot%.txt" (
        call :DlgShow "このスロットにはデータがありません" "41;97" 2
        exit /b 0
    )

    :: In DELETE mode, we bypass confirmations in the selector,
    :: and return UI_ACTION=DELETE / UI_PARAM=%current_selected_slot% to SaveDataDeleter.bat.
    set "UI_ACTION=DELETE"
    set "UI_PARAM=%current_selected_slot%"
    if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "delete selected slot=%current_selected_slot%"
    exit /b 0

:Handle_Continue_Selection
    if "%DEBUG_STATE%"=="1" (
        echo %esc%[27;2H%esc%[K[%current_time%]%esc%[0m
        echo %esc%[28;2H%esc%[K%esc%[91m[DEBUG] Handle_Continue_Selection: Slot=%current_selected_slot% %esc%[0m
        timeout /t 1 >nul
    )

    :: Slot range check
    if %current_selected_slot% gtr %max_available_slots% (
        exit /b 0
    )

    :: Save file existence check
    if not exist "%saves_active_dir%\SaveData_%current_selected_slot%.txt" (
        call :DlgShow "このスロットにはデータがありません" "41;97" 2
        exit /b 0
    )

    call :Preview_SaveData %current_selected_slot%
    call :Confirm_LoadGame %current_selected_slot%

    if "%load_confirmed_flag%"=="1" (
        set "UI_ACTION=CONTINUE"
        set "UI_PARAM=%current_selected_slot%"
        if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "continue slot=%current_selected_slot%"
        if "%DEBUG_STATE%"=="1" (
            echo %esc%[15;1H%esc%[K%esc%[91m [DEBUG] Continue confirmed: slot=%current_selected_slot% %esc%[0m
            timeout /t 2 >nul
        )
        exit /b 0
    ) else (
        exit /b 0
    )

    set "UI_ACTION=CANCEL"
    exit /b 0

:Handle_NewGame_Selection
    :: Display debug info
    if "%DEBUG_STATE%"=="1" (
        echo %esc%[27;2H%esc%[K[%current_time%]%esc%[0m
        echo %esc%[28;2H%esc%[K%esc%[91m[DEBUG] Handle_NewGame_Selection: Slot=%current_selected_slot% %esc%[0m
        timeout /t 1 >nul
    )
    if %current_selected_slot% leq %max_available_slots% (
        if exist "%saves_active_dir%\SaveData_%current_selected_slot%.txt" (
            call :Confirm_Overwrite %current_selected_slot%
            if errorlevel 1 (
                set "UI_ACTION=NEWGAME_OVERWRITE"
                set "UI_PARAM=%current_selected_slot%"
                if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "newgame overwrite slot=%current_selected_slot%"
                exit /b 0
            ) else (
                exit /b 0
            )
        ) else (
            call :Confirm_CreateNew %current_selected_slot%
            if errorlevel 1 (
                set "UI_ACTION=NEWGAME_CREATE"
                set "UI_PARAM=%current_selected_slot%"
                if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "newgame create slot=%current_selected_slot%"
                exit /b 0
            ) else (
                exit /b 0
            )
        )
    )

    set "UI_ACTION=CANCEL"
    exit /b 0



:Confirm_LoadGame
    set "load_confirmed_flag=0"
    call :DlgPrint "このデータをロードしますか？ (F=はい/Q=いいえ)" "93"
    call :Process_Dialog_Input "LOAD"
    set "confirm_choice=%errorlevel%"
    call :DlgClear

    if "%confirm_choice%"=="1" (
        set "load_confirmed_flag=1"
        exit /b 0
    ) else (
        set "load_confirmed_flag=0"
        exit /b 0
    )

:Confirm_Overwrite
    call :DlgPrint "既存のデータを上書きしますか？ (F=はい/Q=いいえ)" "93"
    call :Process_Dialog_Input "OVERWRITE"
    set choice=%errorlevel%
    call :DlgClear

    if %choice%==1 (
        exit /b 1
    ) else (
        exit /b 0
    )

:Confirm_CreateNew
    call :DlgPrint "新しいゲームを開始しますか？ (F=はい/Q=いいえ)" "93"
    call :Process_Dialog_Input CREATE
    set choice=%errorlevel%
    call :DlgClear

    if %choice%==1 (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter3.wav"
        set retcode=1
        exit /b 1
    ) else (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
        set retcode=0
        exit /b 0
    )

:Preview_SaveData
    set slot_num=%1
    if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "DEBUG: Preview_SaveData start slot=%slot_num%"
    if exist "%saves_active_dir%\SaveData_%slot_num%.txt" (
        call :DlgShow "[プレビュー] スロット %slot_num% データ確認中..." "96" 1
    )
    if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "DEBUG: Preview_SaveData complete"
    exit /b 0

:DlgPrint
    setlocal EnableDelayedExpansion
    set "dialog_text=%~1"
    set "dialog_color=%~2"
    if "%dialog_color%"=="" set "dialog_color=93"
    set /a "dialog_row=%SDS_DIALOG_ROW% + %SDS_ANCHOR_ROW% - 1"
    set /a "dialog_col=%SDS_DIALOG_COL% + %SDS_ANCHOR_COL% - 1"
    echo !esc![!dialog_row!;!dialog_col!H!esc![!dialog_color!m !dialog_text! !esc![0m
    endlocal
    exit /b 0

:DlgClear
    setlocal EnableDelayedExpansion
    set /a "dialog_row=%SDS_DIALOG_ROW% + %SDS_ANCHOR_ROW% - 1"
    set /a "dialog_col=%SDS_DIALOG_COL% + %SDS_ANCHOR_COL% - 1"
    echo !esc![!dialog_row!;!dialog_col!H!esc![K
    endlocal
    exit /b 0

:DlgShow
    call :DlgPrint "%~1" "%~2"
    timeout /t %~3 >nul
    call :DlgClear
    exit /b 0

:Process_Dialog_Input
    rem Dialog input handling
    set dialog_type=%1
    if "%dialog_type%"=="" set dialog_type=UNKNOWN

    call :GetChoice
    :: F=6, Q=17

    :: Record to key logs in debug mode
    if "%DEBUG_STATE%"=="1" (
        if %choice%==6 (
            call :Add_Key_Log_Dialog F %dialog_type%_CONFIRM
        ) else if %choice%==17 (
            call :Add_Key_Log_Dialog Q %dialog_type%_CANCEL
        ) else (
            call :Add_Key_Log_Dialog %choice% %dialog_type%_IGNORED
        )
    )

    :: Actual processing
    if %choice%==6 (
        exit /b 1
    ) else if %choice%==17 (
        exit /b 2
    ) else (
        call :Process_Dialog_Input %dialog_type%
        exit /b %errorlevel%
    )

    exit /b 0

:Display_Debug_Info
    :: Initial display of debug info
    call :Update_All_Debug_Info
    exit /b 0

:Render_Debug_Overlay
    setlocal EnableDelayedExpansion
    set /a "dbg_col=%SDS_ANCHOR_COL% + 2"
    set /a "dbg_row=%SDS_ANCHOR_ROW% + 1"
    set /a "dbg_row_2=dbg_row+1"
    set /a "dbg_row_3=dbg_row+2"
    set /a "dbg_row_4=dbg_row+3"
    set /a "dbg_row_5=dbg_row+4"
    echo !esc![!dbg_row!;!dbg_col!H!esc![48;5;235m!esc![38;5;220m SDS DEBUG                     !esc![0m
    echo !esc![!dbg_row_2!;!dbg_col!H!esc![48;5;235m mode=!selector_mode! slot=!current_selected_slot!        !esc![0m
    echo !esc![!dbg_row_3!;!dbg_col!H!esc![48;5;235m key=!key! debug overlay active       !esc![0m
    echo !esc![!dbg_row_4!;!dbg_col!H!esc![48;5;235m anc=!SDS_ANCHOR_COL!,!SDS_ANCHOR_ROW! dlg=!SDS_DIALOG_COL!,!SDS_DIALOG_ROW! !esc![0m
    echo !esc![!dbg_row_5!;!dbg_col!H!esc![48;5;235m act=!UI_ACTION! param=!UI_PARAM!            !esc![0m
    endlocal
    exit /b 0

:Refresh_Display
    :: Redraw screen
    cls
    call :Display_SaveDataSelector
    exit /b 0

:: ========== Key log recording system ==========

:Add_Key_Log
    set input_key=%1
    set current_time=%time:~0,8%

    :: Convert the key code to the debug log label.
    set key_name=UNKNOWN
    if %input_key%==1 set key_name=A(LEFT)
    if %input_key%==2 set key_name=B
    if %input_key%==3 set key_name=C
    if %input_key%==4 set key_name=D(RIGHT)
    if %input_key%==5 set key_name=E
    if %input_key%==6 set key_name=F(SELECT)
    if %input_key%==7 set key_name=G
    if %input_key%==8 set key_name=H
    if %input_key%==9 set key_name=I
    if %input_key%==10 set key_name=J(WIP)
    if %input_key%==11 set key_name=K
    if %input_key%==12 set key_name=L(WIP)
    if %input_key%==13 set key_name=M(WIP)
    if %input_key%==14 set key_name=N(WIP)
    if %input_key%==15 set key_name=O
    if %input_key%==16 set key_name=P
    if %input_key%==17 set key_name=Q(BACK)
    if %input_key%==18 set key_name=R
    if %input_key%==19 set key_name=S(DOWN)
    if %input_key%==20 set key_name=T(WIP)
    if %input_key%==21 set key_name=U(WIP)
    if %input_key%==22 set key_name=V(WIP)
    if %input_key%==23 set key_name=W(UP)
    if %input_key%==24 set key_name=X
    if %input_key%==25 set key_name=Y
    if %input_key%==26 set key_name=Z

    :: Create log entry (unified format with MainMenuModule.bat)
    set log_entry=[%current_time%] #%key_log_count% %key_name% - Slot:%current_selected_slot%

    :: Circular update of logs
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=%log_entry%

    set /a key_log_count+=1

    :: Save to environment variables (shared among modules)
    set RPG_DEBUG_KEYLOG_COUNT=%key_log_count%
    set RPG_DEBUG_LOG1=%key_log_line_1%
    set RPG_DEBUG_LOG2=%key_log_line_2%
    set RPG_DEBUG_LOG3=%key_log_line_3%
    set RPG_DEBUG_LOG4=%key_log_line_4%
    set RPG_DEBUG_LOG5=%key_log_line_5%

    exit /b 0

:Add_Key_Log_Dialog
    set input_key=%~1
    set dialog_action=%~2
    set current_time=%time:~0,8%

    :: Convert the dialog input to the debug log label.
    set key_name=UNKNOWN
    if "%input_key%"=="F" set key_name=F(CONFIRM)
    if "%input_key%"=="Q" set key_name=Q(CANCEL)
    if "%input_key%"=="Y" set key_name=Y(YES)
    if "%input_key%"=="N" set key_name=N(NO)

    :: Process numeric key codes after the named dialog shortcuts.
    if "%input_key%"=="1" set key_name=A(LEFT)
    if "%input_key%"=="2" set key_name=B
    if "%input_key%"=="3" set key_name=C
    if "%input_key%"=="4" set key_name=D(RIGHT)
    if "%input_key%"=="5" set key_name=E
    if "%input_key%"=="6" set key_name=F(CONFIRM)
    if "%input_key%"=="7" set key_name=G
    if "%input_key%"=="8" set key_name=H
    if "%input_key%"=="9" set key_name=I
    if "%input_key%"=="10" set key_name=J(WIP)
    if "%input_key%"=="11" set key_name=K
    if "%input_key%"=="12" set key_name=L(WIP)
    if "%input_key%"=="13" set key_name=M(WIP)
    if "%input_key%"=="14" set key_name=N(WIP)
    if "%input_key%"=="15" set key_name=O
    if "%input_key%"=="16" set key_name=P
    if "%input_key%"=="17" set key_name=Q(CANCEL)
    if "%input_key%"=="18" set key_name=R
    if "%input_key%"=="19" set key_name=S(DOWN)
    if "%input_key%"=="20" set key_name=T(WIP)
    if "%input_key%"=="21" set key_name=U(WIP)
    if "%input_key%"=="22" set key_name=V(WIP)
    if "%input_key%"=="23" set key_name=W(UP)
    if "%input_key%"=="24" set key_name=X
    if "%input_key%"=="25" set key_name=Y
    if "%input_key%"=="26" set key_name=Z

    :: Create log entry (unified format with MainMenuModule.bat)
    set log_entry=[%current_time%] #%key_log_count% %key_name% - Dialog:%dialog_action%

    :: Circular update of logs
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=%log_entry%

    set /a key_log_count+=1

    :: Save to environment variables
    set RPG_DEBUG_KEYLOG_COUNT=%key_log_count%
    set RPG_DEBUG_LOG1=%key_log_line_1%
    set RPG_DEBUG_LOG2=%key_log_line_2%
    set RPG_DEBUG_LOG3=%key_log_line_3%
    set RPG_DEBUG_LOG4=%key_log_line_4%
    set RPG_DEBUG_LOG5=%key_log_line_5%

    exit /b 0

:: ========== Errorlevel check helper function ==========

:: (Removed as it is no longer needed)


:: ========== Load save data preview cache ==========

:Load_All_Slots_Cache
    :: Load save data for every slot
    for /l %%i in (1,1,%max_total_slots%) do (
        set "slot_%%i_is_empty=true"
        set "slot_%%i_name=Empty Slot"
        set "slot_%%i_level=Lv.0"
        set "slot_%%i_route=None"
        if exist "%saves_active_dir%\SaveData_%%i.txt" (
            set "slot_%%i_is_empty=false"
            for /f "usebackq tokens=1,2 delims==" %%a in ("%saves_active_dir%\SaveData_%%i.txt") do (
                if "%%a"=="player_name" set "slot_%%i_name=%%b"
                if "%%a"=="player_level" set "slot_%%i_level=Lv.%%b"
                if "%%a"=="player_storyroute" set "slot_%%i_route=%%b"
            )
        )
        call :PadString slot_%%i_line_name "!slot_%%i_name!"
        call :PadString slot_%%i_line_level "!slot_%%i_level!"
        call :PadString slot_%%i_line_route "!slot_%%i_route!"
    )
    exit /b 0

:PadString
    setlocal EnableDelayedExpansion
    set "orig_str=%~2"
    if "%orig_str%"=="" set "orig_str= "
    set "padded=%orig_str%                "
    set "trimmed=!padded:~0,%SLOT_TEXT_WIDTH%!"
    endlocal & set "%~1=%trimmed%"
    exit /b 0

:PadString15
    setlocal EnableDelayedExpansion
    set "orig_str=%~2"
    if "%orig_str%"=="" set "orig_str= "
    set "padded=%orig_str%               "
    set /a "slot_text_width_15=%SLOT_TEXT_WIDTH% - 1"
    set "trimmed=!padded:~0,%slot_text_width_15%!"
    endlocal & set "%~1=%trimmed%"
    exit /b 0
