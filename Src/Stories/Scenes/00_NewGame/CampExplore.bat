@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
set "CURRENT_SKIP_POLICY=1"

set "BG_FILE=%assets_images_dir%\A_Nighttime_Settlement_of_War_Refugees.png"
if exist "%BG_FILE%" %tools_dir%\cmdbkg.exe "%BG_FILE%" /b >nul 2>&1

call :InitHotspots
call :RenderStatic
call :RenderDynamic

:explore_loop
if "%SCENARIO_SKIP_ACTIVE%"=="1" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "skipping camp explore loop, preserving current state"
    goto :exit_explore
)
call :PollExploreInput
if "%pick%"=="0" (
    "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :explore_loop
)
if "%pick%"=="PAUSE" (
    if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "pause requested current_spot=%current_spot% viewed=%viewed_count%"
    call "%src_display_dir%\PauseManager.bat" ENTER FULL
    set "pause_rc=!errorlevel!"
    if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "pause returned rc=!pause_rc!"
    if "!pause_rc!"=="641" goto :exit_to_title
    if "!pause_rc!"=="642" goto :exit_game
    call :RenderStatic
    set "prev_spot=0"
    call :RenderDynamic
    goto :explore_loop
)
if "%pick%"=="1" call :MoveUp & goto :explore_loop
if "%pick%"=="2" call :MoveLeft & goto :explore_loop
if "%pick%"=="3" call :MoveDown & goto :explore_loop
if "%pick%"=="4" call :MoveRight & goto :explore_loop
if "%pick%"=="5" (
    call :InspectCurrent
    if "!leave_confirmed!"=="1" goto :exit_explore
    goto :explore_loop
)
goto :explore_loop

:PollExploreInput
set "pick=0"
call "%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "key_code=%errorlevel%"
if "%key_code%"=="0" exit /b 0

if "%key_code%"=="87" set "pick=1"
if "%key_code%"=="119" set "pick=1"
if "%key_code%"=="23" set "pick=1"
if "%key_code%"=="72" set "pick=1"
if "%key_code%"=="65" set "pick=2"
if "%key_code%"=="97" set "pick=2"
if "%key_code%"=="1" if "%pick%"=="0" set "pick=2"
if "%key_code%"=="75" if "%pick%"=="0" set "pick=2"
if "%key_code%"=="83" set "pick=3"
if "%key_code%"=="115" set "pick=3"
if "%key_code%"=="19" set "pick=3"
if "%key_code%"=="80" if "%pick%"=="0" set "pick=3"
if "%key_code%"=="68" set "pick=4"
if "%key_code%"=="100" set "pick=4"
if "%key_code%"=="4" if "%pick%"=="0" set "pick=4"
if "%key_code%"=="77" if "%pick%"=="0" set "pick=4"
if "%key_code%"=="70" set "pick=5"
if "%key_code%"=="102" set "pick=5"
if "%key_code%"=="33" if "%pick%"=="0" set "pick=5"
if "%key_code%"=="13" if "%pick%"=="0" set "pick=5"
if "%key_code%"=="28" if "%pick%"=="0" set "pick=5"
if "%key_code%"=="27" set "pick=PAUSE"
if "%key_code%"=="112" if "%pick%"=="0" set "pick=PAUSE"
if "%key_code%"=="25" if "%pick%"=="0" set "pick=PAUSE"
exit /b 0

:InitHotspots
set "current_spot=4"
set "prev_spot=0"

:: Import progress from loaded save data if exists
if defined camp_explore_viewed_count (
    set /a viewed_count=camp_explore_viewed_count
) else (
    set /a viewed_count=0
)
set /a radio_roll=0

set "spot_name_1=カオレオン人のラジオ"
set "spot_hint_1=前線の報告が流れている。耳を澄ますたび、違う話が混じる。"
set "spot_x_1=183"
set "spot_y_1=22"
set "spot_scene_1=Scene00_CampExplore_Radio_01.txt"
if defined camp_seen_1 (set "spot_seen_1=%camp_seen_1%") else (set "spot_seen_1=0")
set "spot_up_1=7"
set "spot_down_1=6"
set "spot_left_1=4"
set "spot_right_1=1"

