@echo off
::------------------------------------------------------------------------------
:: Play_SE.bat
:: Plays a sound effect asynchronously with SE_VOLUME support.
::
:: Arguments:
::   %1 - Path to the sound effect file.
::------------------------------------------------------------------------------
setlocal EnableDelayedExpansion
if /i "%SOUND_FX_ENABLED%"=="OFF" exit /b 0
if "%SOUND_FX_ENABLED%"=="0" exit /b 0

set "SE_FILE=%~1"
if "%SE_FILE%"=="" exit /b 1
if not exist "%SE_FILE%" exit /b 2
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

set "TARGET_VOLUME=%SE_VOLUME%"
if "%TARGET_VOLUME%"=="" set "TARGET_VOLUME=100"
if "%TARGET_VOLUME%"=="0" exit /b 0

set /a "TARGET_BUCKET=((TARGET_VOLUME + 5) / 10) * 10"
if %TARGET_BUCKET% GTR 100 set "TARGET_BUCKET=100"
if %TARGET_BUCKET% LSS 0 set "TARGET_BUCKET=0"

if "%TARGET_BUCKET%"=="100" (
    set "PLAY_FILE=%SE_FILE%"
) else (
    set "SE_CACHE_ROOT=%PROJECT_ROOT%\Config\Cache\SEVariants\v4"
    if not defined PROJECT_ROOT set "SE_CACHE_ROOT=%TEMP%\AstralDivide_SEVariants\v4"
    set "PLAY_FILE=!SE_CACHE_ROOT!\%~n1_v%TARGET_BUCKET%%~x1"
    set "SE_FALLBACK_REASON="
    if not exist "!PLAY_FILE!" (
        set "SE_BUILDER=%~dp0Build_SE_Variant.ps1"
        if exist "!SE_BUILDER!" (
            powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SE_BUILDER!" -SourcePath "%SE_FILE%" -OutputPath "!PLAY_FILE!" -Volume %TARGET_BUCKET% >nul 2>&1
        )
    )
    if not exist "!PLAY_FILE!" (
        set "SE_FALLBACK_REASON=variant-missing"
        set "PLAY_FILE=%SE_FILE%"
    )
)
if defined SE_FALLBACK_REASON if exist "%RCSU%" call "%RCSU%" -trace WARN Play_SE "src=%~nx1 vol=%TARGET_VOLUME% bucket=%TARGET_BUCKET% fallback=!SE_FALLBACK_REASON! play=!PLAY_FILE!"
if /i "%AUDIO_TRACE_SE%"=="1" if exist "%RCSU%" call "%RCSU%" -trace INFO Play_SE "src=%~nx1 vol=%TARGET_VOLUME% bucket=%TARGET_BUCKET% play=!PLAY_FILE!"

if defined PROJECT_ROOT (
    set "CMDWIZ_PATH=%PROJECT_ROOT%\Tools\cmdwiz.exe"
) else (
    set "CMDWIZ_PATH=%~dp0..\..\..\Tools\cmdwiz.exe"
)
if not exist "%CMDWIZ_PATH%" if exist "%~dp0cmdwiz.exe" set "CMDWIZ_PATH=%~dp0cmdwiz.exe"
if exist "%CMDWIZ_PATH%" start "" /b "%CMDWIZ_PATH%" playsound "!PLAY_FILE!"

endlocal
exit /b 0
