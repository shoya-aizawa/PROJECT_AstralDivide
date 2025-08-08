@echo off

:: デバッグ状態継承（環境変数から）
if not defined DEBUG_STATE set DEBUG_STATE=0

:: デバッグ状態確認出力
if %DEBUG_STATE%==1 (
    echo %esc%[K%esc%[93m [DEBUG-MMM] MMM Starting: DEBUG_STATE=%DEBUG_STATE% %esc%[0m
    timeout /t 2 >nul
)


:: ========== デバッグ変数初期化 ==========

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



:: ========== 変数初期化 ==========

:: 返り値の初期化
set retcode=0

:: 現在選択中のメニュー項目（1-4対応）
set current_selected_menu=1

:: 表示設定
set max_menu_items=4

:: カラーコード定義
set color_selected=7
set color_available=32
set color_unavailable=90
set color_normal=0









:: ========== メインループ ==========

:MainMenuLoop
    call :Initialize_Menu_Colors
    call :Display_MainMenu

:MenuInputLoop
    call :Update_Menu_Colors
    call :Quick_Update_Display
    call :GetChoice
    call :HandleKey %choice%
    if %errorlevel% geq 1000 (
        if %DEBUG_STATE%==1 (
            echo %esc%[10;2H%esc%[K%esc%[91m[DEBUG-MMM] ReturnCode: %retcode% %esc%[0m
            timeout /t 1 >nul
        )
        exit /b %retcode%
    )
    goto :MenuInputLoop































:: ========== カラー管理システム ==========

:Initialize_Menu_Colors
    :: 全メニュー項目を利用可能色に初期化
    set menu_1_color=%color_available%
    set menu_2_color=%color_available%
    set menu_3_color=%color_available%
    set menu_4_color=%color_available%

    :: 最初のメニュー項目を選択状態にする
    set menu_1_color=%color_selected%
    exit /b 0

:Update_Menu_Colors
    :: 全メニュー項目を通常色にリセット
    set menu_1_color=%color_available%
    set menu_2_color=%color_available%
    set menu_3_color=%color_unavailable%
    set menu_4_color=%color_available%

    :: 選択中のメニュー項目のみ反転表示
    if "%current_selected_menu%"=="1" set menu_1_color=%color_selected%
    if "%current_selected_menu%"=="2" set menu_2_color=%color_selected%
    if "%current_selected_menu%"=="3" set menu_3_color=%color_selected%
    if "%current_selected_menu%"=="4" set menu_4_color=%color_selected%
    exit /b 0

:: ========== メニュー表示システム ==========

:Display_MainMenu
    :: 画面を常にクリア
    cls

    :: MainMenuDisplay.txtを表示
    for /f "usebackq delims= eol=#" %%a in ("%src_display_tpl_dir%\MainMenuDisplay.txt") do (echo %%a)

    :: デバッグモード時の追加処理
    if %DEBUG_STATE%==1 (
        :: デバッグタイトルを表示
        echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m

        :: 初回のみDebug_Info表示
        if not defined debug_initialized (
            call :Display_Debug_Info
            set debug_initialized=1
        )
        call :Display_Debug_Info
    ) else (
        set debug_initialized=
    )
    exit /b 0

:: ========== キー入力待機 ==========

:GetChoice
    choice /n /c ABCDEFGHIJKLMNOPQRSTUVWXYZ >nul
    set choice=%errorlevel%
    exit /b 0

:: ========== 入力処理システム ==========

:HandleKey
    set key=%1
    set debug_current_key=%key%
    set debug_breakpoint_hit=0
    call :Process_Common_Key_Tasks %key%
    call :Execute_Key_Action %key%
    if %retcode% geq 1000 exit /b %retcode%
    call :Process_Hidden_Sequences
    call :Check_Sequence_Length
    exit /b 0

:Process_Common_Key_Tasks
    set key=%1
    if %DEBUG_STATE%==1 (
        call :Add_Key_Log %key%
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
    if %retcode% geq 1000 (exit /b %retcode%)

    :: 無効キーは何もしない（ログは既に記録済み）
    if %key%==1 call :Handle_Invalid_Key %key%
    if %key%==4 call :Handle_Invalid_Key_With_Sequence %key%

    :: 移動キー（統一処理）
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
    :: retcode設定とデバッグ表示
    if "%current_selected_menu%"=="1" set "retcode=1001"
    if "%current_selected_menu%"=="2" set "retcode=1002"
    if "%current_selected_menu%"=="3" set "retcode=1003"
    if "%current_selected_menu%"=="4" set "retcode=1099"
    if %DEBUG_STATE%==1 (
        echo %esc%[8;1H%esc%[K%esc%[91m [DEBUG-MMM] Handle_Select: Menu=%current_selected_menu% RetCode=%retcode% %esc%[0m
        echo %esc%[9;1H%esc%[K%esc%[93m [DEBUG-MMM] About to exit with code: %retcode% %esc%[0m
        timeout /t 2 >nul
    )
    exit /b %retcode%

:Handle_Move_Down
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Down
    exit /b 0

:Handle_Move_Up
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
    call :Move_Up
    exit /b 0

:Handle_Invalid_Key
    set key_name=%~1
    :: 無効キーは何もしない（ログは既に記録済み）
    exit /b 0

:Handle_Invalid_Key_With_Sequence
    set key_name=%~1
    :: Dキーは無効だがCOORDシーケンスの処理は必要
    if "%hidden_sequence%"=="COOR" (
        set hidden_sequence=COORD
    ) else (
        set hidden_sequence=
    )
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
    start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Beep.wav"
    set hidden_sequence=X
    exit /b 0

:Sequence_Rule_Y
    if "%hidden_sequence%"=="X" (
        start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Beep.wav"
        set hidden_sequence=XY
    ) else (
        set hidden_sequence=Y
    )
    exit /b 0

:Sequence_Rule_Z
    if "%hidden_sequence%"=="XY" (
        start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Beep.wav"
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
        call "%src_debug_dir%\InteractivePicker.bat" "MainMenu" "%current_selected_menu%"
        call :Refresh_Display
        exit /b 0
    )

    :: COORDコマンド発動
    if /i "%hidden_sequence%"=="COORD" (
        set hidden_sequence=
        call "%src_debug_dir%\CoordinateDebugTool.bat" "MainMenu"
        call :Refresh_Display
        exit /b 0
    )

    :: シーケンス長制限（10文字以上でリセット）
    call :Check_Sequence_Length

    exit /b 0




:Check_Sequence_Length
    :: hidden_sequenceの長さをチェック（10文字以上でリセット）
    if defined hidden_sequence (
        if "%hidden_sequence:~10,1%" neq "" (
            set hidden_sequence=
        )
    )
    exit /b 0


:: ========== 表示更新システム ==========

:Quick_Update_Display
    :: メニュー項目は常に部分更新（チカチカ防止）
    echo %esc%[36;99H%esc%[%menu_1_color%m   New Game   %esc%[0m
    echo %esc%[38;99H%esc%[%menu_2_color%m   Continue   %esc%[0m
    echo %esc%[42;99H%esc%[%menu_3_color%m   Settings   %esc%[0m
    echo %esc%[44;99H%esc%[%menu_4_color%m     Quit     %esc%[0m
    :: デバッグモード時の統合更新
    if %DEBUG_STATE%==1 (
        call :Update_All_Debug_Info
    )
    exit /b 0

:Update_All_Debug_Info
    :: デバッグタイトル維持（統一形式）
    echo %esc%[1;1H%esc%[K
    echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m
    
    :: 動的情報の更新
    set current_time=%time:~0,8%
    echo %esc%[2;1H%esc%[K%esc%[93m [%current_time%] Menu: %current_selected_menu%/%max_menu_items% LastKey: %key% %esc%[0m
    echo %esc%[3;1H%esc%[K%esc%[96m Available: %max_menu_items% KeyCount: %key_log_count% %esc%[0m
    echo %esc%[4;1H%esc%[K%esc%[97m Sequence: [%hidden_sequence%] DebugState: %DEBUG_STATE% %esc%[0m

    :: ステータス行の更新
    set status_line=
    if "%current_selected_menu%"=="1" set status_line=[*1][ 2][ 3][ 4]
    if "%current_selected_menu%"=="2" set status_line=[ 1][*2][ 3][ 4]
    if "%current_selected_menu%"=="3" set status_line=[ 1][ 2][*3][ 4]
    if "%current_selected_menu%"=="4" set status_line=[ 1][ 2][ 3][*4]

    echo %esc%[5;1H%esc%[K%esc%[95m MenuItems: %status_line% %esc%[0m
    echo %esc%[6;1H%esc%[K%esc%[94m Commands: W/S=Move F=Select XYZ=Debug %esc%[0m

    :: 拡張デバッグ情報：ブレークポイント
    echo %esc%[8;1H%esc%[K%esc%[93m Breakpoint: %debug_breakpoint_enabled% %esc%[0m

    :: キー押下履歴の更新
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
    if %DEBUG_STATE%==0 (
        set DEBUG_STATE=1
        set debug_initialized=
        echo %esc%[1;1H%esc%[43;30m [DEBUG] FALSE -^> TRUE %esc%[0m
        timeout /t 1 >nul
        echo %esc%[1;1H%esc%[K

        :: 環境変数に状態を保存
        set RPG_DEBUG_KEYLOG_COUNT=%key_log_count%
        set RPG_DEBUG_LOG1=%key_log_line_1%
        set RPG_DEBUG_LOG2=%key_log_line_2%
        set RPG_DEBUG_LOG3=%key_log_line_3%
        set RPG_DEBUG_LOG4=%key_log_line_4%
        set RPG_DEBUG_LOG5=%key_log_line_5%

        call :Display_Debug_Info
    ) else (
        set DEBUG_STATE=0
        set debug_initialized=
        call :Clear_Debug_Info
        echo %esc%[1;1H%esc%[42;30m [DEBUG] TRUE -^> FALSE %esc%[0m
        timeout /t 1 >nul
        echo %esc%[1;1H%esc%[K

        :: 環境変数をクリア
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
    :: 現在時刻を取得
    set current_time=%time:~0,8%

    :: デバッグタイトルを統一形式で表示
    echo %esc%[1;1H%esc%[K
    echo %esc%[1;1H%esc%[43;30m MainMenuModule: Debug Mode %esc%[0m

    :: 初回表示時の固定部分のみ描画
    echo %esc%[2;1H%esc%[93m [%current_time%] Menu: %current_selected_menu%/%max_menu_items% LastKey: %key% %esc%[0m
    echo %esc%[3;1H%esc%[96m Available: %max_menu_items% KeyCount: %key_log_count% %esc%[0m
    echo %esc%[4;1H%esc%[K%esc%[97m Sequence: [%hidden_sequence%] DebugState: %DEBUG_STATE% %esc%[0m

    :: メニュー項目の動的状態表示
    set status_line=
    if "%current_selected_menu%"=="1" set status_line=[*1][ 2][ 3][ 4]
    if "%current_selected_menu%"=="2" set status_line=[ 1][*2][ 3][ 4]
    if "%current_selected_menu%"=="3" set status_line=[ 1][ 2][*3][ 4]
    if "%current_selected_menu%"=="4" set status_line=[ 1][ 2][ 3][*4]

    echo %esc%[5;1H%esc%[95m MenuItems: %status_line% %esc%[0m
    echo %esc%[6;1H%esc%[94m Commands: W/S=Move F=Select XYZ=Debug %esc%[0m

    :: 拡張デバッグ情報：ブレークポイント
    echo %esc%[8;1H%esc%[93m Breakpoint: %debug_breakpoint_enabled% %esc%[0m

    :: キー押下履歴の初期表示
    echo %esc%[20;1H%esc%[90m Key History (MainMenuModule): %esc%[0m
    echo %esc%[21;1H%esc%[37m %esc%[0m
    echo %esc%[22;1H%esc%[37m %esc%[0m
    echo %esc%[23;1H%esc%[37m %esc%[0m
    echo %esc%[24;1H%esc%[37m %esc%[0m
    echo %esc%[25;1H%esc%[37m %esc%[0m

    exit /b 0

:Clear_Debug_Info
    :: デバッグ情報とキーログをクリア
    for /l %%i in (1,1,30) do (
        echo %esc%[%%i;1H%esc%[K
    )

    :: キーログ変数をクリア
    set key_log_count=
    set key_log_line_1=
    set key_log_line_2=
    set key_log_line_3=
    set key_log_line_4=
    set key_log_line_5=

    exit /b 0


:Add_Key_Log
    set key_pressed=%1
    set /a key_log_count+=1

    :: 簡単な時刻取得
    set current_time=%time:~0,8%


    :: キー名を人間が読める形に変換
    set key_name=UNKNOWN
    if "%key_pressed%"=="1" set key_name=A(LEFT-INVALID)
    if "%key_pressed%"=="2" set key_name=B(Hidden)
    if "%key_pressed%"=="3" set key_name=C(Hidden)
    if "%key_pressed%"=="4" set key_name=D(RIGHT-INVALID)
    if "%key_pressed%"=="5" set key_name=E(WIP)
    if "%key_pressed%"=="6" set key_name=F(SELECT)
    if "%key_pressed%"=="7" set key_name=G(WIP)
    if "%key_pressed%"=="8" set key_name=H(WIP)
    if "%key_pressed%"=="9" set key_name=I(Hidden)
    if "%key_pressed%"=="10" set key_name=J(WIP)
    if "%key_pressed%"=="11" set key_name=K(Hidden)
    if "%key_pressed%"=="12" set key_name=L(WIP)
    if "%key_pressed%"=="13" set key_name=M(WIP)
    if "%key_pressed%"=="14" set key_name=N(WIP)
    if "%key_pressed%"=="15" set key_name=O(Hidden)
    if "%key_pressed%"=="16" set key_name=P(Hidden)
    if "%key_pressed%"=="17" set key_name=Q(WIP)
    if "%key_pressed%"=="18" set key_name=R(Hidden)
    if "%key_pressed%"=="19" set key_name=S(DOWN)
    if "%key_pressed%"=="20" set key_name=T(WIP)
    if "%key_pressed%"=="21" set key_name=U(WIP)
    if "%key_pressed%"=="22" set key_name=V(WIP)
    if "%key_pressed%"=="23" set key_name=W(UP)
    if "%key_pressed%"=="24" set key_name=X(Hidden)
    if "%key_pressed%"=="25" set key_name=Y(Hidden)
    if "%key_pressed%"=="26" set key_name=Z(Hidden)
    if "%key_pressed%"=="UNKNOWN_KEY" set key_name=(UNKNOWN)

    :: ログをシフト（最新5件を保持）
    set key_log_line_5=%key_log_line_4%
    set key_log_line_4=%key_log_line_3%
    set key_log_line_3=%key_log_line_2%
    set key_log_line_2=%key_log_line_1%
    set key_log_line_1=[%current_time%] #%key_log_count% %key_name% - Menu:%current_selected_menu%

    :: 隠しコマンド判定（4文字コード）
    if "%hidden_sequence%"=="pick" (
        call "%src_debug_dir%\InteractivePicker.bat" "MainMenu" "%current_selected_menu%"
        call :Refresh_Display
        set hidden_sequence=
        set key_log_count=0
        exit /b 0
    )
    if "%hidden_sequence%"=="coord" (
        call "%src_debug_dir%\CoordinateDebugTool.bat" "MainMenu"
        call :Refresh_Display
        set hidden_sequence=
        set key_log_count=0
        exit /b 0
    )
    if "%hidden_sequence%"=="xyz" (
        call :Activate_Debug_Mode
        set hidden_sequence=
        set key_log_count=0
        exit /b 0
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
        set debug_breakpoint_hit=0
        echo %esc%[12;1H%esc%[42;30m Breakpoint ENABLED %esc%[0m
    ) else (
        set debug_breakpoint_enabled=0
        set debug_breakpoint_hit=0
        echo %esc%[12;1H%esc%[43;30m Breakpoint DISABLED %esc%[0m
    )
    timeout /t 1 >nul
    echo %esc%[12;1H%esc%[K
    exit /b 0




:Refresh_Display
    :: 画面を再描画
    cls
    call :Display_MainMenu
    exit /b 0

:: ========== カラーテーマ変更システム ==========

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

:: ========== メニュー項目の有効/無効制御 ==========

:Set_Menu_Availability
    :: 引数: メニュー番号 状態（available/unavailable）
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

:: ========== 移動処理関数 ==========

:Move_Up
    set /a new_menu=%current_selected_menu% - 1
    if %new_menu% lss 1 set new_menu=%max_menu_items%
    set current_selected_menu=%new_menu%
    call :Update_Menu_Colors
    call :Quick_Update_Display
    exit /b 0

:Move_Left
    :: Aキーは無効なので無視
    exit /b 0

:Move_Down
    set /a new_menu=%current_selected_menu% + 1
    if %new_menu% gtr %max_menu_items% set new_menu=1
    set current_selected_menu=%new_menu%
    call :Update_Menu_Colors
    call :Quick_Update_Display
    exit /b 0

:Move_Right
    :: Dキーは無効なので無視
    exit /b 0

:: ========== Errorlevel チェック専用ヘルパー関数 ==========


