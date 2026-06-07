@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

:loop
set "CURRENT_SKIP_POLICY=1"
set "current_location=疎開キャンプ"
call :Display
call :Scene "Scene00_CampIntro.txt"
call "%~dp0CampExplore.bat"
set "camp_rc=%errorlevel%"
if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO EnterYourName "CampExplore returned rc=%camp_rc%"
if "%camp_rc%"=="641" exit /b 641
if "%camp_rc%"=="642" exit /b 642
set "CURRENT_SKIP_POLICY=1"
call :PlayCampToHillTransition
set "CURRENT_SKIP_POLICY=0"
set "current_location=星が降る丘"
call :Display
call "%src_audio_dir%\Play_BGM.bat" "%assets_sounds_dir%\静かな夜に.mp3" repeat %BGM_VOLUME%
call :Scene "Scene01_PrologueIntro.txt"
if "%errorlevel%"=="8" set "SCENARIO_SKIP_ACTIVE=1"

:input_name
set "CURRENT_SKIP_POLICY=0"
set "SCENARIO_SKIP_ACTIVE="

:input_name_start
set "player_name="
call :DrawInputBox
<nul set /p="%ESC%[40;100H%ESC%[96m名前を入力%ESC%[0m"
<nul set /p="%ESC%[42;97H"
set /p player_name="%ESC%[93m> %ESC%[0m"

if not defined player_name (
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    <nul set /p="%ESC%[45;93H%ESC%[90m名を告げないままなら、これから君は%ESC%[0m"
    <nul set /p="%ESC%[46;101H%ESC%[90m「シオン」と呼ばれる。 [Y/N]%ESC%[0m"
    <nul set /p="%ESC%[42;99H%ESC%[90mシオン%ESC%[0m"
    choice /c YN /n >nul
    if errorlevel 2 (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
        <nul set /p="%ESC%[45;87H%ESC%[0K"
        <nul set /p="%ESC%[46;87H%ESC%[0K"
        <nul set /p="%ESC%[48;87H%ESC%[0K"
        goto :input_name_start
    )
    set "player_name=シオン"
)

:after_name_input
set "CURRENT_SKIP_POLICY=1"
call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
set "current_location=星が降る丘"
call :Display
call :Scene "Scene02_NameConfirmed.txt"
call :Scene "Scene03_PrologueOutro.txt"
call :ResolvePrologueResult
call "%src_display_dir%\ChapterResult.bat" "Prologue" "星の夢" "%prologue_result_bg%" "Chapter01_Part01" "1" "%prologue_result_rank%"
set "result_rc=%errorlevel%"
if not "%result_rc%"=="603" (
    call "%src_scene_chapter01_dir%\01_Part01\Chapter01_Part01.bat"
    set "result_rc=%errorlevel%"
)

endlocal & (
    set "player_name=%player_name%"
    set "player_level=%player_level%"
    set "prologue_completed=%prologue_completed%"
    set "player_storyroute=%player_storyroute%"
)
exit /b %result_rc%

:Display
cls
call :DrawDialogueGuide
exit /b 0

:PlayCampToHillTransition
call "%src_audio_dir%\Play_BGM.bat" "" stop
set "current_location=丘への道"
call :Display
set "camp_transition_scene=Scene00_CampToHill_SeenNone.txt"
if defined camp_explore_viewed_count if !camp_explore_viewed_count! GEQ 2 set "camp_transition_scene=Scene00_CampToHill_SeenSome.txt"
if defined camp_explore_viewed_count if !camp_explore_viewed_count! GEQ 5 set "camp_transition_scene=Scene00_CampToHill_SeenMany.txt"
call :Scene "%camp_transition_scene%"
exit /b 0

:ResolvePrologueResult
set "prologue_result_rank=B"
set "prologue_result_bg=A_Nighttime_Settlement_of_War_Refugees.png"
if defined camp_explore_viewed_count (
    if !camp_explore_viewed_count! GEQ 2 (
        set "prologue_result_rank=A"
        set "prologue_result_bg=StarFallHill_01_Alone.png"
    )
    if !camp_explore_viewed_count! GEQ 6 (
        set "prologue_result_rank=S"
        set "prologue_result_bg=StarFallHill_02_HiroineAppears.png"
    )
)
exit /b 0

:Scene
    set "current_scene=%~1"
    set "current_save_supported=0"
    set "scene_skipped=0"
    call :DrawTextInputGuide
    for /f "eol=# usebackq delims=" %%L in ("%src_text_newgame_dir%\%~1") do (
        if "!SCENARIO_SKIP_ACTIVE!"=="1" (
            set "scene_skipped=1"
            goto :scene_skip_break
        )
        set "line=%%L"
        call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!line!"
        echo !line! | findstr /c:"{clear}" /c:"{bg:" >nul
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
<nul set /p="%ESC%[64;108H%ESC%[90mF/Space: 早送り  P/Esc: ポーズ%ESC%[0m"
exit /b 0



:DrawDialogueGuide
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: %current_location%%ESC%[0m"
<nul set /p="%ESC%[65;187H%ESC%[90mPrologue: 星の夢%ESC%[0m"
exit /b 0

:DrawInputBox
<nul set /p="%ESC%[38;87H%ESC%[90m┌────────────────────────────────────────────────────────────┐%ESC%[0m"
<nul set /p="%ESC%[39;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[40;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[41;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[42;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[43;87H%ESC%[90m└────────────────────────────────────────────────────────────┘%ESC%[0m"
exit /b 0

:DrawSavePromptBox
<nul set /p="%ESC%[38;85H%ESC%[90m┌──────────────────────────────────────────────────────────────┐%ESC%[0m"
for /l %%r in (39,1,45) do (
    <nul set /p="%ESC%[%%r;85H%ESC%[90m│                                                              │%ESC%[0m"
)
<nul set /p="%ESC%[46;85H%ESC%[90m└──────────────────────────────────────────────────────────────┘%ESC%[0m"
exit /b 0

:ClearSavePromptBox
for /l %%r in (38,1,46) do (
    <nul set /p="%ESC%[%%r;85H%ESC%[0K"
)
exit /b 0
