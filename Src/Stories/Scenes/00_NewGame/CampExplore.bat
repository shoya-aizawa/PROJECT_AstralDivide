@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "BG_FILE=%assets_images_dir%\A_Nighttime_Settlement_of_War_Refugees.png"
if exist "%BG_FILE%" %tools_dir%\cmdbkg.exe "%BG_FILE%" /b >nul 2>&1

call :InitHotspots
call :RenderStatic
call :RenderDynamic

:explore_loop
choice /c WASDFQ /n >nul
set "pick=%errorlevel%"
if "%pick%"=="1" call :MoveUp & goto :explore_loop
if "%pick%"=="2" call :MoveLeft & goto :explore_loop
if "%pick%"=="3" call :MoveDown & goto :explore_loop
if "%pick%"=="4" call :MoveRight & goto :explore_loop
if "%pick%"=="5" call :InspectCurrent & goto :explore_loop
if "%pick%"=="6" call :TryLeave & if "!leave_confirmed!"=="1" goto :exit_explore
goto :explore_loop

:InitHotspots
set "current_spot=4"
set "prev_spot=0"
set /a viewed_count=0
set /a radio_roll=0

set "spot_name_1=カオレオン人のラジオ"
set "spot_hint_1=前線の報告が流れている。耳を澄ますたび、違う話が混じる。"
set "spot_x_1=183"
set "spot_y_1=22"
set "spot_scene_1=Scene00_CampExplore_Radio_01.txt"
set "spot_seen_1=0"
set "spot_up_1=1"
set "spot_down_1=6"
set "spot_left_1=4"
set "spot_right_1=1"

set "spot_name_2=配給に不満を持つ避難民"
set "spot_hint_2=疲れた声でぼやいている。列はもう崩れかけている。"
set "spot_x_2=36"
set "spot_y_2=46"
set "spot_scene_2=Scene00_CampExplore_Ration.txt"
set "spot_seen_2=0"
set "spot_up_2=5"
set "spot_down_2=2"
set "spot_left_2=2"
set "spot_right_2=4"

set "spot_name_3=看病する母親"
set "spot_hint_3=寝息のそばで、小さな声が揺れている。"
set "spot_x_3=186"
set "spot_y_3=50"
set "spot_scene_3=Scene00_CampExplore_MotherChild.txt"
set "spot_seen_3=0"
set "spot_up_3=6"
set "spot_down_3=3"
set "spot_left_3=4"
set "spot_right_3=3"

set "spot_name_4=焚き火の輪"
set "spot_hint_4=子どもや大人の声が混じる。丘の噂もここから聞こえる。"
set "spot_x_4=119"
set "spot_y_4=44"
set "spot_scene_4=Scene00_CampExplore_Campfire.txt"
set "spot_seen_4=0"
set "spot_up_4=5"
set "spot_down_4=4"
set "spot_left_4=2"
set "spot_right_4=3"

set "spot_name_5=両国民の噂話"
set "spot_hint_5=停戦と国境の話。声は低いが、熱はこもっている。"
set "spot_x_5=81"
set "spot_y_5=30"
set "spot_scene_5=Scene00_CampExplore_MixedCitizens.txt"
set "spot_seen_5=0"
set "spot_up_5=5"
set "spot_down_5=4"
set "spot_left_5=5"
set "spot_right_5=1"

set "spot_name_6=見回り兵"
set "spot_hint_6=丘の先を警戒している。静かな夜ほど落ち着かないようだ。"
set "spot_x_6=154"
set "spot_y_6=33"
set "spot_scene_6=Scene00_CampExplore_Sentry.txt"
set "spot_seen_6=0"
set "spot_up_6=1"
set "spot_down_6=3"
set "spot_left_6=5"
set "spot_right_6=6"
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
)
call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter4.wav"
call :Display
call :Scene "%scene_file%"
<nul set /p="%ESC%[65;74H%ESC%[90m何かキーを押して疎開キャンプ探索に戻る%ESC%[0m"
"%tools_dir%\cmdwiz.exe" getch >nul 2>&1
call :RenderStatic
set "prev_spot=0"
call :RenderDynamic
exit /b 0

:TryLeave
set "leave_confirmed=0"
<nul set /p="%ESC%[62;82H%ESC%[0K%ESC%[90m丘へ向かいますか？ [Y/N]%ESC%[0m"
choice /c YN /n >nul
if errorlevel 2 (
    <nul set /p="%ESC%[62;74H%ESC%[0K"
    call :RenderDynamic
    exit /b 0
)
set "leave_confirmed=1"
exit /b 0

:RenderStatic
call :Display
for /l %%i in (1,1,6) do call :DrawSpot %%i
exit /b 0

:RenderDynamic
if not "%prev_spot%"=="0" call :DrawSpot %prev_spot%
call :DrawSpot %current_spot%
call :DrawExploreStatus
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

:DrawExploreStatus
call set "cur_name=%%spot_name_%current_spot%%%"
call set "cur_hint=%%spot_hint_%current_spot%%%"
<nul set /p="%ESC%[59;28H%ESC%[0K%ESC%[93m注目:%ESC%[0m %cur_name%"
<nul set /p="%ESC%[60;28H%ESC%[0K%ESC%[90m%cur_hint%%ESC%[0m"
if %viewed_count% GEQ 6 (
    <nul set /p="%ESC%[61;28H%ESC%[0K%ESC%[96m……もう十分見た。丘に向かってみよう。%ESC%[0m"
) else (
    <nul set /p="%ESC%[61;28H%ESC%[0K%ESC%[90m任意の寄り道。何も調べなくても、そのまま丘へ向かえる。%ESC%[0m"
)
<nul set /p="%ESC%[65;96H%ESC%[90mWASD=移動  F=調べる  Q=丘へ向かう  Seen %viewed_count%/6%ESC%[0m"
exit /b 0

:Display
cls
call :DrawDialogueGuide
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
<nul set /p="%ESC%[3;103H%ESC%[90m疎開キャンプ内の探索%ESC%[0m"
<nul set /p="%ESC%[4;90H%ESC%[0K"
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[6;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90m現在地: 疎開キャンプ%ESC%[0m"
<nul set /p="%ESC%[65;186H%ESC%[90mexplore%ESC%[0m"
exit /b 0

:exit_explore
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