set "spot_name_2=配給に不満を持つ避難民"
set "spot_hint_2=疲れた声でぼやいている。列はもう崩れかけている。"
set "spot_x_2=36"
set "spot_y_2=46"
set "spot_scene_2=Scene00_CampExplore_Ration.txt"
if defined camp_seen_2 (set "spot_seen_2=%camp_seen_2%") else (set "spot_seen_2=0")
set "spot_up_2=5"
set "spot_down_2=2"
set "spot_left_2=2"
set "spot_right_2=4"

set "spot_name_3=看病する母親"
set "spot_hint_3=寝息のそばで、小さな声が揺れている。"
set "spot_x_3=186"
set "spot_y_3=50"
set "spot_scene_3=Scene00_CampExplore_MotherChild.txt"
if defined camp_seen_3 (set "spot_seen_3=%camp_seen_3%") else (set "spot_seen_3=0")
set "spot_up_3=6"
set "spot_down_3=3"
set "spot_left_3=4"
set "spot_right_3=3"

set "spot_name_4=焚き火の輪"
set "spot_hint_4=子どもや大人の声が混じる。丘の噂もここから聞こえる。"
set "spot_x_4=119"
set "spot_y_4=44"
set "spot_scene_4=Scene00_CampExplore_Campfire.txt"
if defined camp_seen_4 (set "spot_seen_4=%camp_seen_4%") else (set "spot_seen_4=0")
set "spot_up_4=5"
set "spot_down_4=4"
set "spot_left_4=2"
set "spot_right_4=3"

set "spot_name_5=両国民の噂話"
set "spot_hint_5=停戦と国境の話。声は低いが、熱はこもっている。"
set "spot_x_5=81"
set "spot_y_5=30"
set "spot_scene_5=Scene00_CampExplore_MixedCitizens.txt"
if defined camp_seen_5 (set "spot_seen_5=%camp_seen_5%") else (set "spot_seen_5=0")
set "spot_up_5=5"
set "spot_down_5=4"
set "spot_left_5=5"
set "spot_right_5=1"

set "spot_name_6=見回り兵"
set "spot_hint_6=丘の先を警戒している。静かな夜ほど落ち着かないようだ。"
set "spot_x_6=154"
set "spot_y_6=33"
set "spot_scene_6=Scene00_CampExplore_Sentry.txt"
if defined camp_seen_6 (set "spot_seen_6=%camp_seen_6%") else (set "spot_seen_6=0")
set "spot_up_6=1"
set "spot_down_6=3"
set "spot_left_6=5"
set "spot_right_6=7"

set "spot_name_7=丘への道"
set "spot_hint_7=疎開キャンプの離れ。見回り兵が居ない今のうちに…"
set "spot_x_7=198"
set "spot_y_7=12"
set "spot_scene_7="
set "spot_seen_7=1"
set "spot_up_7=7"
set "spot_down_7=1"
set "spot_left_7=6"
set "spot_right_7=7"
exit /b 0

:MoveUp
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_up_%current_spot%%%"
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveDown
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_down_%current_spot%%%"
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveLeft
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_left_%current_spot%%%"
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:MoveRight
set "prev_spot=%current_spot%"
call set "current_spot=%%spot_right_%current_spot%%%"
call :AnimateMove %prev_spot% %current_spot%
call :RenderDynamic
exit /b 0

:AnimateMove
setlocal EnableDelayedExpansion
set "from=%~1"
set "to=%~2"
if "%from%"=="%to%" exit /b 0
call set /a ox=%%spot_x_%from%%%
call set /a oy=%%spot_y_%from%%%
call set /a nx=%%spot_x_%to%%%
call set /a ny=%%spot_y_%to%%%
set /a dx=nx-ox
set /a dy=ny-oy
set "lastx="
set "lasty="
for /l %%s in (1,1,3) do (
    set /a tx=ox + dx * %%s / 4
    set /a ty=oy + dy * %%s / 4
    if defined lastx (
        <nul set /p="%ESC%[!lasty!;!lastx!H "
    )
    <nul set /p="%ESC%[!ty!;!tx!H%ESC%[96m•%ESC%[0m"
    %tools_dir%\cmdwiz.exe delay 28 >nul 2>&1
    set "lastx=!tx!"
    set "lasty=!ty!"
)
if defined lastx <nul set /p="%ESC%[!lasty!;!lastx!H "
endlocal
exit /b 0

