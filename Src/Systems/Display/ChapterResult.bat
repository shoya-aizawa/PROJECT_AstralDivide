@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: -----------------------------------------------------------------------------
:: ChapterResult.bat
:: Role: Display chapter results, update player stats, and prompt for saving.
:: Arguments:
::   %1 - Chapter ID (e.g. Prologue)
::   %2 - Chapter Title (e.g. 星の夢)
::   %3 - Fallback Background Image Name (e.g. StarFallHill_06_AloneAgain.png)
::   %4 - Next Route (e.g. PrologueComplete)
::   %5 - Level Up Delta (optional, default 0; Prologue currently passes 1)
::   %6 - Result Rank (optional; selects %chapter_id%_Result_%rank%.png when present)
:: -----------------------------------------------------------------------------

set "chapter_id=%~1"
set "chapter_title=%~2"
set "bg_image=%~3"
set "next_route=%~4"
set "level_up_delta=%~5"
set "result_rank=%~6"

if not defined chapter_id set "chapter_id=Unknown"
if not defined chapter_title set "chapter_title=Unknown"
if not defined next_route set "next_route=NewGame"
if not defined level_up_delta set "level_up_delta=0"
for /f "delims=0123456789" %%A in ("%level_up_delta%") do set "level_up_delta=0"

set "selected_bg_image=%bg_image%"
if defined result_rank (
    set "rank_bg_image=%chapter_id%_Result_%result_rank%.png"
    if defined assets_images_dir if exist "%assets_images_dir%\!rank_bg_image!" set "selected_bg_image=!rank_bg_image!"
)

if not defined ESC (
    for /f "delims=" %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
)

if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO ChapterResult "entered chapter=%chapter_id% title=%chapter_title%"

:: -----------------------------------------------------------------------------
:: [1] Chapter Clear and Reward Section
:: -----------------------------------------------------------------------------
if not defined player_level (
    set "player_level=0"
)
set /a "old_level=player_level"
set /a "player_level+=level_up_delta"
set "completed_var=completed_chapter_%chapter_id%"
set "!completed_var!=1"
set "current_chapter=%chapter_id%"
set "current_scene=%chapter_id%Complete"
if not defined current_location set "current_location=%chapter_title%"
if /i "%chapter_id%"=="Prologue" set "prologue_completed=1"

:: -----------------------------------------------------------------------------
:: [2] Result Screen Presentation
:: -----------------------------------------------------------------------------
cls
if defined assets_images_dir if defined selected_bg_image if exist "%assets_images_dir%\%selected_bg_image%" (
    if defined tools_dir if exist "%tools_dir%\cmdbkg.exe" (
        "%tools_dir%\cmdbkg.exe" "%assets_images_dir%\%selected_bg_image%" /b >nul 2>&1
    )
)

