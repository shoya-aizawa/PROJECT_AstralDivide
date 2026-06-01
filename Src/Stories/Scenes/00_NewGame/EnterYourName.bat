@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

:loop
call :Display
call :Scene "Scene00_PrologueIntro.txt"

:input_name
set "player_name="
call :DrawInputBox
%tools_dir%\cmdwiz.exe setcursorpos 95 56
<nul set /p="%ESC%[96m名前を入力%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 92 58
set /p player_name="%ESC%[93m> %ESC%[0m"

if not defined player_name (
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav"
    %tools_dir%\cmdwiz.exe setcursorpos 88 61
    <nul set /p="%ESC%[90m名を告げないままなら、この夜は%ESC%[0m"
    %tools_dir%\cmdwiz.exe setcursorpos 96 62
    <nul set /p="%ESC%[90m「シオン」と呼ばれる。 [Y/N]%ESC%[0m"
    %tools_dir%\cmdwiz.exe setcursorpos 106 64
    <nul set /p="%ESC%[90m……シオン%ESC%[0m"
    choice /c YN /n >nul
    if errorlevel 2 (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav"
        %tools_dir%\cmdwiz.exe setcursorpos 82 61
        <nul set /p="%ESC%[0K"
        %tools_dir%\cmdwiz.exe setcursorpos 82 62
        <nul set /p="%ESC%[0K"
        %tools_dir%\cmdwiz.exe setcursorpos 82 64
        <nul set /p="%ESC%[0K"
        goto :input_name
    )
    set "player_name=シオン"
)

call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
call :Display
call :Scene "Scene01_NameConfirmed.txt"
call :Scene "Scene02_PrologueOutro.txt"

endlocal & (
    set "player_name=%player_name%"
)
exit /b 604

:Display
cls
call :DrawDialogueGuide
exit /b 0

:Scene
for /f "eol=# usebackq delims=" %%L in ("%src_text_newgame_dir%\%~1") do (
    set "line=%%L"
    call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!line!"
)
exit /b 0

:DrawDialogueGuide
%tools_dir%\cmdwiz.exe setcursorpos 24 5
<nul set /p="%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 24 63
<nul set /p="%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 28 65
<nul set /p="%ESC%[90m星が降る丘%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 186 65
<nul set /p="%ESC%[90mprologue%ESC%[0m"
exit /b 0

:DrawInputBox
%tools_dir%\cmdwiz.exe setcursorpos 82 54
<nul set /p="%ESC%[90m┌────────────────────────────────────────────────────────────┐%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 82 55
<nul set /p="%ESC%[90m│                                                            │%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 82 56
<nul set /p="%ESC%[90m│                                                            │%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 82 57
<nul set /p="%ESC%[90m│                                                            │%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 82 58
<nul set /p="%ESC%[90m│                                                            │%ESC%[0m"
%tools_dir%\cmdwiz.exe setcursorpos 82 59
<nul set /p="%ESC%[90m└────────────────────────────────────────────────────────────┘%ESC%[0m"
exit /b 0