:InspectCurrent
if "%current_spot%"=="7" (
    call :TryLeave
    if "!leave_confirmed!"=="1" exit /b 0
    call :RenderDynamic
    exit /b 0
)
call set "scene_file=%%spot_scene_%current_spot%%%"
if "%current_spot%"=="1" (
    set /a radio_roll=radio_roll+1
    if !radio_roll! GTR 3 set /a radio_roll=1
    set "scene_file=Scene00_CampExplore_Radio_0!radio_roll!.txt"
)
call set "seen_flag=%%spot_seen_%current_spot%%%"
if "%seen_flag%"=="0" (
    set /a viewed_count=viewed_count+1
    set "spot_seen_%current_spot%=1"
    
    :: Write back to global save variables
    set "camp_explore_viewed_count=!viewed_count!"
    set "camp_seen_%current_spot%=1"
)
call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
call :Display
call :Scene "%scene_file%"
<nul set /p="%ESC%[65;94H%ESC%[90m何かキーを押して疎開キャンプ探索に戻る%ESC%[0m"
"%tools_dir%\cmdwiz.exe" getch >nul 2>&1
%tools_dir%\cmdbkg.exe "%BG_FILE%" /b >nul 2>&1
call :RenderStatic
set "prev_spot=0"
call :RenderDynamic
exit /b 0

:TryLeave
set "leave_confirmed=0"
call :DrawLeaveConfirm
choice /c FQ /n >nul
if "%errorlevel%"=="2" (
    call :ClearLeaveConfirm
    exit /b 0
)
call :ClearLeaveConfirm
set "leave_confirmed=1"
exit /b 0

:DrawLeaveConfirm
<nul set /p="%ESC%[12;154H%ESC%[90m< 丘へ向かいますか？ [F/Q]%ESC%[0m"
exit /b 0

:ClearLeaveConfirm
<nul set /p="%ESC%[12;154H                                %ESC%[12;190H"
exit /b 0

:RenderStatic
call :Display
for /l %%i in (1,1,7) do call :DrawSpot %%i
exit /b 0

:RenderDynamic
if not "%prev_spot%"=="0" call :DrawSpot %prev_spot%
call :DrawSpot %current_spot%
call :DrawGoalMarker
call :DrawExploreStatus
call :DrawObjectivePanel
call :DrawExploreFooter
exit /b 0

:DrawSpot
setlocal EnableDelayedExpansion
set "idx=%~1"
call set "sx=%%spot_x_%idx%%%"
call set "sy=%%spot_y_%idx%%%"
call set "seen=%%spot_seen_%idx%%%"
set "mark_color=%ESC%[90m"
set "mark= ◇ "
if "!seen!"=="1" (
    set "mark_color=%ESC%[92m"
    set "mark= ◆ "
)
if "%idx%"=="%current_spot%" (
    set "mark_color=%ESC%[96m"
    if "!seen!"=="1" (
        set "mark=[◆]"
    ) else (
        set "mark=[◇]"
    )
)
set /a draw_x=sx-1
<nul set /p="%ESC%[!sy!;!draw_x!H!mark_color!!mark!%ESC%[0m"
endlocal
exit /b 0

:DrawGoalMarker
<nul set /p="%ESC%[12;190H%ESC%[93m[^!]^>%ESC%[0m"
exit /b 0

:DrawExploreStatus
call set "cur_name=%%spot_name_%current_spot%%%"
call set "cur_hint=%%spot_hint_%current_spot%%%"
<nul set /p="%ESC%[59;28H%ESC%[0K%ESC%[93m注目:%ESC%[0m %cur_name%"
<nul set /p="%ESC%[60;28H%ESC%[0K%ESC%[90m%cur_hint%%ESC%[0m"
if %viewed_count% GEQ 6 (
    <nul set /p="%ESC%[61;28H%ESC%[0K%ESC%[96mもう十分見て回った…丘へ向かおう。%ESC%[0m"
) else (
    <nul set /p="%ESC%[61;28H%ESC%[0K%ESC%[90m気になる場所は任意で調べられる。目的地から丘へ向かえる。%ESC%[0m"
)
exit /b 0

