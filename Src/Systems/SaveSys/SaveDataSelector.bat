@echo off
:: Load static UI profile configurations
if exist "%src_display_tpl_dir%\StaticUIProfileSelector.bat" (
    call "%src_display_tpl_dir%\StaticUIProfileSelector.bat"
)
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"


:: 通常の初期化・分岐
set "selector_mode=%1"
if "%selector_mode%"=="" set "selector_mode=CONTINUE"
if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "start mode=%selector_mode% quality=%RENDER_QUALITY%"

:: 返り値の初期化
set retcode=0

:: デバッグ状態継承
if not defined DEBUG_STATE set DEBUG_STATE=0

:: 隠しシーケンスは各モジュールで独立管理
set hidden_sequence=

:: キーログ初期化
set key_log_count=0
set key_log_line_1=
set key_log_line_2=
set key_log_line_3=
set key_log_line_4=
set key_log_line_5=

:: デバッグ拡張機能：ブレークポイント
set debug_breakpoint_enabled=0
set debug_breakpoint_hit=0
set debug_current_key=

:: Initialize the color system
:: Currently selected slots (1-12 compatible, 3 actual operation)

set current_selected_slot=1

:: 返り値・アクションの初期化
set UI_ACTION=
set UI_PARAM=

:: 表示設定
set max_available_slots=12
set max_total_slots=12
set slots_per_row=3

:: 描画品質のデフォルト設定
if not defined RENDER_QUALITY set "RENDER_QUALITY=HIGH"
if not defined SLOT_BOX_WIDTH set "SLOT_BOX_WIDTH=22"
if not defined SLOT_ROW_PITCH set "SLOT_ROW_PITCH=9"
if not defined SLOT_TEXT_WIDTH set "SLOT_TEXT_WIDTH=16"
if not defined SDS_ANCHOR_COL set "SDS_ANCHOR_COL=1"
if not defined SDS_ANCHOR_ROW set "SDS_ANCHOR_ROW=1"
if not defined SDS_DIALOG_COL set "SDS_DIALOG_COL=92"
if not defined SDS_DIALOG_ROW set "SDS_DIALOG_ROW=20"
if not defined SDS_USE_DYNAMIC set "SDS_USE_DYNAMIC=0"

:: 描画品質に応じたカラーコード定義
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


:: ========== モード別前処理 ==========

:: CONTINUEモード
if "%selector_mode%"=="CONTINUE" (
    call :Check_Continue_Prerequisites
    goto :Process_Continue_Result
)

:: NEWGAMEモード
if "%selector_mode%"=="NEWGAME" (
    call :Check_NewGame_Prerequisites
    goto :MainLoop
)

:: UNDEFINEDモード
echo [DEBUG] Unexpected selector_mode=[%selector_mode%]
echo Undefined!?
pause
exit /b 2099

:Process_Continue_Result
    set prereq_result=%errorlevel%
    
    if %prereq_result%==0 (
        :: セーブデータが見つからなかった場合（既にメッセージ表示とUI_ACTION=CANCEL設定済み）
        exit /b %RC_OK%
    )
    if %prereq_result%==1 goto :MainLoop
    
    :: 想定外
    set "UI_ACTION=CANCEL"
    exit /b %RC_OK%


:: ========== CONTINUE前提条件チェック ==========

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
    call :Print_Centered 18 "No save data was found."
    call :Print_Centered 20 "Start a new game first, then create save data."
    call :Print_Centered 23 "Press any key to continue"
    pause >nul
    set "UI_ACTION=CANCEL"
    exit /b %RC_OK%


:: ========== NEWGAME前提条件チェック ==========

:Check_NewGame_Prerequisites
    exit /b 1
    :: ここでは特に何もしない
    :: 今後の拡張予定 -- 未定





:: ================================
:: ========== メインループ =========
:: ================================

:MainLoop
    call :Load_All_Slots_Cache
    call :Initialize_Slot_Colors
    :: 初回のみ全体表示
    call :Display_SaveDataSelector
 
:SaveDataSelectLoop
    call :Update_Slot_Colors
    call :Quick_Update_Display
    call :GetChoice
    call :HandleKey %choice%
    if defined UI_ACTION exit /b %RC_OK%
    goto :SaveDataSelectLoop



:: ========== カラー管理システム ==========