:: Draw borders and titles
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[29;88H%ESC%[96m%chapter_id% COMPLETE%ESC%[0m"
<nul set /p="%ESC%[33;74H%ESC%[93m%chapter_title% をクリアしました。%ESC%[0m"

if defined result_rank (
    <nul set /p="%ESC%[36;88H%ESC%[96mRESULT RANK: %result_rank%%ESC%[0m"
)

if %level_up_delta% GTR 0 (
    <nul set /p="%ESC%[38;84H%ESC%[92m★ LEVEL UP ★%ESC%[0m"
    <nul set /p="%ESC%[40;84H%ESC%[97mLv. %old_level%  ->  Lv. %player_level%%ESC%[0m"
) else (
    <nul set /p="%ESC%[38;79H%ESC%[90m章の清算が完了しました。%ESC%[0m"
)

<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: %current_location%%ESC%[0m"
<nul set /p="%ESC%[65;172H%ESC%[90m%chapter_id%: 完了%ESC%[0m"
<nul set /p="%ESC%[64;100H%ESC%[90mF/Space: 次へ%ESC%[0m"

:: Wait for key input to proceed to save sequence
"%tools_dir%\cmdwiz.exe" getch >nul 2>&1
call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav" >nul 2>&1

:: -----------------------------------------------------------------------------
:: [3] Save Selection Sequence
:: -----------------------------------------------------------------------------
call :DrawSavePromptBox

<nul set /p="%ESC%[39;93H%ESC%[96mチャプタークリアを記録しますか？%ESC%[0m"
<nul set /p="%ESC%[41;91H%ESC%[90m次回はこの区切りから再開できます。%ESC%[0m"
<nul set /p="%ESC%[43;101H%ESC%[93m[F:セーブ / Q:あとで]%ESC%[0m"

:InputLoop
choice /c FQ /n >nul
set "save_choice=%errorlevel%"

if "%save_choice%"=="2" (
    :: Player chose NO
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
    <nul set /p="%ESC%[39;93H%ESC%[90mチャプタークリアを記録しますか？ …あとで%ESC%[0m"
    <nul set /p="%ESC%[43;101H%ESC%[0K"
    set "save_requested=0"
) else (
    :: Player chose YES
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav" >nul 2>&1
    <nul set /p="%ESC%[39;93H%ESC%[92mチャプタークリアを記録しますか？ …セーブ%ESC%[0m"
    <nul set /p="%ESC%[43;101H%ESC%[0K"
    set "save_requested=1"
)

"%tools_dir%\cmdwiz.exe" delay 500 >nul 2>&1

:: If this is the initial chapter completion (level 0 -> 1), ask about auto-save
if %level_up_delta% GTR 0 if "%old_level%"=="0" (
    <nul set /p="%ESC%[42;89H%ESC%[96m今後の冒険のためにオートセーブを有効にしますか？%ESC%[0m"
    <nul set /p="%ESC%[43;101H%ESC%[93m[F:はい / Q:いいえ]%ESC%[0m"
    choice /c FQ /n >nul
    set "autosave_choice=!errorlevel!"
    
    if "!autosave_choice!"=="2" (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
        set "AUTO_SAVE=OFF"
        set "autosave_enabled=0"
        <nul set /p="%ESC%[42;89H%ESC%[90m今後の冒険のためにオートセーブを有効にしますか？ …いいえ%ESC%[0m"
        <nul set /p="%ESC%[43;101H%ESC%[0K"
    ) else (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav" >nul 2>&1
        set "AUTO_SAVE=ON"
        set "autosave_enabled=1"
        <nul set /p="%ESC%[42;89H%ESC%[92m今後の冒険のためにオートセーブを有効にしますか？ …はい  %ESC%[0m"
        <nul set /p="%ESC%[43;101H%ESC%[0K"
    )
    
    call :PersistAutoSavePreference "!AUTO_SAVE!"
    "%tools_dir%\cmdwiz.exe" delay 800 >nul 2>&1
)

if "%save_requested%"=="1" (
    <nul set /p="%ESC%[45;92H%ESC%[96mセーブデータを書き込んでいます...%ESC%[0m"
    
    :: Pre-set the next story route before saving so the file stores the correct progress
    set "player_storyroute=%next_route%"
    
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO ChapterResult "saving slot=%current_save_slot% route=%player_storyroute% autosave=%AUTO_SAVE%"
    call "%src_savesys_dir%\SaveDataWriter.bat" MANUAL "%current_save_slot%" "%next_route%"
    set "save_rc=!errorlevel!"
    
    <nul set /p="%ESC%[45;92H%ESC%[0K"
    if not "!save_rc!"=="0" (
        <nul set /p="%ESC%[45;92H%ESC%[91mセーブに失敗しました。(コード: !save_rc!)%ESC%[0m"
        "%tools_dir%\cmdwiz.exe" delay 1800 >nul 2>&1
        call :ClearSavePromptBox
        endlocal & (
            set "player_level=%player_level%"
            set "%completed_var%=1"
            set "prologue_completed=%prologue_completed%"
            set "current_chapter=%current_chapter%"
            set "current_scene=%current_scene%"
            set "current_location=%current_location%"
            set "player_storyroute=%next_route%"
            set "AUTO_SAVE=%AUTO_SAVE%"
            exit /b 603
        )
    )
    
    <nul set /p="%ESC%[45;98H%ESC%[92mセーブ完了しました。%ESC%[0m"
    "%tools_dir%\cmdwiz.exe" delay 1200 >nul 2>&1
) else (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO ChapterResult "save skipped by user choice"
)

call :ClearSavePromptBox

:: -----------------------------------------------------------------------------
:: [4] Finish and Return
:: -----------------------------------------------------------------------------
endlocal & (
    set "player_level=%player_level%"
    set "%completed_var%=1"
    set "prologue_completed=%prologue_completed%"
    set "current_chapter=%current_chapter%"
    set "current_scene=%current_scene%"
    set "current_location=%current_location%"
    set "player_storyroute=%next_route%"
    set "AUTO_SAVE=%AUTO_SAVE%"
    exit /b 604
)

:: -----------------------------------------------------------------------------
:: Helper Functions
:: -----------------------------------------------------------------------------

:DrawSavePromptBox
<nul set /p="%ESC%[38;85H%ESC%[90m┌──────────────────────────────────────────────┐%ESC%[0m"
for /l %%r in (39,1,45) do (
    <nul set /p="%ESC%[%%r;85H%ESC%[90m│                                              │%ESC%[0m"
)
<nul set /p="%ESC%[46;85H%ESC%[90m└──────────────────────────────────────────────┘%ESC%[0m"
exit /b 0

:ClearSavePromptBox
for /l %%r in (38,1,46) do (
    <nul set /p="%ESC%[%%r;85H%ESC%[0K"
)
exit /b 0

:PersistAutoSavePreference
setlocal EnableDelayedExpansion
set "desired_auto_save=%~1"
if not defined desired_auto_save (
    endlocal
    exit /b 0
)

set "target_config=%config_profile_file%"
if not defined target_config set "target_config=%PROJECT_ROOT%\Config\user_config.env"
if not defined target_config (
    endlocal
    exit /b 0
)

for %%A in ("%target_config%") do set "target_dir=%%~dpA"
if defined target_dir if not exist "!target_dir!" md "!target_dir!" >nul 2>&1

set "tmp_config=%target_config%.tmp"
set "found_auto_save=0"

> "!tmp_config!" (
    if exist "!target_config!" (
        for /f "usebackq delims=" %%L in ("!target_config!") do (
            set "cfg_line=%%L"
            set "handled=0"
            for /f "tokens=1* delims==" %%K in ("!cfg_line!") do (
                if /i "%%K"=="AUTO_SAVE" (
                    echo AUTO_SAVE=!desired_auto_save!
                    set "found_auto_save=1"
                    set "handled=1"
                )
            )
            if "!handled!"=="0" echo(!cfg_line!
        )
    ) else (
        echo # Astral Divide profile [updated by ChapterResult.bat]
    )
    if "!found_auto_save!"=="0" echo AUTO_SAVE=!desired_auto_save!
)

move /y "!tmp_config!" "!target_config!" >nul 2>&1
if errorlevel 1 (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace WARN ChapterResult "failed to persist AUTO_SAVE=!desired_auto_save! path=!target_config!"
) else (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO ChapterResult "persisted AUTO_SAVE=!desired_auto_save! path=!target_config!"
)
endlocal
exit /b 0
