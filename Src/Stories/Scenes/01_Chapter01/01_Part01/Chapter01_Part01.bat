@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "CURRENT_SKIP_POLICY=1"
set "current_location=---"
set "current_chapter=Chapter01"
set "player_storyroute=Chapter01_Part01"
call :TryResumeFromSave
set "resume_entry_rc=%errorlevel%"
if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO Chapter01_Part01 "resume entry returned rc=%resume_entry_rc% handled=%resume_handled% scene=%current_scene%"
if "%resume_entry_rc%"=="641" (
    endlocal
    exit /b 641
)
if "%resume_entry_rc%"=="642" (
    endlocal
    exit /b 642
)
if "%resume_handled%"=="1" goto :Chapter01Exit
call :Display
call :Scene "Scene01_ToChapter1.txt"
set "current_location=王都エリュシオン - 自室"
call :Scene "Scene02_Chapter1Opening.txt"
call "%~dp0Chapter01_RoomExplore.bat"
set "room_rc=%errorlevel%"
if "%room_rc%"=="641" (
    endlocal
    exit /b 641
)
if "%room_rc%"=="642" (
    endlocal
    exit /b 642
)
set "CURRENT_SKIP_POLICY=1"
call :PlayAfterRoomSequence
set "after_room_rc=%errorlevel%"
if "%after_room_rc%"=="641" (
    endlocal
    exit /b 641
)
if "%after_room_rc%"=="642" (
    endlocal
    exit /b 642
)

:Chapter01Exit
endlocal & (
    set "player_storyroute=%player_storyroute%"
    set "current_chapter=%current_chapter%"
    set "current_scene=%current_scene%"
    set "current_location=%current_location%"
    set "resume_storyroute=%resume_storyroute%"
    set "resume_scene=%resume_scene%"
    set "resume_location=%resume_location%"
    set "current_save_supported=%current_save_supported%"
    set "player_money=%player_money%"
    set "chapter01_allowance_received=%chapter01_allowance_received%"
    set "chapter01_allowance_amount=%chapter01_allowance_amount%"
    set "chapter01_starter_items_received=%chapter01_starter_items_received%"
    set "chapter01_town_started=%chapter01_town_started%"
    set "chapter01_town_node=%chapter01_town_node%"
    set "chapter01_seen_home_intro=%chapter01_seen_home_intro%"
    set "chapter01_seen_plaza=%chapter01_seen_plaza%"
    set "chapter01_seen_tavern=%chapter01_seen_tavern%"
    set "chapter01_seen_academy_gate=%chapter01_seen_academy_gate%"
    set "chapter01_quest_tavern_intro=%chapter01_quest_tavern_intro%"
    set "inventory_stack_count=%inventory_stack_count%"
    set "inventory_stack_1=%inventory_stack_1%"
    set "inventory_stack_2=%inventory_stack_2%"
    set "inventory_stack_3=%inventory_stack_3%"
    set "inventory_stack_4=%inventory_stack_4%"
    set "inventory_stack_5=%inventory_stack_5%"
    set "inventory_stack_6=%inventory_stack_6%"
    set "inventory_stack_7=%inventory_stack_7%"
    set "inventory_stack_8=%inventory_stack_8%"
    set "inventory_unique_count=%inventory_unique_count%"
    set "inventory_unique_1=%inventory_unique_1%"
    set "inventory_unique_2=%inventory_unique_2%"
    set "inventory_unique_3=%inventory_unique_3%"
    set "inventory_unique_4=%inventory_unique_4%"
    set "inventory_unique_5=%inventory_unique_5%"
    set "inventory_unique_6=%inventory_unique_6%"
    set "inventory_unique_7=%inventory_unique_7%"
    set "inventory_unique_8=%inventory_unique_8%"
)
exit /b 604

:TryResumeFromSave
set "resume_handled=0"
if /i not "%player_storyroute%"=="Chapter01_Part01" exit /b 0
set "chapter01_town_node="
call :ResolveTownNodeFromScene
if not defined chapter01_town_node exit /b 0
set "resume_storyroute=Chapter01_Part01"
if not defined resume_scene set "resume_scene=%current_scene%"
if not defined resume_location set "resume_location=%current_location%"
call :AwardChapter01StarterItems
call "%~dp0Chapter01_TownExplore.bat"
set "resume_rc=%errorlevel%"
if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO Chapter01_Part01 "resume town explore returned rc=%resume_rc% location=%current_location% node=%chapter01_town_node%"
if "%resume_rc%"=="641" exit /b 641
if "%resume_rc%"=="642" exit /b 642
set "resume_handled=1"
exit /b 0

:ResolveTownNodeFromScene
set "scene_prefix=Chapter01_TownExplore_"
call set "scene_suffix=%%current_scene:%scene_prefix%=%%"
if not "%scene_suffix%"=="%current_scene%" set "chapter01_town_node=%scene_suffix%"
exit /b 0

:PlayAfterRoomSequence
set "current_scene=Chapter01_Part01_Downstairs"
set "current_location=王都エリュシオン - 自宅一階"
call :AwardAllowance 120
call :AwardChapter01StarterItems
call :Display
call :Scene "Scene03_Downstairs.txt"
set "current_scene=Chapter01_Part01_LeaveHome"
set "current_location=王都エリュシオン - 住宅区"
call :Display
call :Scene "Scene04_LeaveHome.txt"
if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO Chapter01_Part01 "enter town explore player_money=%player_money%"
call "%~dp0Chapter01_TownExplore.bat"
set "town_rc=%errorlevel%"
if defined RCSU if exist "%RCSU%" call "%RCSU%" -trace INFO Chapter01_Part01 "town explore returned rc=%town_rc% location=%current_location% node=%chapter01_town_node%"
if "%town_rc%"=="641" exit /b 641
if "%town_rc%"=="642" exit /b 642
exit /b 0

:AwardAllowance
if not defined player_money set "player_money=0"
set "chapter01_allowance_amount=%~1"
if "%chapter01_allowance_received%"=="1" exit /b 0
set /a player_money+=%~1
set "chapter01_allowance_received=1"
exit /b 0

:AwardChapter01StarterItems
if "%chapter01_starter_items_received%"=="1" exit /b 0
call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" INIT_DEFAULTS
call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" ADD key_astral_army_enlistment_form 1
call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" ADD use_potion_small 3
call "%PROJECT_ROOT%\Src\Systems\Inventory\InventoryCore.bat" ADD key_home_key 1
set "chapter01_starter_items_received=1"
exit /b 0

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
<nul set /p="%ESC%[64;108H%ESC%[90mSpace: 早送り  P/Esc: ポーズ%ESC%[0m"
exit /b 0

:DrawDialogueGuide
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: %current_location%%ESC%[0m"
<nul set /p="%ESC%[65;174H%ESC%[90mChapter1: 王都に生きる者%ESC%[0m"
exit /b 0
