@echo off
title %~2
set "REMOTE_STREAMER_STOP_FILE=%PROJECT_ROOT%\Config\Logs\ad_streamer.stop"
set "IS_DEBUG_MODE=0"
if /i "%~3"=="DEBUG" set "IS_DEBUG_MODE=1"

:: Load dynamic console size from user config or default to 90x35
if not defined CONSOLE_COLS set "CONSOLE_COLS=90"
if not defined CONSOLE_ROWS set "CONSOLE_ROWS=35"
mode %CONSOLE_COLS%,%CONSOLE_ROWS%

set "IS_CONSOLAS="
if defined SELECTED_FONT if /i "%SELECTED_FONT%"=="Consolas" set "IS_CONSOLAS=1"
if not defined IS_CONSOLAS if defined CONSOLE_FONT if /i "%CONSOLE_FONT%"=="Consolas" set "IS_CONSOLAS=1"
if not defined IS_CONSOLAS if defined PROJECT_ROOT if exist "%PROJECT_ROOT%\Config\user_config.env" (
    findstr /i /c:"CONSOLE_FONT=Consolas" "%PROJECT_ROOT%\Config\user_config.env" >nul
    if not errorlevel 1 set "IS_CONSOLAS=1"
)

if "%IS_CONSOLAS%"=="1" (
    powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" > "%TEMP%\ad_ps_main_f11.tmp" 2>&1
    if exist "%TEMP%\ad_ps_main_f11.tmp" del "%TEMP%\ad_ps_main_f11.tmp" >nul 2>&1
) else (
    powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1
)
:: ==================================================
:: Astral Divide - Main.bat (v0.2.0)
:: Role: Game Core / State Orchestrator
:: ==================================================

:: --------------------------------------------------
:: [0] Encoding & Launch Guard
:: --------------------------------------------------
if not "%~1"=="65001" goto :ENCODING_ERROR
chcp %~1 >nul

if not defined RCSU set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

:: DEV MODE (optional)
if "%IS_DEBUG_MODE%"=="1" (
    set DEBUG_STATE=1
) else if "%~2"=="DEV" (
    set DEBUG_STATE=1
) else (
    if not defined DEBUG_STATE set DEBUG_STATE=0
)

:: --------------------------------------------------
:: [1] Environment Initialization
:: --------------------------------------------------
call "%src_systems_dir%\InitializeModule.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FATAL_ERROR
if exist "%RCSU%" call "%RCSU%" -trace INFO Main "InitializeModule ok"
call "%src_savesys_dir%\SaveDataDetectSystem.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FATAL_ERROR
if exist "%RCSU%" call "%RCSU%" -trace INFO Main "SaveDataDetectSystem ok"
rem pause
call "%src_display_dir%\BootCompleteDisplay.bat"
rem pause
set "MAINMENU_NEEDS_REFRESH=1"
call :Prepare_MainMenu_Presentation

:: Apply user-configured font automatically
if defined CONSOLE_FONT (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        if exist "%tools_dir%\cmdwiz.exe" (
            timeout /t 1 /nobreak >nul
            call "%tools_dir%\cmdwiz.exe" setfont "%tools_dir%\%CONSOLE_FONT%.fnt" >nul 2>&1
            timeout /t 1 /nobreak >nul
        )
    )
)

:: --------------------------------------------------
:: [2] Main State Loop
:: --------------------------------------------------
:STATE_MAINMENU
    if "%MAINMENU_NEEDS_REFRESH%"=="1" call :Prepare_MainMenu_Presentation
    call :Reset_UI_Context
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "enter STATE_MAINMENU"

    call "%src_display_dir%\MainMenuModule.bat"
    if not "%errorlevel%"=="%RC_OK%" goto :UI_ERROR
    call :Trace_UI_Return "MMM returned"

    goto :Route_MainMenu_Action



:: ==================================================
:: ========== ROUTERS =================================
:: ==================================================

:Route_MainMenu_Action
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "route action=%UI_ACTION%"
    if "%UI_ACTION%"=="MAINMENU_NEWGAME"   goto :STATE_NEWGAME
    if "%UI_ACTION%"=="MAINMENU_CONTINUE"  goto :STATE_CONTINUE
    if "%UI_ACTION%"=="MAINMENU_SETTINGS"  goto :STATE_SETTINGS
    if "%UI_ACTION%"=="EXIT"               goto :STATE_EXIT

    rem 想定外
    goto :STATE_MAINMENU



:: ==================================================
:: ========== STATES ==================================
:: ==================================================

