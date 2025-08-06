@echo on
cmdwiz fullscreen 1

:: Main.bat
:: This is the main entry point for the RPG game.
:: aka : "HUB Terminal"
:: All system modules are called from here,
:: and error code (return value) handling controls the system flow.
:: error code material is in the bottom of this file.
:: For complete guides, see the ErrorCodeReference.md file


:: Detect Arguments
if "%1"=="777" (
    echo This is a development mode. Please use the normal Run.bat to start the game.
    chcp 65001 >nul
    set DEV_STATE=1
    title RPG Game - Development Mode
    goto :DEV_MODE
)
if not "%1"=="65001" (goto :ENCODING_ERROR)
chcp %1 >nul



:: Setting Environment

:: System Initialization
call "%src_systems_dir%\InitializeModule.bat"


:: Detect Save Data
call "%src_savesys_dir%\SaveDataDetectSystem.bat"


:: カラーシステム
:: ここに将来的にMarkup言語のようなカラーコードを実装する予定

call "%src_debug_dir%\Show_ANSI_Colors.bat"


:: Display Boot Complete
call "%src_display_dir%\BootCompleteDisplay.bat"


:: Launch Music System
rem start "LaunchMusic" /b cmdwiz playsound %cd_sounds%\starfallhill20min.wav

start "TitleMusic" /b "%assets_sounds_starfall_dir%\StarFallHill.wav" repeat 50


:: Debug Mode Check
if not defined DEBUG_STATE set DEBUG_STATE=0

::setlocal enabledelayedexpansion

:: Main Menu Loop
:Start_MainMenu
    :: Debug Info
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Starting MainMenu call...
        timeout /t 1 >nul
    )

    :: Call Main Menu Module (MMM)
    call "%cd_systems%\MainMenuModule.bat" MainMenu
    
    :: Check return code from MMM
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] MMM returned errorlevel: %errorlevel%
        echo [DEBUG-Main] DEBUG_STATE is now: %DEBUG_STATE%
        echo [DEBUG-Main] Checking conditions...
        timeout /t 3 >nul
    )
    
    if %retcode%==1001 goto :Start_NewGame
    if %retcode%==1002 goto :Start_Continue
    if %retcode%==1003 goto :Start_Settings
    if %retcode%==1099 goto :Exit
    
    :: デバッグ情報：予期しない返り値
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Unexpected errorlevel: %errorlevel% - returning to MainMenu
        timeout /t 3 >nul
    )
    goto :Start_MainMenu
::


:: セーブデータ選択画面に遷移
:: コンティニュー処理

:Start_Continue
    call "%cd_systems_savesys%\SaveDataSelector.bat" CONTINUE
    if %errorlevel%==2000 (goto :Start_MainMenu)& rem セーブデータが見つからない場合はメインメニューに戻る
    if %errorlevel%==2031 (call :Start_ContinueGame 1)
    if %errorlevel%==2032 (call :Start_ContinueGame 2)
    if %errorlevel%==2033 (call :Start_ContinueGame 3)
    if %errorlevel%==2099 (goto :Start_MainMenu)
:: 拡張予定
::  if %errorlevel%==2034 (call :Start_ContinueGame 4)
::  if %errorlevel%==2035 (call :Start_ContinueGame 5)
::  ...


:: ニューゲーム処理
:Start_NewGame
    :: デバッグ情報
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Starting NewGame process - calling SaveDataSelector...
        timeout /t 2 >nul
    )
    
    call "%cd_systems_savesys%\SaveDataSelector.bat" NEWGAME
    
    :: デバッグ情報：SDS返り値確認
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo %esc%[8;1H[DEBUG-Main] SDS returned errorlevel: %errorlevel%%esc%[0m
        timeout /t 2 >nul
    )
    
    if %retcode%==2051 (call :Start_NewGameSession 1 CreateNew)
    if %retcode%==2052 (call :Start_NewGameSession 2 CreateNew)
    if %retcode%==2053 (call :Start_NewGameSession 3 CreateNew)
    if %retcode%==2071 (call :Start_NewGameSession 1 Overwrite)
    if %retcode%==2072 (call :Start_NewGameSession 2 Overwrite)
    if %retcode%==2073 (call :Start_NewGameSession 3 Overwrite)
    if %retcode%==2099 (goto :Start_MainMenu)
    
    :: デバッグ情報：予期しない返り値
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Unexpected SDS errorlevel: %errorlevel% - returning to MainMenu...
        timeout /t 3 >nul
    )
    goto :Start_MainMenu
