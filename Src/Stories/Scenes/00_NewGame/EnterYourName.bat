@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

:loop
set "current_location=疎開キャンプ"
call :Display
call :Scene "Scene00_CampIntro.txt"
call "%~dp0CampExplore.bat"
call :PlayCampToHillTransition
set "current_location=星が降る丘"
call :Display
call :Scene "Scene01_PrologueIntro.txt"

:input_name
set "player_name="
call :DrawInputBox
<nul set /p="%ESC%[40;100H%ESC%[96m名前を入力%ESC%[0m"
<nul set /p="%ESC%[42;97H"
set /p player_name="%ESC%[93m> %ESC%[0m"

if not defined player_name (
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    <nul set /p="%ESC%[45;93H%ESC%[90m名を告げないままなら、この夜は%ESC%[0m"
    <nul set /p="%ESC%[46;101H%ESC%[90m「シオン」と呼ばれる。 [Y/N]%ESC%[0m"
    <nul set /p="%ESC%[42;99H%ESC%[90mシオン%ESC%[0m"
    choice /c YN /n >nul
    if errorlevel 2 (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
        <nul set /p="%ESC%[45;87H%ESC%[0K"
        <nul set /p="%ESC%[46;87H%ESC%[0K"
        <nul set /p="%ESC%[48;87H%ESC%[0K"
        goto :input_name
    )
    set "player_name=シオン"
)

call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
set "current_location=星が降る丘"
call :Display
call :Scene "Scene02_NameConfirmed.txt"
call :Scene "Scene03_PrologueOutro.txt"

endlocal & (
    set "player_name=%player_name%"
)
exit /b 604

:Display
cls
call :DrawDialogueGuide
exit /b 0

:PlayCampToHillTransition
set "current_location=丘への道"
call :Display
set "camp_transition_scene=Scene00_CampToHill_SeenNone.txt"
if defined camp_explore_viewed_count if !camp_explore_viewed_count! GEQ 2 set "camp_transition_scene=Scene00_CampToHill_SeenSome.txt"
if defined camp_explore_viewed_count if !camp_explore_viewed_count! GEQ 5 set "camp_transition_scene=Scene00_CampToHill_SeenMany.txt"
call :Scene "%camp_transition_scene%"
exit /b 0

:Scene
for /f "eol=# usebackq delims=" %%L in ("%src_text_newgame_dir%\%~1") do (
    set "line=%%L"
    call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!line!"
    echo !line! | findstr /c:"{clear}" /c:"{bg:" >nul
    if !errorlevel! == 0 call :DrawDialogueGuide
)
exit /b 0

:DrawDialogueGuide
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: %current_location%%ESC%[0m"
<nul set /p="%ESC%[65;186H%ESC%[90mprologue%ESC%[0m"
exit /b 0

:DrawInputBox
<nul set /p="%ESC%[38;87H%ESC%[90m┌────────────────────────────────────────────────────────────┐%ESC%[0m"
<nul set /p="%ESC%[39;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[40;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[41;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[42;87H%ESC%[90m│                                                            │%ESC%[0m"
<nul set /p="%ESC%[43;87H%ESC%[90m└────────────────────────────────────────────────────────────┘%ESC%[0m"
exit /b 0