:DrawExploreFooter
<nul set /p="%ESC%[64;96H%ESC%[0KWASD=移動  F=調べる/選択  Q=キャンセル%ESC%[0m"
exit /b 0

:DrawObjectivePanel
setlocal EnableDelayedExpansion
set "objective_title=目標"
set "objective_main=丘へ向かう"
set "objective_sub=目的地から次へ進む"
set "optional_title=任意目標"
set "optional_main=避難民を見て回る"
set "optional_sub=進捗 !viewed_count!/6"
set "objective_accent=%ESC%[93m"
set "objective_main_color=%ESC%[97m"
set "objective_sub_color=%ESC%[96m"
set "optional_accent=%ESC%[90m"
set "optional_main_color=%ESC%[37m"
set "optional_sub_color=%ESC%[90m"
set "objective_rule=%ESC%[90m──────────────────%ESC%[0m"

set "objective_right=%CONSOLE_WIDTH%"
if not defined objective_right set "objective_right=%CONSOLE_COLS%"
if not defined objective_right set "objective_right=210"
set /a "objective_left=objective_right-18"
if !objective_left! LSS 160 set "objective_left=160"

if !viewed_count! GEQ 6 set "optional_sub=全地点を確認済み"

<nul set /p="%ESC%[12;!objective_left!H%ESC%[0K!objective_accent!!objective_title!%ESC%[0m"
<nul set /p="%ESC%[13;!objective_left!H%ESC%[0K!objective_rule!"
<nul set /p="%ESC%[14;!objective_left!H%ESC%[0K!objective_main_color!!objective_main!%ESC%[0m"
<nul set /p="%ESC%[15;!objective_left!H%ESC%[0K!objective_sub_color!!objective_sub!%ESC%[0m"
<nul set /p="%ESC%[17;!objective_left!H%ESC%[0K!optional_accent!!optional_title!%ESC%[0m"
<nul set /p="%ESC%[18;!objective_left!H%ESC%[0K!objective_rule!"
<nul set /p="%ESC%[19;!objective_left!H%ESC%[0K!optional_main_color!!optional_main!%ESC%[0m"
<nul set /p="%ESC%[20;!objective_left!H%ESC%[0K!optional_sub_color!!optional_sub!%ESC%[0m"
endlocal
exit /b 0

:Display
cls
call :DrawDialogueGuide
<nul set /p="%ESC%[64;24H%ESC%[0K"
exit /b 0

:Scene
    set "scene_skipped=0"
    set "RENDER_BG_T=33"
    set "RENDER_BG_PATH="
    call :DrawTextInputGuide
    for /f "eol=# usebackq delims=" %%L in ("%src_text_newgame_dir%\%~1") do (
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

:DrawTextInputGuide
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[64;108H%ESC%[90mF/Space: 早送り  P/Esc: ポーズ%ESC%[0m"
exit /b 0

:DrawDialogueGuide
<nul set /p="%ESC%[3;103H%ESC%[90m疎開キャンプ内の探索%ESC%[0m"
<nul set /p="%ESC%[4;90H%ESC%[0K"
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: 疎開キャンプ%ESC%[0m"
<nul set /p="%ESC%[65;187H%ESC%[90mPrologue: 星の夢%ESC%[0m"
exit /b 0

:exit_explore
if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "exit normal viewed=%viewed_count%"
endlocal & (
    set "camp_explore_viewed_count=%viewed_count%"
    set "camp_seen_1=%spot_seen_1%"
    set "camp_seen_2=%spot_seen_2%"
    set "camp_seen_3=%spot_seen_3%"
    set "camp_seen_4=%spot_seen_4%"
    set "camp_seen_5=%spot_seen_5%"
    set "camp_seen_6=%spot_seen_6%"
)
exit /b 0

:exit_to_title
if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "exit to title viewed=%viewed_count%"
endlocal & (
    set "camp_explore_viewed_count=%viewed_count%"
)
exit /b 641

:exit_game
if exist "%RCSU%" call "%RCSU%" -trace INFO CampExplore "exit game viewed=%viewed_count%"
endlocal & (
    set "camp_explore_viewed_count=%viewed_count%"
)
exit /b 642