:Initialize_Slot_Colors
    :: 利用可能スロット（1-3）
    set slot_1_color=%color_available%
    set slot_2_color=%color_available%
    set slot_3_color=%color_available%
    
    :: 開発中スロット（4-12）
    set slot_4_color=%color_coming_soon%
    set slot_5_color=%color_coming_soon%
    set slot_6_color=%color_coming_soon%
    set slot_7_color=%color_coming_soon%
    set slot_8_color=%color_coming_soon%
    set slot_9_color=%color_coming_soon%
    set slot_10_color=%color_coming_soon%
    set slot_11_color=%color_coming_soon%
    set slot_12_color=%color_coming_soon%
    
    :: 最初のスロットを選択状態にする
    set slot_1_color=%color_selected%
    exit /b 0

:Update_Slot_Colors
    :: 全スロット通常色にリセット
    set slot_1_color=%color_available%
    set slot_2_color=%color_available%
    set slot_3_color=%color_available%
    set slot_4_color=%color_coming_soon%
    set slot_5_color=%color_coming_soon%
    set slot_6_color=%color_coming_soon%
    set slot_7_color=%color_coming_soon%
    set slot_8_color=%color_coming_soon%
    set slot_9_color=%color_coming_soon%
    set slot_10_color=%color_coming_soon%
    set slot_11_color=%color_coming_soon%
    set slot_12_color=%color_coming_soon%
    
    :: 選択中のスロットのみ反転表示
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

:: ========== 表示・入力システム ==========