::


:: オプション処理

:Start_Settings
echo オプションメニューを開きます。
pause
goto :Label_Settings
::


:: ゲームセッション開始処理
:Start_ContinueGameSession
    call :Label_IsSelectedSaveData %1
    call :Label_LoadSaveData %1
    call :JumpToEpisode %player_storyroute%
::

:Start_NewGameSession
    :: デバッグ情報
    if defined DEBUG_STATE if %DEBUG_STATE%==1 (
        echo [DEBUG-Main] Starting NewGame_%2 in Slot:%1 - waiting for load...
        timeout /t 2 >nul
    )


    cls
    taskkill /f /im cmdwiz.exe >nul 2>&1
    echo おめでとうございます！ニューゲームを開始します。
    timeout /t 3
    call :Label_IsSelectedSaveData %1
    call :Label_PlayerStatus_Initialize


    if "%2"=="CreateNew" (
        call :JumpToEpisode Prologue
    ) else (
        call :Label_OverwriteSaveAndStartNewGame %1
        call :JumpToEpisode Prologue
    )


::
:Start_Scenario
call :JumpToEpisode %player_storyroute%
goto :Scenario_Return
::



:: ストーリー進行処理
:JumpToEpisode
    if "%~1"=="Prologue"       call "%cd_stories%\Prologue_ver.0.bat"
    if "%~1"=="Episode_1"      call "%cd_stories%\Episode_01\EntryPoint.bat"
    if "%~1"=="Episode_2"      call "%cd_stories%\Episode_02\EntryPoint.bat"

    if %retcode%==55 goto :JumpToEpisode


    :: ...今後も増やせる


    exit /b
::


:Scenario_Return
if %errorlevel%==602 (
    echo セーブ完了、ゲームを終了します。
    exit /b 0
)
if %errorlevel%==603 (
    echo セーブ失敗。緊急停止します。
    exit /b 1
)
if %errorlevel%==604 (
    echo プレイヤーによって中断されました。
    exit /b 2
)
goto :Start_Scenario


:Label_PlayerStatus_Initialize
    for /f "tokens=1,2 delims='='" %%a in (
        %cd_playerdata%\Player_Status_Initialize.txt
    ) do (
        set "%%a=%%b"
    ) & rem ここではplayer_変数が初期化
    exit /b 0

:Label_OverwriteSaveAndStartNewGame
    rem 既存のセーブデータを上書きしNewGameをスタート
    set "selected_save=%1"
    del "%cd_savedata%\ESD_%selected_save%.txt" >nul
    del "%cd_savedata%\SaveData_%selected_save%.txt" >nul
    exit /b 0


::Utility
:Label_IsSelectedSaveData
    rem 今後セーブデータ容量を増やす場合forループ範囲の変更をする 現在:3
    for /l %%i in (1,1,3) do (
        rem selected_savedata_: どのセーブデータを選択しているかを示すフラグ (true/false)
        if %%i==%1 (
            set "selected_savedata_%%i=true"
        ) else (
            set "selected_savedata_%%i=false"
        )
    )
    exit /b 0


::Continue
:Label_LoadSaveData
    rem セーブデータのロード
    for /f "tokens=1,2 delims='='" %%a in (
        %cd_savedata%\SaveData_%1.txt
    ) do (
        set "%%a=%%b"
    )
    exit /b 0


::
:Label_Continue
    set continue=true
    call "%cd_systems%\Display\SelectSaveData.bat"
    if %errorlevel%==31 (goto :Label_MainMenu)
    if %errorlevel%==32 (call :Label_ContinueGame 1)
    if %errorlevel%==33 (call :Label_ContinueGame 2)
    if %errorlevel%==34 (call :Label_ContinueGame 3)
    if %errorlevel%==35 (exit /b 35)



:Label_ContinueGame
    call :Label_IsSelectedSaveData %1
    call :Label_LoadSaveData %1
    exit /b 35

:Label_NewGame
    set newgame=true
    call "%cd_systems%\Display\SelectSaveData.bat"
    if %errorlevel%==31 (goto :Label_MainMenu)
    if %errorlevel%==42 (call :Label_StartNewGame 1 CreateNew)
    if %errorlevel%==43 (call :Label_StartNewGame 2 CreateNew)
    if %errorlevel%==44 (call :Label_StartNewGame 3 CreateNew)
    if %errorlevel%==45 (exit /b 45)
    if %errorlevel%==52 (call :Label_StartNewGame 1 Overwrite)
    if %errorlevel%==53 (call :Label_StartNewGame 2 Overwrite)
    if %errorlevel%==54 (call :Label_StartNewGame 3 Overwrite)
    if %errorlevel%==55 (exit /b 55)



