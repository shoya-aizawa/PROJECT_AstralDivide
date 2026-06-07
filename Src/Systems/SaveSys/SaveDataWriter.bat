@echo off
setlocal EnableExtensions EnableDelayedExpansion

if not defined RCS_S_ERR set "RCS_S_ERR=9"
if not defined RCS_D_SAVE set "RCS_D_SAVE=02"
if not defined RCS_R_IO set "RCS_R_IO=10"
if not defined RCS_R_VALID set "RCS_R_VALID=30"

set "save_kind=%~1"
set "save_slot=%~2"
set "save_point=%~3"

if not defined save_kind set "save_kind=AUTO"
if not defined save_point set "save_point=unknown"

:: Sync autosave_enabled with global AUTO_SAVE setting if defined
if defined AUTO_SAVE (
    if /i "%AUTO_SAVE%"=="OFF" (
        set "autosave_enabled=0"
    ) else (
        set "autosave_enabled=1"
    )
)

:: If it is an AUTO save request but autosave is disabled, skip it silently
if /i "%save_kind%"=="AUTO" (
    if "%autosave_enabled%"=="0" (
        if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO SaveDataWriter "autosave is disabled, skipping write"
        exit /b 0
    )
)

if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO SaveDataWriter "start kind=%save_kind% slot=%save_slot% point=%save_point%"

call :ValidateSlot "%save_slot%"
if errorlevel 1 (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_VALID% 001 "Save invalid slot" "slot=%save_slot%;point=%save_point%"
    exit /b 90230001
)

if not defined saves_active_dir (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_VALID% 002 "Save directory missing" "slot=%save_slot%;point=%save_point%"
    exit /b 90230002
)

if not exist "%saves_active_dir%" md "%saves_active_dir%" >nul 2>&1
if not exist "%saves_active_dir%" (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 001 "Save directory create failed" "dir=%saves_active_dir%"
    exit /b 90210001
)

call :ApplySavePointDefaults "%save_point%"
call :ApplyFieldDefaults

set "save_path=%saves_active_dir%\SaveData_%save_slot%.txt"
set "tmp_path=%save_path%.tmp"
set "saved_at=%DATE% %TIME%"

> "%tmp_path%" (
    echo save_version=1
    echo save_kind=%save_kind%
    echo save_slot=%save_slot%
    echo save_point=%save_point%
    echo saved_at=%saved_at%
    echo player_name=%player_name%
    echo player_level=%player_level%
    echo player_storyroute=%player_storyroute%
    echo current_chapter=%current_chapter%
    echo current_scene=%current_scene%
    echo current_location=%current_location%
    echo prologue_completed=%prologue_completed%
    for /f "tokens=1* delims==" %%A in ('set completed_chapter_ 2^>nul') do echo %%A=%%B
    echo autosave_enabled=%autosave_enabled%
    echo camp_explore_viewed_count=%camp_explore_viewed_count%
    echo camp_seen_1=%camp_seen_1%
    echo camp_seen_2=%camp_seen_2%
    echo camp_seen_3=%camp_seen_3%
    echo camp_seen_4=%camp_seen_4%
    echo camp_seen_5=%camp_seen_5%
    echo camp_seen_6=%camp_seen_6%
)

if not exist "%tmp_path%" (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 002 "Save temp write failed" "slot=%save_slot%;path=%tmp_path%"
    exit /b 90210002
)

move /y "%tmp_path%" "%save_path%" >nul 2>&1
if errorlevel 1 (
    if defined RCSU if exist "%RCSU%" call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 003 "Save replace failed" "slot=%save_slot%;path=%save_path%"
    exit /b 90210003
)

if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO SaveDataWriter "saved slot=%save_slot% path=%save_path%"
exit /b 0

:ValidateSlot
set "slot_to_check=%~1"
if not defined slot_to_check exit /b 1
for /f "delims=0123456789" %%A in ("%slot_to_check%") do exit /b 1
if %slot_to_check% LSS 1 exit /b 1
if %slot_to_check% GTR 12 exit /b 1
exit /b 0

:ApplySavePointDefaults
set "point=%~1"
if /i "%point%"=="prologue_end" (
    set "player_storyroute=PrologueComplete"
    set "current_chapter=Prologue"
    set "current_scene=PrologueComplete"
    set "current_location=星が降る丘"
    set "prologue_completed=1"
    set "completed_chapter_Prologue=1"
)
exit /b 0

:ApplyFieldDefaults
if not defined player_name set "player_name=シオン"
if not defined player_level set "player_level=0"
if not defined player_storyroute set "player_storyroute=NewGame"
if not defined current_chapter set "current_chapter=Unknown"
if not defined current_scene set "current_scene=Unknown"
if not defined current_location set "current_location=Unknown"
if not defined prologue_completed set "prologue_completed=0"
if "%prologue_completed%"=="1" if not defined completed_chapter_Prologue set "completed_chapter_Prologue=1"
if not defined autosave_enabled set "autosave_enabled=1"
if not defined camp_explore_viewed_count set "camp_explore_viewed_count=0"
for /l %%I in (1,1,6) do if not defined camp_seen_%%I set "camp_seen_%%I=0"
exit /b 0
