@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "CURRENT_SKIP_POLICY=1"
set "current_location=---"
call :Display
call :Scene "Scene01_ToChapter1.txt"
set "current_location=王都エリュシオン - 自室"
call :Scene "Scene02_Chapter1Opening.txt"

endlocal
exit /b 604

:Scene
    set "current_scene=%~1"
    set "current_save_supported=0"
    set "scene_skipped=0"
    set "RENDER_BG_T=33"
    set "RENDER_BG_PATH="
    call :DrawTextInputGuide
    for /f "eol=# usebackq delims=" %%L in ("%src_text_chapter01_dir%\01_Part01\%~1") do (
        if "!SCENARIO_SKIP_ACTIVE!"=="1" (
            set "scene_skipped=1"
            goto :scene_skip_break
        )
        set "line=%%L"
        call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!line!"
        echo !line! | findstr /c:"{clear}" /c:"{bg:" /c:"{bg_t:" >nul
        if !errorlevel! == 0 (
            call :DrawDialogueGuide
            call :DrawTextInputGuide
        )
    )
:scene_skip_break
    set "SCENARIO_SKIP_ACTIVE="
    if "%scene_skipped%"=="1" exit /b 8
    exit /b 0

:Display
cls
call :DrawDialogueGuide
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
<nul set /p="%ESC%[65;174H%ESC%[90mChapter1: 王都に生きる者%ESC%[0m"
exit /b 0