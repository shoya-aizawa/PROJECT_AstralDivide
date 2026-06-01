@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "PREWARM_MODE=%~1"
if "%PREWARM_MODE%"=="" set "PREWARM_MODE=FULL"
set "PROGRESS_FILE=%~2"
set "PROGRESS_START=%~3"
set "PROGRESS_END=%~4"

set "SE_SOURCE_DIR=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect"
set "SE_CACHE_ROOT=%PROJECT_ROOT%\Config\Cache\SEVariants\v2"
set "SE_BUILDER=%~dp0Build_SE_Variant.ps1"

if not exist "%SE_SOURCE_DIR%" exit /b 0
if not exist "%SE_BUILDER%" exit /b 0
if not exist "%SE_CACHE_ROOT%" md "%SE_CACHE_ROOT%" >nul 2>&1

if /i "%PREWARM_MODE%"=="FULL" (
    set "SE_BUCKET_LIST=10 20 30 40 50 60 70 80 90"
) else (
    set "SE_PREWARM_VOLUME=%SE_VOLUME%"
    if "!SE_PREWARM_VOLUME!"=="" set "SE_PREWARM_VOLUME=80"
    set /a "SE_PREWARM_BUCKET=((SE_PREWARM_VOLUME + 5) / 10) * 10"
    if !SE_PREWARM_BUCKET! GTR 90 set "SE_PREWARM_BUCKET=90"
    if !SE_PREWARM_BUCKET! LSS 10 set "SE_PREWARM_BUCKET=10"
    set /a "SE_PREWARM_BUCKET_PREV=SE_PREWARM_BUCKET-10"
    set /a "SE_PREWARM_BUCKET_NEXT=SE_PREWARM_BUCKET+10"
    if !SE_PREWARM_BUCKET_PREV! LSS 10 set "SE_PREWARM_BUCKET_PREV="
    if !SE_PREWARM_BUCKET_NEXT! GTR 90 set "SE_PREWARM_BUCKET_NEXT="
    set "SE_BUCKET_LIST=!SE_PREWARM_BUCKET_PREV! !SE_PREWARM_BUCKET! !SE_PREWARM_BUCKET_NEXT!"
)

set /a "bucket_count=0"
for %%V in (%SE_BUCKET_LIST%) do (
    if not "%%V"=="" set /a "bucket_count+=1"
)

set /a "file_count=0"
for %%F in ("%SE_SOURCE_DIR%\*.wav") do set /a "file_count+=1"

set /a "total_items=file_count*bucket_count"
if %total_items% LEQ 0 exit /b 0

set /a "done_items=0"
if defined PROGRESS_FILE if not defined PROGRESS_START set "PROGRESS_START=0"
if defined PROGRESS_FILE if not defined PROGRESS_END set "PROGRESS_END=100"
if defined PROGRESS_FILE echo %PROGRESS_START% > "%PROGRESS_FILE%"

for %%V in (%SE_BUCKET_LIST%) do (
    if not "%%V"=="" (
        for %%F in ("%SE_SOURCE_DIR%\*.wav") do (
            set "TARGET_FILE=%SE_CACHE_ROOT%\%%~nF_v%%V%%~xF"
            if not exist "!TARGET_FILE!" (
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SE_BUILDER%" -SourcePath "%%~fF" -OutputPath "!TARGET_FILE!" -Volume %%V >nul 2>&1
            )
            set /a "done_items+=1"
            if defined PROGRESS_FILE (
                set /a "progress_span=PROGRESS_END-PROGRESS_START"
                set /a "progress_value=PROGRESS_START + ((done_items * progress_span) / total_items)"
                echo !progress_value! > "%PROGRESS_FILE%"
            )
        )
    )
)

if defined PROGRESS_FILE echo %PROGRESS_END% > "%PROGRESS_FILE%"
exit /b 0