:Display_SaveDataSelector
    :: 初回表示時のみ全体描画
    cls
    if "%SDS_USE_DYNAMIC%"=="1" (
        call :Render_SaveDataSelector_Dynamic
        if %DEBUG_STATE%==1 (
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
    if %DEBUG_STATE%==1 (
        call :Display_Debug_Info
    )
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
    if %DEBUG_STATE%==1 (
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
    if %DEBUG_STATE%==1 (
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
    call :Print_Centered %SDS_TITLE_ROW_1% "SAVE DATA SELECT"
    call :Print_Centered %SDS_TITLE_ROW_2% "~ Select save data ~"
    if "%SDS_SHOW_HELP_BOX%"=="1" (
        call :Draw_Box %SDS_HELP_BOX_LEFT% %SDS_HELP_BOX_TOP% %SDS_HELP_BOX_RIGHT% %SDS_HELP_BOX_BOTTOM%
        call :Print_Centered %SDS_HELP_TEXT_ROW% "WASD: select  F: enter  Q: back"
    ) else (
        call :Print_Centered %SDS_HELP_TEXT_ROW% "WASD: select  F: enter  Q: back"
    )
    if "%SDS_SHOW_FOOTER%"=="1" (
        echo !esc![%SDS_FOOTER_ROW_1%;%SDS_FOOTER_LEFT_COL%HAstral Divide
        echo !esc![%SDS_FOOTER_ROW_2%;%SDS_FOOTER_LEFT_COL%HVersion: v0.1.1
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
    :: デバッグタイトル維持（統一形式）
    echo %esc%[1;1H%esc%[K
    echo %esc%[1;1H%esc%[43;30m SaveDataSelector: Debug Mode %esc%[0m
    
    :: 動的情報の更新
    set current_time=%time:~0,8%
    echo %esc%[2;1H%esc%[K%esc%[93m [%current_time%] Slot: %current_selected_slot%/%max_total_slots% Mode: %selector_mode% %esc%[0m
    echo %esc%[3;1H%esc%[K%esc%[96m Available: %max_available_slots% KeyCount: %key_log_count% %esc%[0m
    echo %esc%[4;1H%esc%[K%esc%[97m Sequence: [%hidden_sequence%] DebugState: %DEBUG_STATE% %esc%[0m
    
    :: ステータス行の更新
    set status_line=
    if "%current_selected_slot%"=="1" set status_line=[*1][ 2][ 3]...
    if "%current_selected_slot%"=="2" set status_line=[ 1][*2][ 3]...
    if "%current_selected_slot%"=="3" set status_line=[ 1][ 2][*3]...
    if %current_selected_slot% gtr 3 (
        set status_line=[ 1][ 2][ 3][*%current_selected_slot%]...
    )
    
    echo %esc%[5;1H%esc%[K%esc%[95m SaveSlots: %status_line% %esc%[0m
    echo %esc%[6;1H%esc%[K%esc%[94m Commands: WASD=Move F=Select Q=Back XYZ=Debug %esc%[0m
    
    :: 拡張デバッグ情報：ブレークポイント
    echo %esc%[8;1H%esc%[K%esc%[93m Breakpoint: %debug_breakpoint_enabled% %esc%[0m
    
    :: キー押下履歴の更新
    echo %esc%[20;1H%esc%[K%esc%[90m Key History (SaveDataSelector): %esc%[0m
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

:: 新しい関数を追加
:Restore_Debug_Display
    if %DEBUG_STATE%==1 (
        echo %esc%[1;1H%esc%[43;30m SaveDataSelector: Debug Mode %esc%[0m
        call :Display_Debug_Info
    )
    exit /b 0


:GetChoice
    choice /n /c ABCDEFGHIJKLMNOPQRSTUVWXYZ >nul
    set choice=%errorlevel%
    exit /b 0

:: ========== 入力処理システム ==========


:HandleKey
    set key=%1
    
    :: キーごとのブレークポイントフラグを初期化
    set debug_current_key=%key%
    set debug_breakpoint_hit=0
    
    :: 統一されたデバッグ・ログ処理
    call :Process_Common_Key_Tasks %key%
    
    :: キー別処理の実行
    call :Execute_Key_Action %key%
    if defined UI_ACTION exit /b 0
    
    :: 後処理（隠しシーケンス、制限チェック）
    call :Process_Hidden_Sequences
    call :Check_Sequence_Length
    exit /b 0

:Process_Common_Key_Tasks
    set key=%1
    if %DEBUG_STATE%==1 (
        call :Add_Key_Log %key%
        
        :: ブレークポイントが有効で、現在のキーでまだヒットしていない場合のみ実行
        if %debug_breakpoint_enabled%==1 (
            if %debug_breakpoint_hit%==0 (
                if defined debug_current_key (
                    set debug_breakpoint_hit=1
                    call :Debug_Breakpoint_Pause
                )
            )
        )
    )
    exit /b 0

:Execute_Key_Action
    set key=%1
    
    :: 主要機能キー（即座に返る）
    if %key%==6 call :Handle_Select
    if defined UI_ACTION (exit /b 0)

    if %key%==17 call :Handle_Back
    if defined UI_ACTION (exit /b 0)

    :: 移動キー（統一処理）
    if %key%==1 call :Handle_Move_Left
    if %key%==4 call :Handle_Move_Right
    if %key%==19 call :Handle_Move_Down
    if %key%==23 call :Handle_Move_Up
    
    :: 隠しシーケンスキー（統一処理）
    call :Handle_Hidden_Sequence_Key %key%
    
    :: WIPキー（将来の拡張用、現在は何もしない）
    call :Handle_WIP_Key %key%

    exit /b 0

:Handle_Select
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav"
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )
    call :HandleSelection
    exit /b 0

:Handle_Back
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
    if %DEBUG_STATE%==1 (
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

:Handle_Hidden_Sequence_Key
    set key=%1
    
    :: 統一シーケンスエンジンを使用
    if %key%==2 call :Process_Sequence_Engine B & exit /b 0
    if %key%==3 call :Process_Sequence_Engine C & exit /b 0
    if %key%==5 call :Process_Sequence_Engine E & exit /b 0
    if %key%==7 call :Process_Sequence_Engine G & exit /b 0
    if %key%==9 call :Process_Sequence_Engine I & exit /b 0
    if %key%==11 call :Process_Sequence_Engine K & exit /b 0
    if %key%==15 call :Process_Sequence_Engine O & exit /b 0
    if %key%==16 call :Process_Sequence_Engine P & exit /b 0
    if %key%==18 call :Process_Sequence_Engine R & exit /b 0
    if %key%==21 call :Process_Sequence_Engine U & exit /b 0
    if %key%==24 call :Process_Sequence_Engine X & exit /b 0
    if %key%==25 call :Process_Sequence_Engine Y & exit /b 0
    if %key%==26 call :Process_Sequence_Engine Z & exit /b 0
    
    exit /b 0

:Handle_WIP_Key
    set key=%1
    :: WIPキー: 将来のイースターエッグ用
    :: 現在は何もしない（キーログは記録済み）
    exit /b 0

    
:: ========== 統一シーケンスエンジン ==========

:Process_Sequence_Engine
    set char=%1
    
    :: 各文字のシーケンスルールを統一的に処理
    if "%char%"=="B" call :Sequence_Rule_B
    if "%char%"=="C" call :Sequence_Rule_C
    if "%char%"=="E" call :Sequence_Rule_E
    if "%char%"=="G" call :Sequence_Rule_G
    if "%char%"=="I" call :Sequence_Rule_I
    if "%char%"=="K" call :Sequence_Rule_K
    if "%char%"=="O" call :Sequence_Rule_O
    if "%char%"=="P" call :Sequence_Rule_P
    if "%char%"=="R" call :Sequence_Rule_R
    if "%char%"=="U" call :Sequence_Rule_U
    if "%char%"=="X" call :Sequence_Rule_X
    if "%char%"=="Y" call :Sequence_Rule_Y
    if "%char%"=="Z" call :Sequence_Rule_Z
    
    exit /b 0

:: ========== シーケンスルール定義 ==========

:Sequence_Rule_B
    if "%hidden_sequence%"=="BR" (
        set hidden_sequence=BRK
    ) else (
        set hidden_sequence=B
    )
    exit /b 0

:Sequence_Rule_C
    if "%hidden_sequence%"=="PI" (
        set hidden_sequence=PIC
    ) else if "%hidden_sequence%"=="" (
        set hidden_sequence=C
    ) else (
        set hidden_sequence=
    )
    exit /b 0

:Sequence_Rule_E
    set hidden_sequence=E
    exit /b 0

:Sequence_Rule_G
    set hidden_sequence=
    exit /b 0

:Sequence_Rule_I
    if "%hidden_sequence%"=="P" (
        set hidden_sequence=PI
    ) else (
        set hidden_sequence=
    )
    exit /b 0

:Sequence_Rule_K
    if "%hidden_sequence%"=="PIC" (
        set hidden_sequence=PICK
    ) else if "%hidden_sequence%"=="BR" (
        set hidden_sequence=BRK
    ) else (
        set hidden_sequence=
    )
    exit /b 0

:Sequence_Rule_O
    if "%hidden_sequence%"=="C" (
        set hidden_sequence=CO
    ) else if "%hidden_sequence%"=="CO" (
        set hidden_sequence=COO
    ) else (
        set hidden_sequence=
    )
    exit /b 0

:Sequence_Rule_P
    set hidden_sequence=P
    exit /b 0

:Sequence_Rule_R
    if "%hidden_sequence%"=="B" (
        set hidden_sequence=BR
    ) else if "%hidden_sequence%"=="COO" (
        set hidden_sequence=COOR
    ) else (
        set hidden_sequence=
    )
    exit /b 0

:Sequence_Rule_U
    set hidden_sequence=
    exit /b 0

:Sequence_Rule_X
    set hidden_sequence=X
    exit /b 0

:Sequence_Rule_Y
    if "%hidden_sequence%"=="X" (
        set hidden_sequence=XY
    ) else (
        set hidden_sequence=Y
    )
    exit /b 0

:Sequence_Rule_Z
    if "%hidden_sequence%"=="XY" (
        set hidden_sequence=XYZ
    ) else (
        set hidden_sequence=Z
    )
    exit /b 0

:Process_Hidden_Sequences
    :: デバッグコード: XYZ
    if "%hidden_sequence%"=="XYZ" (
        set hidden_sequence=
        call :Activate_Debug_Mode
        exit /b 0
    )
    
    :: ブレークポイント切り替え: BRK
    if "%hidden_sequence%"=="BRK" (
        set hidden_sequence=
        call :Debug_Toggle_Breakpoint
        exit /b 0
    )

    :: PICKコマンド発動
    if /i "%hidden_sequence%"=="PICK" (
        set hidden_sequence=
        call :Launch_Debug_Tool "PICKER" "%current_selected_slot%"
        exit /b 0
    )

    :: COORDコマンド発動
    if /i "%hidden_sequence%"=="COORD" (
        set hidden_sequence=
        call :Launch_Debug_Tool "COORD" ""
        exit /b 0
    )

    :: シーケンス長制限（10文字以上でリセット）
    call :Check_Sequence_Length

    exit /b 0

    :: デバッグモード時はsequence[]の変更を即座に反映
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
    )

    exit /b 0

:Launch_Debug_Tool
    set tool_type=%1
    set tool_param=%2
    
    if %tool_type%=="PICKER" (
        echo %esc%[27;2H%esc%[90m[DEBUG]%esc%[0m
        echo %esc%[28;2H%esc%[93m[%current_time%] Launch InteractivePicker %esc%[0m
        call "%cd_systems%\Debug\InteractivePicker.bat" "SaveData" "%tool_param%"
        echo %esc%[29;2H%esc%[93m[%current_time%] Terminate InteractivePicker %esc%[0m
    ) else if %tool_type%=="COORD" (
        call "%cd_systems%\Debug\CoordinateDebugTool.bat" "SaveData"
    )
    timeout /t 1 >nul
    call :Refresh_Display
    exit /b 0

:Check_Sequence_Length
    :: hidden_sequenceの長さをチェック（10文字以上でリセット）
    if defined hidden_sequence (
        if "%hidden_sequence:~10,1%" neq "" (
            set hidden_sequence=
        )
    )
    exit /b 0

:: ========== 移動処理関数 ==========

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

:: ========== 選択処理システム ==========

:HandleSelection
    if "%selector_mode%"=="CONTINUE" (
        call :Handle_Continue_Selection
        exit /b 0
    ) else if "%selector_mode%"=="NEWGAME" (
        call :Handle_NewGame_Selection
        if %DEBUG_STATE%==1 (
            echo %esc%[29;2H%esc%[K[%current_time%]%esc%[0m
            call echo %%esc%%[30;2H%%esc%%[K%%esc%%[91m[DEBUG] UI_ACTION from Handle_NewGame_Selection = %%UI_ACTION%% %%esc%%[0m
        )
        exit /b 0
    )
    exit /b 0

:Handle_Continue_Selection
    :: デバッグ情報表示
    if %DEBUG_STATE%==1 (
        echo %esc%[27;2H%esc%[K[%current_time%]%esc%[0m
        echo %esc%[28;2H%esc%[K%esc%[91m[DEBUG] Handle_Continue_Selection: Slot=%current_selected_slot% %esc%[0m
        timeout /t 1 >nul
    )
    if %current_selected_slot% leq %max_available_slots% (
        if exist "%saves_active_dir%\SaveData_%current_selected_slot%.txt" (
            call :Preview_SaveData %current_selected_slot%
            call :Confirm_LoadGame %current_selected_slot%
            if !errorlevel! == 1 (
                set temp_confirmed=1
            ) else (
                set temp_confirmed=0
            )
            if %temp_confirmed%==1 (
                set "UI_ACTION=CONTINUE"
                set "UI_PARAM=%current_selected_slot%"
                if exist "%RCSU%" call "%RCSU%" -trace INFO SDS "continue slot=%current_selected_slot%"
                if %DEBUG_STATE%==1 (
                    echo %esc%[15;1H%esc%[K%esc%[91m [DEBUG] Continue confirmed: slot=%current_selected_slot% %esc%[0m
                    timeout /t 2 >nul
                )
                exit /b 0
            ) else (
                exit /b 0
            )
        ) else (
            call :DlgShow "このスロットにはデータがありません" "41;97" 2
            exit /b 0
        )
    )
    
    if %current_selected_slot% gtr %max_available_slots% (
        call :DlgShow "このスロットは開発中です" "41;97" 1
        exit /b 0
    )
    
    set "UI_ACTION=CANCEL"
    exit /b 0

:Handle_NewGame_Selection
    :: デバッグ情報表示
    if %DEBUG_STATE%==1 (
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

    if %current_selected_slot% gtr %max_available_slots% (
        call :DlgShow "This slot is under development" "41;97" 1
        exit /b 0
    )

    set "UI_ACTION=CANCEL"
    exit /b 0



:Confirm_LoadGame
    call :DlgPrint "このデータをロードしますか？ (F=はい/Q=いいえ)" "93"
    call :Process_Dialog_Input "LOAD"
    set choice=%errorlevel%
    call :DlgClear
    
    if %choice%==1 (
        exit /b 1
    ) else (
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
    if exist "%saves_active_dir%\SaveData_%slot_num%.txt" (
        call :DlgShow "[Preview] Slot %slot_num% データ確認中..." "96" 1
    )
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
    :: ダイアログ中の入力処理
    set dialog_type=%1
    if "%dialog_type%"=="" set dialog_type=UNKNOWN
    
    call :GetChoice
    :: F=6, Q=17
    
    :: デバッグモード時はキーログに記録
    if %DEBUG_STATE%==1 (
        if %choice%==6 (
            call :Add_Key_Log_Dialog F %dialog_type%_CONFIRM
        ) else if %choice%==17 (
            call :Add_Key_Log_Dialog Q %dialog_type%_CANCEL
        ) else (
            call :Add_Key_Log_Dialog %choice% %dialog_type%_IGNORED
        )
    )
    
    :: 実際の処理
    if %choice%==6 (
        exit /b 1
    ) else if %choice%==17 (
        exit /b 2
    ) else (
        call :Process_Dialog_Input %dialog_type%
        exit /b %errorlevel%
    )

    exit /b 0

:: ========== デバッグ拡張機能 ==========

:Debug_Breakpoint_Pause
    :: 疑似ブレークポイント動作
    echo %esc%[12;1H%esc%[41;97m === BREAKPOINT HIT (Key:%debug_current_key%) === %esc%[0m
    echo %esc%[13;1H%esc%[97m Press any key to continue... %esc%[0m
    pause >nul
    echo %esc%[12;1H%esc%[K
    echo %esc%[13;1H%esc%[K
    :: ブレークポイントヒットフラグはキー終了時にリセット
    exit /b 0

:Debug_Toggle_Breakpoint
    :: ブレークポイントのオン/オフ切り替え
    if %debug_breakpoint_enabled%==0 (
        set debug_breakpoint_enabled=1
        echo %esc%[12;1H%esc%[42;30m Breakpoint ENABLED %esc%[0m
    ) else (
        set debug_breakpoint_enabled=0
        echo %esc%[12;1H%esc%[43;30m Breakpoint DISABLED %esc%[0m
    )
    timeout /t 1 >nul
    echo %esc%[12;1H%esc%[K
    exit /b 0

:Debug_Add_Variable_Watch
    :: 変数監視リストに追加
    set debug_variable_watch_list=%debug_variable_watch_list%,%1
    exit /b 0

:Debug_Clear_Variable_Watch
    :: 変数監視リストをクリア
    set debug_variable_watch_list=
    exit /b 0

:Activate_Debug_Mode
    echo %esc%[55;90H%esc%[91m ===== DEBUG CODE ACTIVATED ===== %esc%[0m
    :: キーログを初期化
    set key_log_count=0
    set key_log_line_1=
    set key_log_line_2=
    set key_log_line_3=
    set key_log_line_4=
    set key_log_line_5=
    timeout /t 1 >nul
    call :Toggle_Debug_Mode
    exit /b 0

:Toggle_Debug_Mode
    if not defined debug_selector set debug_selector=0

    if %debug_selector%==0 (
        set debug_selector=1
        echo %esc%[1;1H%esc%[43;30m [DEBUG] FALSE -^> TRUE %esc%[0m
        timeout /t 1 >nul
        echo %esc%[1;1H%esc%[K

        :: 環境変数に状態を保存
        set DEBUG_STATE=1
        set RPG_DEBUG_KEYLOG_COUNT=%key_log_count%
        set RPG_DEBUG_LOG1=%key_log_line_1%
        set RPG_DEBUG_LOG2=%key_log_line_2%
        set RPG_DEBUG_LOG3=%key_log_line_3%
        set RPG_DEBUG_LOG4=%key_log_line_4%
        set RPG_DEBUG_LOG5=%key_log_line_5%

        call :Display_Debug_Info
    ) else (
        set debug_selector=0
        echo %esc%[1;1H%esc%[42;30m [DEBUG] TRUE -^> FALSE %esc%[0m
        timeout /t 1 >nul
        echo %esc%[1;1H%esc%[K

        :: 環境変数をクリア
        set DEBUG_STATE=0
        set RPG_DEBUG_KEYLOG_COUNT=0
        set RPG_DEBUG_LOG1=
        set RPG_DEBUG_LOG2=
        set RPG_DEBUG_LOG3=
        set RPG_DEBUG_LOG4=
        set RPG_DEBUG_LOG5=

        call :Refresh_Display
    )
    exit /b 0

:Display_Debug_Info
    :: デバッグ情報の初期表示
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
    echo !esc![!dbg_row_3!;!dbg_col!H!esc![48;5;235m key=!key! seq=!hidden_sequence!              !esc![0m
    echo !esc![!dbg_row_4!;!dbg_col!H!esc![48;5;235m anc=!SDS_ANCHOR_COL!,!SDS_ANCHOR_ROW! dlg=!SDS_DIALOG_COL!,!SDS_DIALOG_ROW! !esc![0m
    echo !esc![!dbg_row_5!;!dbg_col!H!esc![48;5;235m act=!UI_ACTION! param=!UI_PARAM!            !esc![0m
    endlocal
    exit /b 0

:Refresh_Display
    :: 画面を再描画
    cls
    call :Display_SaveDataSelector
    exit /b 0

:: ========== キーログ記録システム ==========

:Add_Key_Log
    set input_key=%1
    set current_time=%time:~0,8%
    
    :: キーマッピング（1=A, 2=B, ..., 26=Z）
    set key_name=Unknown
    if %input_key%==1 set key_name=A
    if %input_key%==2 set key_name=B
    if %input_key%==3 set key_name=C
    if %input_key%==4 set key_name=D
    if %input_key%==5 set key_name=E
    if %input_key%==6 set key_name=F
    if %input_key%==7 set key_name=G
    if %input_key%==8 set key_name=H
    if %input_key%==9 set key_name=I
    if %input_key%==10 set key_name=J
    if %input_key%==11 set key_name=K
    if %input_key%==12 set key_name=L
    if %input_key%==13 set key_name=M
    if %input_key%==14 set key_name=N
    if %input_key%==15 set key_name=O
    if %input_key%==16 set key_name=P
    if %input_key%==17 set key_name=Q
    if %input_key%==18 set key_name=R
    if %input_key%==19 set key_name=S
    if %input_key%==20 set key_name=T
    if %input_key%==21 set key_name=U
    if %input_key%==22 set key_name=V
    if %input_key%==23 set key_name=W
    if %input_key%==24 set key_name=X
    if %input_key%==25 set key_name=Y
    if %input_key%==26 set key_name=Z
    
    :: キー名を人間が読める形に変換（MainMenuModule.batと統一）
    set key_name=UNKNOWN
    if %input_key%==1 set key_name=A(LEFT)
    if %input_key%==2 set key_name=B(Hidden)
    if %input_key%==3 set key_name=C(Hidden)
    if %input_key%==4 set key_name=D(RIGHT)
    if %input_key%==5 set key_name=E(Hidden)
    if %input_key%==6 set key_name=F(SELECT)
    if %input_key%==7 set key_name=G(Hidden)
    if %input_key%==8 set key_name=H(Hidden)
    if %input_key%==9 set key_name=I(Hidden)
    if %input_key%==10 set key_name=J(WIP)
    if %input_key%==11 set key_name=K(Hidden)
    if %input_key%==12 set key_name=L(WIP)
    if %input_key%==13 set key_name=M(WIP)
    if %input_key%==14 set key_name=N(WIP)
    if %input_key%==15 set key_name=O(Hidden)
    if %input_key%==16 set key_name=P(Hidden)
    if %input_key%==17 set key_name=Q(BACK)
    if %input_key%==18 set key_name=R(Hidden)
    if %input_key%==19 set key_name=S(DOWN)
    if %input_key%==20 set key_name=T(WIP)
    if %input_key%==21 set key_name=U(WIP)
    if %input_key%==22 set key_name=V(WIP)
    if %input_key%==23 set key_name=W(UP)
    if %input_key%==24 set key_name=X(Hidden)
    if %input_key%==25 set key_name=Y(Hidden)
    if %input_key%==26 set key_name=Z(Hidden)
    
    :: ログエントリの作成（MainMenuModule.batと統一形式）
    set log_entry=[%current_time%] #%key_log_count% %key_name% - Slot:%current_selected_slot%
    
    :: ログの循環更新
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=%log_entry%
    
    set /a key_log_count+=1
    
    :: 環境変数に保存（モジュール間で共有）
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
    
    :: キー名を人間が読める形に変換（MainMenuModule.batと統一）
    set key_name=UNKNOWN
    if "%input_key%"=="F" set key_name=F(CONFIRM)
    if "%input_key%"=="Q" set key_name=Q(CANCEL)
    if "%input_key%"=="Y" set key_name=Y(YES)
    if "%input_key%"=="N" set key_name=N(NO)
    
    :: 数値の場合の処理（文字列チェック後）
    if "%input_key%"=="1" set key_name=A(LEFT)
    if "%input_key%"=="2" set key_name=B(Hidden)
    if "%input_key%"=="3" set key_name=C(Hidden)
    if "%input_key%"=="4" set key_name=D(RIGHT)
    if "%input_key%"=="5" set key_name=E(Hidden)
    if "%input_key%"=="6" set key_name=F(CONFIRM)
    if "%input_key%"=="7" set key_name=G(Hidden)
    if "%input_key%"=="8" set key_name=H(Hidden)
    if "%input_key%"=="9" set key_name=I(Hidden)
    if "%input_key%"=="10" set key_name=J(WIP)
    if "%input_key%"=="11" set key_name=K(Hidden)
    if "%input_key%"=="12" set key_name=L(WIP)
    if "%input_key%"=="13" set key_name=M(WIP)
    if "%input_key%"=="14" set key_name=N(WIP)
    if "%input_key%"=="15" set key_name=O(Hidden)
    if "%input_key%"=="16" set key_name=P(Hidden)
    if "%input_key%"=="17" set key_name=Q(CANCEL)
    if "%input_key%"=="18" set key_name=R(Hidden)
    if "%input_key%"=="19" set key_name=S(DOWN)
    if "%input_key%"=="20" set key_name=T(WIP)
    if "%input_key%"=="21" set key_name=U(WIP)
    if "%input_key%"=="22" set key_name=V(WIP)
    if "%input_key%"=="23" set key_name=W(UP)
    if "%input_key%"=="24" set key_name=X(Hidden)
    if "%input_key%"=="25" set key_name=Y(Hidden)
    if "%input_key%"=="26" set key_name=Z(Hidden)
    
    :: ログエントリの作成（MainMenuModule.batと統一形式）
    set log_entry=[%current_time%] #%key_log_count% %key_name% - Dialog:%dialog_action%
    
    :: ログの循環更新
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=%log_entry%
    
    set /a key_log_count+=1
    
    :: 環境変数に保存
    set RPG_DEBUG_KEYLOG_COUNT=%key_log_count%
    set RPG_DEBUG_LOG1=%key_log_line_1%
    set RPG_DEBUG_LOG2=%key_log_line_2%
    set RPG_DEBUG_LOG3=%key_log_line_3%
    set RPG_DEBUG_LOG4=%key_log_line_4%
    set RPG_DEBUG_LOG5=%key_log_line_5%
    
    exit /b 0

:: ========== Errorlevel チェック専用ヘルパー関数 ==========

:: （不要になったため削除済み）


:: ========== セーブデータプレビューキャッシュロード ==========

:Load_All_Slots_Cache
    :: スロット 1〜3 のロード
    for /l %%i in (1,1,3) do (
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
    )
    
    :: 個別にパディング（16文字パディング）
    call :PadString slot_1_line_name "%slot_1_name%"
    call :PadString slot_1_line_level "%slot_1_level%"
    call :PadString slot_1_line_route "%slot_1_route%"
    
    call :PadString slot_2_line_name "%slot_2_name%"
    call :PadString slot_2_line_level "%slot_2_level%"
    call :PadString slot_2_line_route "%slot_2_route%"
    
    call :PadString slot_3_line_name "%slot_3_name%"
    call :PadString slot_3_line_level "%slot_3_level%"
    call :PadString slot_3_line_route "%slot_3_route%"
    
    :: スロット4〜9用（未実装）
    for /l %%i in (4,1,9) do (
        call :PadString slot_%%i_line_name "Coming Soon"
        call :PadString slot_%%i_line_level " "
        call :PadString slot_%%i_line_route " "
    )
    
    :: スロット 10〜12 用の15文字パディングを個別に作成
    call :PadString15 slot_10_line_name_15 "Coming Soon"
    call :PadString15 slot_10_line_level " "
    call :PadString15 slot_10_line_route " "
    
    call :PadString15 slot_11_line_name_15 "Coming Soon"
    call :PadString15 slot_11_line_level " "
    call :PadString15 slot_11_line_route " "
    
    call :PadString15 slot_12_line_name_15 "Coming Soon"
    call :PadString15 slot_12_line_level " "
    call :PadString15 slot_12_line_route " "
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

