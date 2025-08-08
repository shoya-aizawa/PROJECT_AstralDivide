@echo off

:: 通常の初期化・分岐
set "selector_mode=%1"
if "%selector_mode%"=="" set "selector_mode=CONTINUE"

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

:: 表示設定
set max_available_slots=3
set max_total_slots=12
set slots_per_row=4

:: カラーコード定義
set color_selected=7
set color_available=32
set color_coming_soon=90
set color_normal=0


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
    
    if %prereq_result%==0 exit /b 2031
    if %prereq_result%==1 goto :MainLoop
    if %prereq_result%==2000 (
        :: セーブデータが見つからない場合はメインメニューに戻る
        exit /b 2000
    )
    
    echo [Debug] Unexpected prereq_result=%prereq_result%
    timeout /t 5 >nul
    exit /b 2999
    :: 想定外


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
    cls
    echo.
    echo. %esc%[91m+---------------------------------------------+%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[93m         セーブデータが見つかりません        %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[97m    まずは「はじめから」でゲームを開始して   %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[97m        セーブデータを作成してください       %esc%[91m│%esc%[0m
    echo. %esc%[91m│%esc%[0m                                             %esc%[91m│%esc%[0m
    echo. %esc%[91m+---------------------------------------------+%esc%[0m
    echo.
    echo. %esc%[96mpress any key to continue%esc%[0m
    pause >nul
    exit /b 2000


:: ========== NEWGAME前提条件チェック ==========

:Check_NewGame_Prerequisites
    exit /b 1
    :: ここでは特に何もしない
    :: 今後の拡張予定 -- 未定





:: ================================
:: ========== メインループ =========
:: ================================

:MainLoop
    call :Initialize_Slot_Colors
    :: 初回のみ全体表示
    call :Display_SaveDataSelector

:SaveDataSelectLoop
    call :Update_Slot_Colors
    call :Quick_Update_Display
    call :GetChoice
    call :HandleKey %choice%
    if %errorlevel% geq 2000 exit /b %errorlevel%
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
    for /f "usebackq delims= eol=#" %%a in ("%src_display_tpl_dir%\[DEV]SelectSaveDataDisplay.txt") do (echo %%a)
    if %DEBUG_STATE%==1 (
        call :Display_Debug_Info
    )
    exit /b 0

:Quick_Update_Display
    :: 第1行のスロット（22-29行目）の外枠とスロット番号を更新

    echo %esc%[22;55H%esc%[%slot_1_color%m┌────────────────────┐%esc%[0m
    echo %esc%[23;55H%esc%[%slot_1_color%m│%esc%[0m[1]                 %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[24;55H%esc%[%slot_1_color%m│%esc%[0m                    %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[25;55H%esc%[%slot_1_color%m│%esc%[0m                    %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[26;55H%esc%[%slot_1_color%m│%esc%[0m                    %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[27;55H%esc%[%slot_1_color%m│%esc%[0m                    %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[28;55H%esc%[%slot_1_color%m│%esc%[0m                    %esc%[%slot_1_color%m│%esc%[0m
    echo %esc%[29;55H%esc%[%slot_1_color%m└────────────────────┘%esc%[0m
    
    echo %esc%[22;82H%esc%[%slot_2_color%m┌────────────────────┐%esc%[0m
    echo %esc%[23;82H%esc%[%slot_2_color%m│%esc%[0m[2]                 %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[24;82H%esc%[%slot_2_color%m│%esc%[0m                    %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[25;82H%esc%[%slot_2_color%m│%esc%[0m                    %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[26;82H%esc%[%slot_2_color%m│%esc%[0m                    %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[27;82H%esc%[%slot_2_color%m│%esc%[0m                    %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[28;82H%esc%[%slot_2_color%m│%esc%[0m                    %esc%[%slot_2_color%m│%esc%[0m
    echo %esc%[29;82H%esc%[%slot_2_color%m└────────────────────┘%esc%[0m
    
    echo %esc%[22;109H%esc%[%slot_3_color%m┌────────────────────┐%esc%[0m
    echo %esc%[23;109H%esc%[%slot_3_color%m│%esc%[0m[3]                 %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[24;109H%esc%[%slot_3_color%m│%esc%[0m                    %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[25;109H%esc%[%slot_3_color%m│%esc%[0m                    %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[26;109H%esc%[%slot_3_color%m│%esc%[0m                    %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[27;109H%esc%[%slot_3_color%m│%esc%[0m                    %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[28;109H%esc%[%slot_3_color%m│%esc%[0m                    %esc%[%slot_3_color%m│%esc%[0m
    echo %esc%[29;109H%esc%[%slot_3_color%m└────────────────────┘%esc%[0m
    
    echo %esc%[22;136H%esc%[%slot_4_color%m┌────────────────────┐%esc%[0m
    echo %esc%[23;136H%esc%[%slot_4_color%m│%esc%[0m[4]                 %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[24;136H%esc%[%slot_4_color%m│%esc%[0m                    %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[25;136H%esc%[%slot_4_color%m│%esc%[0m                    %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[26;136H%esc%[%slot_4_color%m│%esc%[0m                    %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[27;136H%esc%[%slot_4_color%m│%esc%[0m                    %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[28;136H%esc%[%slot_4_color%m│%esc%[0m                    %esc%[%slot_4_color%m│%esc%[0m
    echo %esc%[29;136H%esc%[%slot_4_color%m└────────────────────┘%esc%[0m
    
    :: 第2行のスロット（31-38行目）

    echo %esc%[31;55H%esc%[%slot_5_color%m┌────────────────────┐%esc%[0m
    echo %esc%[32;55H%esc%[%slot_5_color%m│%esc%[0m[5]                 %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[33;55H%esc%[%slot_5_color%m│%esc%[0m                    %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[34;55H%esc%[%slot_5_color%m│%esc%[0m                    %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[35;55H%esc%[%slot_5_color%m│%esc%[0m                    %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[36;55H%esc%[%slot_5_color%m│%esc%[0m                    %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[37;55H%esc%[%slot_5_color%m│%esc%[0m                    %esc%[%slot_5_color%m│%esc%[0m
    echo %esc%[38;55H%esc%[%slot_5_color%m└────────────────────┘%esc%[0m

    echo %esc%[31;82H%esc%[%slot_6_color%m┌────────────────────┐%esc%[0m
    echo %esc%[32;82H%esc%[%slot_6_color%m│%esc%[0m[6]                 %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[33;82H%esc%[%slot_6_color%m│%esc%[0m                    %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[34;82H%esc%[%slot_6_color%m│%esc%[0m                    %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[35;82H%esc%[%slot_6_color%m│%esc%[0m                    %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[36;82H%esc%[%slot_6_color%m│%esc%[0m                    %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[37;82H%esc%[%slot_6_color%m│%esc%[0m                    %esc%[%slot_6_color%m│%esc%[0m
    echo %esc%[38;82H%esc%[%slot_6_color%m└────────────────────┘%esc%[0m

    echo %esc%[31;109H%esc%[%slot_7_color%m┌────────────────────┐%esc%[0m
    echo %esc%[32;109H%esc%[%slot_7_color%m│%esc%[0m[7]                 %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[33;109H%esc%[%slot_7_color%m│%esc%[0m                    %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[34;109H%esc%[%slot_7_color%m│%esc%[0m                    %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[35;109H%esc%[%slot_7_color%m│%esc%[0m                    %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[36;109H%esc%[%slot_7_color%m│%esc%[0m                    %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[37;109H%esc%[%slot_7_color%m│%esc%[0m                    %esc%[%slot_7_color%m│%esc%[0m
    echo %esc%[38;109H%esc%[%slot_7_color%m└────────────────────┘%esc%[0m

    echo %esc%[31;136H%esc%[%slot_8_color%m┌────────────────────┐%esc%[0m
    echo %esc%[32;136H%esc%[%slot_8_color%m│%esc%[0m[8]                 %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[33;136H%esc%[%slot_8_color%m│%esc%[0m                    %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[34;136H%esc%[%slot_8_color%m│%esc%[0m                    %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[35;136H%esc%[%slot_8_color%m│%esc%[0m                    %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[36;136H%esc%[%slot_8_color%m│%esc%[0m                    %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[37;136H%esc%[%slot_8_color%m│%esc%[0m                    %esc%[%slot_8_color%m│%esc%[0m
    echo %esc%[38;136H%esc%[%slot_8_color%m└────────────────────┘%esc%[0m
    
    :: 第3行のスロット（40-47行目）

    echo %esc%[40;55H%esc%[%slot_9_color%m┌────────────────────┐%esc%[0m
    echo %esc%[41;55H%esc%[%slot_9_color%m│%esc%[0m[9]                 %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[42;55H%esc%[%slot_9_color%m│%esc%[0m                    %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[43;55H%esc%[%slot_9_color%m│%esc%[0m                    %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[44;55H%esc%[%slot_9_color%m│%esc%[0m                    %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[45;55H%esc%[%slot_9_color%m│%esc%[0m                    %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[46;55H%esc%[%slot_9_color%m│%esc%[0m                    %esc%[%slot_9_color%m│%esc%[0m
    echo %esc%[47;55H%esc%[%slot_9_color%m└────────────────────┘%esc%[0m

    echo %esc%[40;82H%esc%[%slot_10_color%m┌────────────────────┐%esc%[0m
    echo %esc%[41;82H%esc%[%slot_10_color%m│%esc%[0m[10]                %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[42;82H%esc%[%slot_10_color%m│%esc%[0m                    %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[43;82H%esc%[%slot_10_color%m│%esc%[0m                    %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[44;82H%esc%[%slot_10_color%m│%esc%[0m                    %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[45;82H%esc%[%slot_10_color%m│%esc%[0m                    %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[46;82H%esc%[%slot_10_color%m│%esc%[0m                    %esc%[%slot_10_color%m│%esc%[0m
    echo %esc%[47;82H%esc%[%slot_10_color%m└────────────────────┘%esc%[0m

    echo %esc%[40;109H%esc%[%slot_11_color%m┌────────────────────┐%esc%[0m
    echo %esc%[41;109H%esc%[%slot_11_color%m│%esc%[0m[11]                %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[42;109H%esc%[%slot_11_color%m│%esc%[0m                    %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[43;109H%esc%[%slot_11_color%m│%esc%[0m                    %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[44;109H%esc%[%slot_11_color%m│%esc%[0m                    %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[45;109H%esc%[%slot_11_color%m│%esc%[0m                    %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[46;109H%esc%[%slot_11_color%m│%esc%[0m                    %esc%[%slot_11_color%m│%esc%[0m
    echo %esc%[47;109H%esc%[%slot_11_color%m└────────────────────┘%esc%[0m

    echo %esc%[40;136H%esc%[%slot_12_color%m┌────────────────────┐%esc%[0m
    echo %esc%[41;136H%esc%[%slot_12_color%m│%esc%[0m[12]                %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[42;136H%esc%[%slot_12_color%m│%esc%[0m                    %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[43;136H%esc%[%slot_12_color%m│%esc%[0m                    %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[44;136H%esc%[%slot_12_color%m│%esc%[0m                    %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[45;136H%esc%[%slot_12_color%m│%esc%[0m                    %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[46;136H%esc%[%slot_12_color%m│%esc%[0m                    %esc%[%slot_12_color%m│%esc%[0m
    echo %esc%[47;136H%esc%[%slot_12_color%m└────────────────────┘%esc%[0m
    
    :: デバッグモード時のみ統合更新
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
    )
    exit /b 0

:Update_All_Debug_Info
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
    if %errorlevel% geq 2000 exit /b %errorlevel%
    
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
    if %errorlevel% geq 2000 (exit /b %errorlevel%)

    if %key%==17 call :Handle_Back
    if %errorlevel% geq 2000 (exit /b %errorlevel%)

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
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Enter.wav"
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )
    call :HandleSelection
    exit /b %retcode%

:Handle_Back
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Cancel.wav"
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
        timeout /t 1 >nul
    )
    
    :: Qキーでのキャンセルは2099を返す
    set retcode=2099
    exit /b %retcode%

:Handle_Move_Left
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Left_1
    exit /b 0

:Handle_Move_Right
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Right_1
    exit /b 0

:Handle_Move_Down
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Down_4
    exit /b 0

:Handle_Move_Up
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Up_4
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

:Move_Up_4
    set /a new_slot=%current_selected_slot% - 4
    if %new_slot% lss 1 set new_slot=%current_selected_slot%
    set current_selected_slot=%new_slot%
    exit /b 0

:Move_Left_1
    set /a new_slot=%current_selected_slot% - 1
    if %new_slot% lss 1 set new_slot=%max_total_slots%
    set current_selected_slot=%new_slot%
    exit /b 0

:Move_Down_4
    set /a new_slot=%current_selected_slot% + 4
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
        exit /b %retcode%
    ) else if "%selector_mode%"=="NEWGAME" (
        call :Handle_NewGame_Selection
        if %DEBUG_STATE%==1 (
            echo %esc%[29;2H%esc%[K[%current_time%]%esc%[0m
            call echo %%esc%%[30;2H%%esc%%[K%%esc%%[91m[DEBUG] ReturnCode from Handle_NewGame_Selection = %%retcode%% %%esc%%[0m
        )
        exit /b %retcode%
    )
    exit /b 2000

:Handle_Continue_Selection
    :: デバッグ情報表示
    if %DEBUG_STATE%==1 (
        echo %esc%[27;2H%esc%[K[%current_time%]%esc%[0m
        echo %esc%[28;2H%esc%[K%esc%[91m[DEBUG] Handle_Continue_Selection: Slot=%current_selected_slot% %esc%[0m
        timeout /t 1 >nul
    )
    if %current_selected_slot% leq %max_available_slots% (
        if exist "%cd_savedata%\SaveData_%current_selected_slot%.txt" (
            call :Preview_SaveData %current_selected_slot%
            call :Confirm_LoadGame %current_selected_slot%
            if !errorlevel! == 1 (
                set temp_confirmed=1
            ) else (
                set temp_confirmed=0
            )
            if %temp_confirmed%==1 (
                :: 設計書準拠：2030 + スロット番号
                set /a retcode=2030 + %current_selected_slot%
                if %DEBUG_STATE%==1 (
                    echo %esc%[15;1H%esc%[K%esc%[91m [DEBUG] Continue confirmed: retcode=%retcode% %esc%[0m
                    timeout /t 2 >nul
                )
                exit /b %retcode%
            ) else (
                exit /b 0
            )
        ) else (
            echo %esc%[20;92H%esc%[41;97m このスロットにはデータがありません %esc%[0m
            timeout /t 2 >nul
            echo %esc%[20;92H%esc%[K
            exit /b 0
        )
    )
    
    if %current_selected_slot% gtr %max_available_slots% (
        echo %esc%[20;92H%esc%[41;97m このスロットは開発中です %esc%[0m
        timeout /t 1 >nul
        echo %esc%[20;92H%esc%[K
        exit /b 0
    )
    
    :: 設計書準拠：キャンセルは2099
    exit /b 2099

:Handle_NewGame_Selection
    :: デバッグ情報表示
    if %DEBUG_STATE%==1 (
        echo %esc%[27;2H%esc%[K[%current_time%]%esc%[0m
        echo %esc%[28;2H%esc%[K%esc%[91m[DEBUG] Handle_Continue_Selection: Slot=%current_selected_slot% %esc%[0m
        timeout /t 1 >nul
    )
    if %current_selected_slot% leq %max_available_slots% (
        if exist "%cd_savedata%\SaveData_%current_selected_slot%.txt" (
            call :Confirm_Overwrite %current_selected_slot%
            if %errorlevel%==1 (
                set /a retcode=2070 + %current_selected_slot%
                exit /b %retcode%
            ) else (
                exit /b 0
            )
        ) else (
            call :Confirm_CreateNew %current_selected_slot%
            setlocal EnableDelayedExpansion
            if !retcode!==1 (
                endlocal
                set /a retcode=2050 + %current_selected_slot%
                exit /b 1
            ) else (
                exit /b 0
            )
        )
    )

    if %current_selected_slot% gtr %max_available_slots% (
        echo %esc%[20;92H%esc%[41;97m This slot is under development %esc%[0m
        timeout /t 1 >nul
        echo %esc%[20;92H%esc%[K
        exit /b 0
    )

    exit /b 2099



:Confirm_LoadGame
    echo %esc%[20;92H%esc%[93m このデータをロードしますか？ (F=はい/Q=いいえ) %esc%[0m
    call :Process_Dialog_Input "LOAD"
    set choice=%errorlevel%
    echo %esc%[20;92H%esc%[K
    
    if %choice%==1 (
        exit /b 1
    ) else (
        exit /b 0
    )

:Confirm_Overwrite
    echo %esc%[20;92H%esc%[93m 既存のデータを上書きしますか？ (F=はい/Q=いいえ) %esc%[0m
    call :Process_Dialog_Input "OVERWRITE"
    set choice=%errorlevel%
    echo %esc%[20;92H%esc%[K
    
    if %choice%==1 (
        exit /b 1
    ) else (
        exit /b 0
    )

:Confirm_CreateNew
    echo %esc%[20;92H%esc%[93m 新しいゲームを開始しますか？ (F=はい/Q=いいえ) %esc%[0m
    call :Process_Dialog_Input CREATE
    echo %esc%[20;92H%esc%[K

    if %errorlevel%==1 (
        start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Enter3.wav"
        set retcode=1
        exit /b 1
    ) else (
        start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Cancel.wav"
        set retcode=0
        exit /b 0
    )

:Preview_SaveData
    set slot_num=%1
    if exist "%cd_savedata%\SaveData_%slot_num%.txt" (
        echo %esc%[20;92H%esc%[96m [Preview] Slot %slot_num% データ確認中... %esc%[0m
        timeout /t 1 >nul
        echo %esc%[20;92H%esc%[K
    )
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
