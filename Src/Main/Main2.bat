@echo off
title %~2
mode 80,25
%tools_dir%\cmdwiz.exe fullscreen 1
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
        call :Start_NewGameSession %UI_PARAM%
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_CONTINUE
    call :Reset_UI_Context
    call "%src_savesys_dir%\SaveDataSelector.bat" CONTINUE
    if not "%errorlevel%"=="%RC_OK%" goto :STATE_MAINMENU

    if "%UI_ACTION%"=="CANCEL" goto :STATE_MAINMENU
    if "%UI_ACTION%"=="CONTINUE" (
        call :Load_SaveData %UI_PARAM%
        goto :STATE_SCENARIO
    )
    goto :STATE_MAINMENU


:STATE_SETTINGS
    call "%src_display_dir%\SettingsMenu.bat"
    goto :STATE_MAINMENU


:STATE_SCENARIO
    call :JumpToEpisode %player_storyroute%
    goto :STATE_MAINMENU


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
    if "%~1"=="Episode_1" call "%cd_stories%\Episode_01\EntryPoint.bat"
    exit /b %errorlevel%


:Load_SaveData
    for /f "tokens=1,2 delims==" %%a in ("%cd_savedata%\SaveData_%1.txt") do (
        set "%%a=%%b"
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
