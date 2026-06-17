@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
call "%~dp0..\Environment\SettingPath.bat" SILENT >nul 2>&1
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"
set "CMDWIZ=%tools_dir%\cmdwiz.exe"
mode 240,67 >nul 2>&1
powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1

if "%~1"=="" (
    set "TARGET_LAYOUT=%PROJECT_ROOT%\Assets\Layouts\01_Chapter01\01_Part01\Chapter01_RoomExplore.layout.bat"
) else (
    set "TARGET_LAYOUT=%~f1"
)
if not exist "%TARGET_LAYOUT%" (
    echo Layout file not found: "%TARGET_LAYOUT%"
    pause
    exit /b 1
)

call :LoadLayout
set /a current_page_idx=1
call set "current_page=%%page_id_%current_page_idx%%%"
call set "current_spot=%%page_default_spot_%current_page_idx%%%"
call :ApplyCurrentBackground
call :FullRender

:editor_loop
call :PollKey
if "%key_code%"=="0" (
    "%CMDWIZ%" delay 10 >nul 2>&1
    goto :editor_loop
)

if "%key_code%"=="81" goto :done
if /i "%key_code%"=="113" goto :done
if "%key_code%"=="82" call :ReloadLayout & goto :editor_loop
if /i "%key_code%"=="114" call :ReloadLayout & goto :editor_loop
if "%key_code%"=="75" call :SaveLayout & goto :editor_loop
if /i "%key_code%"=="107" call :SaveLayout & goto :editor_loop
if "%key_code%"=="71" call :CyclePage & goto :editor_loop
if /i "%key_code%"=="103" call :CyclePage & goto :editor_loop
if "%key_code%"=="78" call :CycleSpot 1 & goto :editor_loop
if /i "%key_code%"=="110" call :CycleSpot 1 & goto :editor_loop
if "%key_code%"=="80" call :CycleSpot -1 & goto :editor_loop
if /i "%key_code%"=="112" call :CycleSpot -1 & goto :editor_loop

if "%key_code%"=="87" call :MoveSpot -5 0 & goto :editor_loop
if "%key_code%"=="119" call :MoveSpot -1 0 & goto :editor_loop
if "%key_code%"=="83" call :MoveSpot 5 0 & goto :editor_loop
if "%key_code%"=="115" call :MoveSpot 1 0 & goto :editor_loop
if "%key_code%"=="65" call :MoveSpot 0 -10 & goto :editor_loop
if "%key_code%"=="97" call :MoveSpot 0 -1 & goto :editor_loop
if "%key_code%"=="68" call :MoveSpot 0 10 & goto :editor_loop
if "%key_code%"=="100" call :MoveSpot 0 1 & goto :editor_loop

goto :editor_loop

:done
<nul set /p="%ESC%[?25h%ESC%[0m"
endlocal
exit /b 0

:PollKey
set "key_code=0"
"%CMDWIZ%" getch noWait >nul 2>&1
set "key_code=%errorlevel%"
exit /b 0

:LoadLayout
call "%TARGET_LAYOUT%"
set "status_msg=Loaded layout."
exit /b 0

:ReloadLayout
call :LoadLayout
call :ApplyCurrentBackground
call :FullRender
exit /b 0

:CyclePage
set /a current_page_idx+=1
if %current_page_idx% GTR %page_count% set /a current_page_idx=1
call set "current_page=%%page_id_%current_page_idx%%%"
call set "current_spot=%%page_default_spot_%current_page_idx%%%"
set "LAST_EDITOR_BG="
call :ApplyCurrentBackground
set "status_msg=Page switched."
call :FullRender
exit /b 0

:CycleSpot
set "dir=%~1"
set "candidate=%current_spot%"
:cycle_spot_loop
set /a candidate+=dir
if %candidate% LSS 1 set /a candidate=spot_count
if %candidate% GTR %spot_count% set /a candidate=1
call set "candidate_page=%%spot_page_%candidate%%%"
if /i "%candidate_page%"=="%current_page%" (
    set "current_spot=%candidate%"
    set "status_msg=Spot switched."
    call :FullRender
    exit /b 0
)
if "%candidate%"=="%current_spot%" exit /b 0
goto :cycle_spot_loop

:MoveSpot
set /a dy=%~1
set /a dx=%~2
call set /a new_y=%%spot_y_%current_spot%%% + dy
call set /a new_x=%%spot_x_%current_spot%%% + dx
if %new_y% LSS 1 set /a new_y=1
if %new_x% LSS 1 set /a new_x=1
set "spot_y_%current_spot%=%new_y%"
set "spot_x_%current_spot%=%new_x%"
set "status_msg=Spot moved."
call :FullRender
exit /b 0

:ApplyCurrentBackground
set "page_bg_name="
for /l %%i in (1,1,%page_count%) do (
    call set "page_id_value=%%page_id_%%i%%%"
    if /i "!page_id_value!"=="%current_page%" call set "page_bg_name=%%page_bg_%%i%%%"
)
if not defined page_bg_name exit /b 0
set "EDITOR_BG=%assets_images_dir%\%page_bg_name%"
if not exist "%EDITOR_BG%" exit /b 0
if /i "%LAST_EDITOR_BG%"=="%EDITOR_BG%" exit /b 0
%tools_dir%\cmdbkg.exe "%EDITOR_BG%" /b >nul 2>&1
set "LAST_EDITOR_BG=%EDITOR_BG%"
exit /b 0

