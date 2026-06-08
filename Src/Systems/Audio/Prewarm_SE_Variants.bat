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
set "SE_CACHE_ROOT=%PROJECT_ROOT%\Config\Cache\SEVariants\v4"
set "SE_BUILDER=%~dp0Build_SE_Variant.ps1"
set "SE_CACHE_FORMAT=v4"
if not defined RCSU set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

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
for /f "delims=" %%F in ('dir /b /a-d "%SE_SOURCE_DIR%\*.wav" 2^>nul') do set /a "file_count+=1"

set /a "total_items=file_count*bucket_count"
if %total_items% LEQ 0 exit /b 0

set /a "done_items=0"
set /a "generated_count=0"
set /a "cache_hit_count=0"
set /a "failed_count=0"
set /a "stale_rebuild_count=0"
if defined PROGRESS_FILE if not defined PROGRESS_START set "PROGRESS_START=0"
if defined PROGRESS_FILE if not defined PROGRESS_END set "PROGRESS_END=100"
if defined PROGRESS_FILE echo %PROGRESS_START% > "%PROGRESS_FILE%"
if exist "%RCSU%" call "%RCSU%" -trace INFO PrewarmSE "start mode=%PREWARM_MODE% buckets=%SE_BUCKET_LIST% files=%file_count% total=%total_items% cache=%SE_CACHE_ROOT%"

for %%V in (%SE_BUCKET_LIST%) do (
    if not "%%V"=="" (
        for /f "delims=" %%F in ('dir /b /a-d "%SE_SOURCE_DIR%\*.wav" 2^>nul') do (
            set "SOURCE_FILE=%SE_SOURCE_DIR%\%%F"
            for %%I in ("!SOURCE_FILE!") do (
            set "TARGET_FILE=%SE_CACHE_ROOT%\%%~nI_v%%V%%~xI"
            set "META_FILE=!TARGET_FILE!.meta"
            set "SOURCE_STAMP=%%~zI|%%~tI|%%V|%SE_CACHE_FORMAT%"
            set "PREWARM_STATUS=cache-hit"
            set "PREWARM_REASON=cache-hit"
            if not exist "!TARGET_FILE!" (
                set "PREWARM_STATUS=missing"
                set "PREWARM_REASON=missing"
            ) else if not exist "!META_FILE!" (
                set "PREWARM_STATUS=stale"
                set "PREWARM_REASON=stale"
            ) else (
                set "CACHED_STAMP="
                set /p "CACHED_STAMP=" < "!META_FILE!"
                if /i not "!CACHED_STAMP!"=="!SOURCE_STAMP!" (
                    set "PREWARM_STATUS=stale"
                    set "PREWARM_REASON=stale"
                )
            )
            if /i not "!PREWARM_STATUS!"=="cache-hit" (
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SE_BUILDER%" -SourcePath "%%~fI" -OutputPath "!TARGET_FILE!" -Volume %%V >nul 2>&1
                if exist "!TARGET_FILE!" (
                    > "!META_FILE!" <nul set /p "=!SOURCE_STAMP!"
                    set "PREWARM_STATUS=generated"
                ) else (
                    set "PREWARM_STATUS=generate-failed"
                )
            )
            set /a "done_items+=1"
            if defined PROGRESS_FILE (
                set /a "progress_span=PROGRESS_END-PROGRESS_START"
                set /a "progress_value=PROGRESS_START + ((done_items * progress_span) / total_items)"
                echo !progress_value! > "%PROGRESS_FILE%"
            )
            if /i "!PREWARM_STATUS!"=="generated" set /a "generated_count+=1"
            if /i "!PREWARM_STATUS!"=="cache-hit" set /a "cache_hit_count+=1"
            if /i "!PREWARM_REASON!"=="stale" set /a "stale_rebuild_count+=1"
            if /i "!PREWARM_STATUS!"=="generate-failed" (
                set /a "failed_count+=1"
                if exist "%RCSU%" call "%RCSU%" -trace WARN PrewarmSE "volume=%%V file=%%~nxI status=!PREWARM_STATUS! reason=!PREWARM_REASON! item=!done_items!/!total_items!"
            )
            )
        )
    )
)

if defined PROGRESS_FILE echo %PROGRESS_END% > "%PROGRESS_FILE%"
if exist "%RCSU%" call "%RCSU%" -trace INFO PrewarmSE "complete total=%done_items% generated=%generated_count% stale_rebuild=%stale_rebuild_count% cache_hit=%cache_hit_count% failed=%failed_count% cache=%SE_CACHE_ROOT%"
exit /b 0