:Label_StartNewGame
    call :Label_IsSelectedSaveData %1
    call :Label_PlayerStatus_Initialize
    if "%2"=="CreateNew" (
        exit /b 45
    ) else if "%2"=="Overwrite" (
        call :Label_OverwriteSaveAndStartNewGame %1
        exit /b 55
    )

::
:Label_Settings
goto :OPTION




::
::
::****************************************************************************************************************
:Main1
rem Continue
goto %player_lastplace%
:Main2



:EnterPlayerName
call "%cd_newgame%\EntreYourName.bat"
:ReadyForPrologue
call "%cd_newgame%\ReadyForPrologue.bat"
if %errorlevel%==18 (goto :Prologue)
IF %ERRORLEVEL%==666 (GOTO :CRITICAL_ERROR)


:Prologue
call "%cd_stories%\Prologue.bat"
if %errorlevel%==100 (cls& goto :Prologue)& rem エラーコード100予期せぬエラー
if %errorlevel%==602 (exit)& rem 602はセーブして終了のコード



:UnexpectedError
rem 予期しないエラーが発生しました
cls
echo. %ESC%[91mAn unexpected error occurred. [E-100:EOF]
echo. Terminate Systems.%ESC%[0m
call "%cd_sounds%\ErrorBeepSounds.bat"
pause >nul
exit 9009
::****************************************************************************************************************
::
::
::








:OPTION
cls
echo.+-------------------------------------------------++-------------------------------------------------+
echo.%P%                                                 %P%%P%                                                 %P%
echo.%P%      (A)        DELETE SAVE DATA                %P%%P%      (C)          ECHO ON                       %P%
echo.%P%                                                 %P%%P%                                                 %P%
echo.+-------------------------------------------------++-------------------------------------------------+
echo.+-------------------------------------------------++-------------------------------------------------+
echo.%P%                                                 %P%%P%                                                 %P%
echo.%P%      (B)           EXIT GAME                    %P%%P%      (D)           SET /P                       %P%
echo.%P%                                                 %P%%P%                                                 %P%
echo.+-------------------------------------------------++-------------------------------------------------+
choice /c ABCDQ
if %errorlevel%==1 (goto :Label_DeleteAllSaveData)
if %errorlevel%==2 (exit /b 9000)
if %errorlevel%==3 (@echo on & goto Label_Main)
if %errorlevel%==4 (goto :Label_DevCommand)
if %errorlevel%==5 (goto :Label_MainMenu)


:Label_DeleteAllSaveData
    echo. 開発段階用緊急停止pause
    echo. 続行しますか？
    pause > nul
    rem これセーブデータ初期化バッチにつき注意（キャンセルできるようにしてます）
    call "%cd_systems%\SaveDataDeleteSystem.bat"
    if %errorlevel%==606 (exit /b 606)
    if %errorlevel%==660 (goto Label_Main)

:Label_DevCommand
    set /p command="command=>"
    %command%
    call :DevCommand










:Exit
    taskkill /f /im cmdwiz.exe >nul 2>&1
    echo. %ESC%[92mGame has exited successfully. [E-0:EXIT]%ESC%[0m
    echo. %ESC%[92mThank you for playing!%ESC%[0m
    timeout /t 2 >nul
    exit /b 39

::
::
::*******************************************************************************************************
:ENCODING_ERROR
    @ECHO OFF
    CHCP 65001
    COLOR 1F
    CLS
    ECHO.
    ECHO.
    ECHO. Error code: 65001 - A serious encoding error has been detected in the boot sector.
    ECHO.
    ECHO. The system source that is the core of this project is a batch file,
    ECHO.  so if an encoding error occurs, it will cause irreparable problems in the code.
    ECHO.
    ECHO. If this error message appears, the following may be the cause:
    ECHO.
    ECHO. - The game was started by an illegal means other than "Run.bat"
    ECHO. - The source code was rewritten and did not run using the normal startup procedure
    ECHO. - There is a problem with the Windows encoding settings
    ECHO.
    TIMEOUT /T 600
    ECHO.
    ECHO. PRESS ANY KEY TO EXIT.
    PAUSE > NUL

EXIT
::*******************************************************************************************************
::