:FullRender
cls
call :DrawGuide
for /l %%i in (1,1,%spot_count%) do (
    call set "spot_page=%%spot_page_%%i%%%"
    if /i "!spot_page!"=="%current_page%" call :DrawSpot %%i
)
call :DrawStatus
exit /b 0

:DrawGuide
<nul set /p="%ESC%[3;96H%ESC%[90mHotspot Layout Editor%ESC%[0m"
<nul set /p="%ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
exit /b 0

:DrawSpot
setlocal EnableDelayedExpansion
set "idx=%~1"
call set "sx=%%spot_x_%idx%%%"
call set "sy=%%spot_y_%idx%%%"
call set "spot_id=%%spot_id_%idx%%%"
call set "marker_type=%%spot_marker_%idx%%%"
set "mark_color=%ESC%[90m"
call :ResolveMarker "!marker_type!" normal mark
if "%idx%"=="%current_spot%" (
    set "mark_color=%ESC%[96m"
    call :ResolveMarker "!marker_type!" active mark
)
set /a draw_x=sx-1
<nul set /p="%ESC%[!sy!;!draw_x!H!mark_color!!mark!%ESC%[0m"
endlocal
exit /b 0

:ResolveMarker
setlocal
set "marker_type=%~1"
set "variant=%~2"
set "mark= ◇ "
if /i "%marker_type%"=="nav_right" set "mark= > "
if /i "%marker_type%"=="nav_left" set "mark= < "
if /i "%marker_type%"=="door" set "mark= □ "
if /i "%variant%"=="active" (
    if /i "%marker_type%"=="diamond" set "mark=[◇]"
    if /i "%marker_type%"=="nav_right" set "mark=[>]"
    if /i "%marker_type%"=="nav_left" set "mark=[<]"
    if /i "%marker_type%"=="door" set "mark=[□]"
)
endlocal & set "%~3=%mark%"
exit /b 0

:DrawStatus
call set "spot_id=%%spot_id_%current_spot%%%"
call set "sx=%%spot_x_%current_spot%%%"
call set "sy=%%spot_y_%current_spot%%%"
call set "spot_action=%%spot_action_%current_spot%%%"
call set "spot_scene=%%spot_scene_%current_spot%%%"
<nul set /p="%ESC%[64;24H%ESC%[0K%ESC%[93mLayout:%ESC%[0m %TARGET_LAYOUT%"
<nul set /p="%ESC%[65;24H%ESC%[0K%ESC%[93mPage:%ESC%[0m %current_page% (%current_page_idx%/%page_count%)   %ESC%[93mSpot:%ESC%[0m %spot_id% (%current_spot%/%spot_count%)"
<nul set /p="%ESC%[66;24H%ESC%[0K%ESC%[93mPos:%ESC%[0m X=%sx% Y=%sy%   %ESC%[93mAction:%ESC%[0m %spot_action%   %ESC%[93mScene:%ESC%[0m %spot_scene%"
<nul set /p="%ESC%[67;24H%ESC%[0K%ESC%[90mWASD move  Shift+W/S=5 rows  Shift+A/D=10 cols  N/P=spot  G=page  K=save  R=reload  Q=quit   %status_msg%%ESC%[0m"
exit /b 0

:SaveLayout
(
    echo @echo off
    echo set "layout_id=%layout_id%"
    echo set "page_count=%page_count%"
    for /l %%i in (1,1,%page_count%) do (
        call echo set "page_id_%%i=%%page_id_%%i%%%"
        call echo set "page_bg_%%i=%%page_bg_%%i%%%"
        call echo set "page_default_spot_%%i=%%page_default_spot_%%i%%%"
    )
    echo.
    echo set "spot_count=%spot_count%"
    echo.
    for /l %%i in (1,1,%spot_count%) do (
        call echo set "spot_id_%%i=%%spot_id_%%i%%%"
        call echo set "spot_page_%%i=%%spot_page_%%i%%%"
        call echo set "spot_x_%%i=%%spot_x_%%i%%%"
        call echo set "spot_y_%%i=%%spot_y_%%i%%%"
        call echo set "spot_hit_w_%%i=%%spot_hit_w_%%i%%%"
        call echo set "spot_hit_h_%%i=%%spot_hit_h_%%i%%%"
        call echo set "spot_action_%%i=%%spot_action_%%i%%%"
        call echo set "spot_target_%%i=%%spot_target_%%i%%%"
        call echo set "spot_scene_%%i=%%spot_scene_%%i%%%"
        call echo set "spot_marker_%%i=%%spot_marker_%%i%%%"
        call echo set "spot_up_%%i=%%spot_up_%%i%%%"
        call echo set "spot_down_%%i=%%spot_down_%%i%%%"
        call echo set "spot_left_%%i=%%spot_left_%%i%%%"
        call echo set "spot_right_%%i=%%spot_right_%%i%%%"
        echo.
    )
) > "%TARGET_LAYOUT%"
set "status_msg=Layout saved."
call :FullRender
exit /b 0