:STATE_NEWGAME
    call :Reset_UI_Context
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "enter STATE_NEWGAME"
    call "%src_savesys_dir%\SaveDataSelector.bat" NEWGAME
    if not "%errorlevel%"=="%RC_OK%" goto :STATE_MAINMENU
    call :Trace_UI_Return "SDS NEWGAME returned"

    if "%UI_ACTION%"=="CANCEL" goto :STATE_MAINMENU
    if "%UI_ACTION%"=="NEWGAME_CREATE" (
        call :Start_NewGameSession %UI_PARAM% CreateNew
        if errorlevel 642 goto :STATE_EXIT
        if errorlevel 641 (
            set "MAINMENU_NEEDS_REFRESH=1"
            goto :STATE_MAINMENU
        )
        if errorlevel 604 (
            set "MAINMENU_NEEDS_REFRESH=1"
            goto :STATE_MAINMENU
        )
        goto :STATE_SCENARIO
    )
    if "%UI_ACTION%"=="NEWGAME_OVERWRITE" (
        call :Start_NewGameSession %UI_PARAM% Overwrite
        if errorlevel 642 goto :STATE_EXIT
        if errorlevel 641 (
            set "MAINMENU_NEEDS_REFRESH=1"
            goto :STATE_MAINMENU
        )
        if errorlevel 604 (
            set "MAINMENU_NEEDS_REFRESH=1"
            goto :STATE_MAINMENU
        )
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_CONTINUE
    call :Reset_UI_Context
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "enter STATE_CONTINUE"
    call "%src_savesys_dir%\SaveDataSelector.bat" CONTINUE
    if not "%errorlevel%"=="%RC_OK%" goto :STATE_MAINMENU
    call :Trace_UI_Return "SDS CONTINUE returned"

    if "%UI_ACTION%"=="CANCEL" goto :STATE_MAINMENU
    if "%UI_ACTION%"=="CONTINUE" (
        call :Start_ContinueGameSession %UI_PARAM%
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_SETTINGS
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "enter STATE_SETTINGS"
    call "%src_display_dir%\SettingsMenu.bat"
    if "%UI_ACTION%"=="SYSTEM_INIT_RESET" goto :STATE_RESET_SYSTEM
    goto :STATE_MAINMENU


:STATE_RESET_SYSTEM
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "enter STATE_RESET_SYSTEM"
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    start "" /d "%PROJECT_ROOT%" cmd.exe /c call "%PROJECT_ROOT%\AstralDivide.bat" -first
    if defined runtime_ipc_dir if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
    if defined REMOTE_STREAMER_STOP_FILE > "%REMOTE_STREAMER_STOP_FILE%" echo STOP
    if defined runtime_ipc_dir > "%runtime_ipc_dir%\.stop" echo STOP
    if defined runtime_ipc_dir > "%runtime_ipc_dir%\.restart_first" echo RESTART_ALREADY_STARTED
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "started new launcher and requested watchdog stop"
    if "%IS_DEBUG_MODE%"=="1" (
        exit /b 0
    ) else (
        exit
    )


:STATE_SCENARIO
    call :JumpToEpisode %player_storyroute%
    set "scenario_rc=%errorlevel%"
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "STATE_SCENARIO returned rc=%scenario_rc% route=%player_storyroute% scene=%current_scene%"
    if "%scenario_rc%"=="602" (
        echo セーブ完了、ゲームを終了します。
        goto :STATE_EXIT
    )
    if "%scenario_rc%"=="603" (
        echo セーブ失敗。緊急停止します。
        pause
        goto :STATE_EXIT
    )
    if "%scenario_rc%"=="604" (
        echo プレイヤーによって中断されました。
        set "MAINMENU_NEEDS_REFRESH=1"
        goto :STATE_MAINMENU
    )
    if "%scenario_rc%"=="641" (
        echo Pause menu requested return to title.
        set "MAINMENU_NEEDS_REFRESH=1"
        goto :STATE_MAINMENU
    )
    if "%scenario_rc%"=="642" (
        echo Pause menu requested exit.
        goto :STATE_EXIT
    )
    if "%scenario_rc%"=="606" (
        echo Pause menu requested exit.
        goto :STATE_EXIT
    )
    goto :STATE_SCENARIO


:STATE_EXIT
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    echo %esc%[6m%esc%[92mThank you for playing.%esc%[0m
    if defined runtime_ipc_dir if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
    if defined REMOTE_STREAMER_STOP_FILE > "%REMOTE_STREAMER_STOP_FILE%" echo STOP
    if defined runtime_ipc_dir > "%runtime_ipc_dir%\.stop" echo STOP
    if defined runtime_ipc_dir > "%runtime_ipc_dir%\.shutdown" echo SHUTDOWN
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "requested clean shutdown"
    if "%IS_DEBUG_MODE%"=="1" (
        exit /b 0
    ) else (
        exit
    )



:: ==================================================
:: ========== UTILITIES ===============================
:: ==================================================

:Reset_UI_Context
    set UI_ACTION=
    set UI_PARAM=
    exit /b 0

:Trace_UI_Return
    if not exist "%RCSU%" exit /b 0
    set "_trace_param=%UI_PARAM%"
    if not defined _trace_param set "_trace_param=(none)"
    call "%RCSU%" -trace INFO Main "%~1 action=%UI_ACTION% param=%_trace_param%"
    set "_trace_param="
    exit /b 0

:Prepare_MainMenu_Presentation
    call :Resolve_Menu_Bgm
    call "%src_audio_dir%\Play_BGM.bat" "%MENU_BGM_PATH%" repeat %BGM_VOLUME%
    call "%tools_dir%\cmdbkg.exe" "%assets_images_dir%\AD_Title_Image.png" /b
    set "MAINMENU_NEEDS_REFRESH=0"
    if exist "%RCSU%" call "%RCSU%" -trace INFO Main "mainmenu presentation refreshed"
    exit /b 0


:Resolve_Menu_Bgm
    set "MENU_BGM_PATH=%assets_sounds_starfall_dir%\StarFallHill.wav"
    if /i "%BGM_SOUNDTRACK%"=="ETERNAL" set "MENU_BGM_PATH=%PROJECT_ROOT%\Assets\Sounds\EternalGround\EternalGround.wav"
    if /i "%BGM_SOUNDTRACK%"=="REVELATION" set "MENU_BGM_PATH=%PROJECT_ROOT%\Assets\Sounds\RevelationOfGod\RevelationOfGod.wav"
    if /i "%BGM_SOUNDTRACK%"=="BATTLE" set "MENU_BGM_PATH=%PROJECT_ROOT%\Assets\Sounds\BattleMusic.wav"
    exit /b 0


:JumpToEpisode
    set "SCENARIO_SKIP_ACTIVE="
    set "current_save_supported=0"
    set "resume_storyroute="
    set "resume_scene="
    set "resume_location="
    if "%~1"=="NewGame" call "%src_scene_newgame_dir%\NewGame.bat"
    if "%~1"=="Prologue" call "%src_scene_newgame_dir%\NewGame.bat"
    if "%~1"=="PrologueComplete" call "%src_scene_newgame_dir%\PrologueComplete.bat"
    if "%~1"=="Chapter01" call "%src_scene_chapter01_dir%\01_Part01\Chapter01_Part01.bat"
    if "%~1"=="Chapter01_Part01" call "%src_scene_chapter01_dir%\01_Part01\Chapter01_Part01.bat"
    exit /b %errorlevel%


:Load_SaveData
    for /f "usebackq tokens=1,2 delims==" %%a in ("%saves_active_dir%\SaveData_%1.txt") do (
        set "%%a=%%b"
    )
    call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" INIT_DEFAULTS
    exit /b 0


:Start_NewGameSession
    :: デバッグ情報
    if "%DEBUG_STATE%"=="1" (
        echo [DEBUG-Main] Starting NewGame_%2 in Slot:%1 - waiting for load...
        timeout /t 2 >nul
    )

    cls
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    echo おめでとうございます！ニューゲームを開始します。
    timeout /t 3
    call :Label_IsSelectedSaveData %1
    call :Label_PlayerStatus_Initialize
    call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" INIT_DEFAULTS
    set "current_save_slot=%1"

    :: Reset camp explore variables for new session
    set "camp_explore_viewed_count=0"
    for /l %%I in (1,1,6) do set "camp_seen_%%I=0"

    if "%2"=="CreateNew" (
        call :JumpToEpisode NewGame
    ) else (
        call :Label_OverwriteSaveAndStartNewGame %1
        call :JumpToEpisode NewGame
    )
    exit /b %errorlevel%


:Start_ContinueGameSession
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    call :Label_IsSelectedSaveData %1
    call :Load_SaveData %1
    set "current_save_slot=%1"
    exit /b 0


:Label_PlayerStatus_Initialize
    for /f "usebackq eol=# tokens=1,2 delims==" %%a in (
        "%src_playerdata_dir%\Player_Status_Initialize.txt"
    ) do (
        set "%%a=%%b"
    ) & rem ここではplayer_変数が初期化
    exit /b 0


:Label_OverwriteSaveAndStartNewGame
    :: 既存のセーブデータを上書きしNewGameをスタート
    set "selected_save=%1"
    del "%saves_active_dir%\ESD_%selected_save%.txt" >nul 2>&1
    del "%saves_active_dir%\SaveData_%selected_save%.txt" >nul 2>&1
    exit /b 0


:Label_IsSelectedSaveData
    for /l %%i in (1,1,3) do (
        if %%i==%1 (
            set "selected_savedata_%%i=true"
        ) else (
            set "selected_savedata_%%i=false"
        )
    )
    exit /b 0



:: ==================================================
:: ========== ERROR HANDLING ==========================
:: ==================================================

:UI_ERROR
    echo [FATAL] UI Module returned invalid state.
    pause
    goto :STATE_EXIT


:FATAL_ERROR
    echo [FATAL] System initialization failed.
    pause
    goto :STATE_EXIT


:ENCODING_ERROR
    echo Encoding Error. Please launch via Run.bat
    pause
    exit /b 1
