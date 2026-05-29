@echo off
title %~2

:: Load dynamic console size from user config or default to 90x35
if not defined CONSOLE_COLS set "CONSOLE_COLS=90"
if not defined CONSOLE_ROWS set "CONSOLE_ROWS=35"
mode %CONSOLE_COLS%,%CONSOLE_ROWS%

powershell -NoProfile -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')"
:: ==================================================
:: Astral Divide - Main.bat (v0.1.2 planned)
:: Role: Game Core / State Orchestrator
:: ==================================================

:: --------------------------------------------------
:: [0] Encoding & Launch Guard
:: --------------------------------------------------
if not "%~1"=="65001" goto :ENCODING_ERROR
chcp %~1 >nul

:: DEV MODE (optional)
if "%~2"=="DEV" (
    set DEBUG_STATE=1
) else (
    if not defined DEBUG_STATE set DEBUG_STATE=0
)

:: --------------------------------------------------
:: [1] Environment Initialization
:: --------------------------------------------------
call "%src_systems_dir%\InitializeModule.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FATAL_ERROR

call "%src_savesys_dir%\SaveDataDetectSystem.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FATAL_ERROR

call "%src_display_dir%\BootCompleteDisplay.bat"

call "%src_audio_dir%\Play_BGM.bat" "%assets_sounds_starfall_dir%\StarFallHill.wav" repeat 30

call "%tools_dir%\cmdbkg.exe" "%assets_images_dir%\AD_Title_Image.png" /b

chcp 65001

:: Apply user-configured font automatically
if defined CONSOLE_FONT (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        if exist "%tools_dir%\cmdwiz.exe" (
            call "%tools_dir%\cmdwiz.exe" setfont "%tools_dir%\%CONSOLE_FONT%.fnt" >nul 2>&1
        )
    )
)

:: --------------------------------------------------
:: [2] Main State Loop
:: --------------------------------------------------
:STATE_MAINMENU
    call :Reset_UI_Context

    call "%src_display_dir%\MainMenuModule.bat"
    if not "%errorlevel%"=="%RC_OK%" goto :UI_ERROR

    call :Route_MainMenu_Action
    goto :STATE_MAINMENU



:: ==================================================
:: ========== ROUTERS =================================
:: ==================================================

:Route_MainMenu_Action
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
    call "%src_savesys_dir%\SaveDataSelector.bat" NEWGAME
    if not "%errorlevel%"=="%RC_OK%" goto :STATE_MAINMENU

    if "%UI_ACTION%"=="CANCEL" goto :STATE_MAINMENU
    if "%UI_ACTION%"=="NEWGAME_CREATE" (
        call :Start_NewGameSession %UI_PARAM% CreateNew
        goto :STATE_SCENARIO
    )
    if "%UI_ACTION%"=="NEWGAME_OVERWRITE" (
        call :Start_NewGameSession %UI_PARAM% Overwrite
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_CONTINUE
    call :Reset_UI_Context
    call "%src_savesys_dir%\SaveDataSelector.bat" CONTINUE
    if not "%errorlevel%"=="%RC_OK%" goto :STATE_MAINMENU

    if "%UI_ACTION%"=="CANCEL" goto :STATE_MAINMENU
    if "%UI_ACTION%"=="CONTINUE" (
        call :Start_ContinueGameSession %UI_PARAM%
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_SETTINGS
    call "%src_display_dir%\SettingsMenu.bat"
    goto :STATE_MAINMENU


:STATE_SCENARIO
    call :JumpToEpisode %player_storyroute%
    if "%errorlevel%"=="602" (
        echo セーブ完了、ゲームを終了します。
        goto :STATE_EXIT
    )
    if "%errorlevel%"=="603" (
        echo セーブ失敗。緊急停止します。
        pause
        goto :STATE_EXIT
    )
    if "%errorlevel%"=="604" (
        echo プレイヤーによって中断されました。
        goto :STATE_MAINMENU
    )
    goto :STATE_SCENARIO


:STATE_EXIT
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    echo %esc%[6m%esc%[92mThank you for playing.%esc%[0m
    exit /b 0



:: ==================================================
:: ========== UTILITIES ===============================
:: ==================================================

:Reset_UI_Context
    set UI_ACTION=
    set UI_PARAM=
    exit /b 0


:JumpToEpisode
    if "%~1"=="NewGame"  call "%src_scene_newgame_dir%\NewGame.bat"
    if "%~1"=="Prologue" call "%src_scene_prologue_dir%\Prologue_ver.0.bat"
    if "%~1"=="Episode_1" call "%src_stories_dir%\Episode_01\EntryPoint.bat"
    exit /b %errorlevel%


:Load_SaveData
    for /f "usebackq tokens=1,2 delims==" %%a in ("%saves_active_dir%\SaveData_%1.txt") do (
        set "%%a=%%b"
    )
    exit /b 0


:Start_NewGameSession
    :: デバッグ情報
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Starting NewGame_%2 in Slot:%1 - waiting for load...
        timeout /t 2 >nul
    )

    cls
    call "%src_audio_dir%\Play_BGM.bat" "" stop
    echo おめでとうございます！ニューゲームを開始します。
    timeout /t 3
    call :Label_IsSelectedSaveData %1
    call :Label_PlayerStatus_Initialize

    if "%2"=="CreateNew" (
        call :JumpToEpisode NewGame
    ) else (
        call :Label_OverwriteSaveAndStartNewGame %1
        call :JumpToEpisode NewGame
    )
    exit /b 0


:Start_ContinueGameSession
    call :Label_IsSelectedSaveData %1
    call :Load_SaveData %1
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
