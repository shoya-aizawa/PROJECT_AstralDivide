@echo off
chcp 65001 >nul
rem -----------------------------------------------------------------------------
rem StaticUIProfileSelector.bat
rem Role:
rem   - Read console size from user_config.env.
rem   - Determine RENDER_QUALITY (HIGH/MIDDLE/LOW) based on size.
rem   - Export coordinates for MMM, SDS, and Options.
rem -----------------------------------------------------------------------------

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)

for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

set "USER_CONFIG_PATH=%PROJECT_ROOT%\Config\user_config.env"
if exist "%USER_CONFIG_PATH%" (
    for /f "usebackq delims== tokens=1,2 eol=#" %%i in ("%USER_CONFIG_PATH%") do (
        set "%%i=%%j"
    )
)

if not defined CONSOLE_COLS set CONSOLE_COLS=90
if not defined CONSOLE_ROWS set CONSOLE_ROWS=35

set "PRESET_RENDER_QUALITY=%RENDER_QUALITY%"
if not defined SUPPRESS_STATIC_UI_TRACE if exist "%RCSU%" call "%RCSU%" -trace INFO StaticUIProfileSelector "enter cols=%CONSOLE_COLS% rows=%CONSOLE_ROWS% pre_quality=%PRESET_RENDER_QUALITY% force_quality=%FORCE_RENDER_QUALITY% pref_quality=%PREFERRED_RENDER_QUALITY%"

if defined FORCE_RENDER_QUALITY (
    if /i "%FORCE_RENDER_QUALITY%"=="HIGH" set "RENDER_QUALITY=HIGH"
    if /i "%FORCE_RENDER_QUALITY%"=="MIDDLE" set "RENDER_QUALITY=MIDDLE"
    if /i "%FORCE_RENDER_QUALITY%"=="LOW" set "RENDER_QUALITY=LOW"
)

if not defined FORCE_RENDER_QUALITY (
    set "RENDER_QUALITY="
)

if not defined RENDER_QUALITY (
    if defined PREFERRED_RENDER_QUALITY (
        if /i "%PREFERRED_RENDER_QUALITY%"=="HIGH" set "RENDER_QUALITY=HIGH"
        if /i "%PREFERRED_RENDER_QUALITY%"=="MIDDLE" set "RENDER_QUALITY=MIDDLE"
        if /i "%PREFERRED_RENDER_QUALITY%"=="LOW" set "RENDER_QUALITY=LOW"
    )
)

if not defined RENDER_QUALITY (
    if %CONSOLE_COLS% GEQ 200 (
        if %CONSOLE_ROWS% GEQ 55 (
            set "RENDER_QUALITY=HIGH"
        ) else (
            set "RENDER_QUALITY=MIDDLE"
        )
    ) else if %CONSOLE_COLS% GEQ 90 (
        if %CONSOLE_ROWS% GEQ 35 (
            set "RENDER_QUALITY=MIDDLE"
        ) else (
            set "RENDER_QUALITY=LOW"
        )
    ) else (
        set "RENDER_QUALITY=LOW"
    )
)

if /i "%RENDER_QUALITY%"=="HIGH" (
    set UI_CANVAS_COLS=240
    set UI_CANVAS_ROWS=67
    set MMM_TEMPLATE_COLS=239
    set MMM_TEMPLATE_ROWS=70
    set SDS_TEMPLATE_COLS=239
    set SDS_TEMPLATE_ROWS=66
    set MENU_BOX_INNER_WIDTH=20
    set SLOT_BOX_WIDTH=22
    set SLOT_ROW_PITCH=9
    set SLOT_TEXT_WIDTH=16

    set MENU_POS_ROW_1=36
    set MENU_POS_ROW_2=38
    set MENU_POS_ROW_3=42
    set MENU_POS_ROW_4=44
    set MENU_POS_COL=110

    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    set SLOT_POS_ROW=21
    set SLOT_POS_COL_1=38
    set SLOT_POS_COL_2=106
    set SLOT_POS_COL_3=174
    set SDS_DIALOG_ROW=20
    set SDS_DIALOG_COL=92
    set MMM_USE_DYNAMIC=0
    set SDS_USE_DYNAMIC=0
) else if /i "%RENDER_QUALITY%"=="MIDDLE" (
    set UI_CANVAS_COLS=90
    set UI_CANVAS_ROWS=35
    set MMM_TEMPLATE_COLS=89
    set MMM_TEMPLATE_ROWS=35
    set SDS_TEMPLATE_COLS=89
    set SDS_TEMPLATE_ROWS=35
    set MENU_BOX_INNER_WIDTH=20
    set SLOT_BOX_WIDTH=22
    set SLOT_ROW_PITCH=9
    set SLOT_TEXT_WIDTH=16

    set MENU_POS_ROW_1=17
    set MENU_POS_ROW_2=19
    set MENU_POS_ROW_3=23
    set MENU_POS_ROW_4=25
    set MENU_POS_COL=36

    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    set SLOT_POS_ROW=11
    set SLOT_POS_COL_1=6
    set SLOT_POS_COL_2=34
    set SLOT_POS_COL_3=62
    set SDS_DIALOG_ROW=9
    set SDS_DIALOG_COL=23
    set MMM_USE_DYNAMIC=1
    set SDS_USE_DYNAMIC=1
) else (
    set UI_CANVAS_COLS=80
    set UI_CANVAS_ROWS=25
    set MMM_TEMPLATE_COLS=79
    set MMM_TEMPLATE_ROWS=25
    set SDS_TEMPLATE_COLS=79
    set SDS_TEMPLATE_ROWS=25
    set MENU_BOX_INNER_WIDTH=20
    set SLOT_BOX_WIDTH=22
    set SLOT_ROW_PITCH=9
    set SLOT_TEXT_WIDTH=16

    set MENU_POS_ROW_1=10
    set MENU_POS_ROW_2=12
    set MENU_POS_ROW_3=16
    set MENU_POS_ROW_4=18
    set MENU_POS_COL=31

    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    set SLOT_POS_ROW=7
    set SLOT_POS_COL_1=4
    set SLOT_POS_COL_2=30
    set SLOT_POS_COL_3=56
    set SDS_DIALOG_ROW=6
    set SDS_DIALOG_COL=14
    set MMM_USE_DYNAMIC=1
    set SDS_USE_DYNAMIC=0
)

if not defined UI_ANCHOR_LEFT set UI_ANCHOR_LEFT=1
if not defined UI_ANCHOR_TOP set UI_ANCHOR_TOP=1

set "MMM_ANCHOR_COL=1"
set "MMM_ANCHOR_ROW=1"
set "SDS_ANCHOR_COL=1"
set "SDS_ANCHOR_ROW=1"

if defined CONSOLE_COLS (
    if defined MMM_TEMPLATE_COLS (
        if %CONSOLE_COLS% GTR %MMM_TEMPLATE_COLS% (
            set /a "MMM_ANCHOR_COL=((%CONSOLE_COLS% - %MMM_TEMPLATE_COLS%) / 2) + 1"
        )
    )
)
if defined CONSOLE_ROWS (
    if defined MMM_TEMPLATE_ROWS (
        if %CONSOLE_ROWS% GTR %MMM_TEMPLATE_ROWS% (
            set /a "MMM_ANCHOR_ROW=((%CONSOLE_ROWS% - %MMM_TEMPLATE_ROWS%) / 2) + 1"
        )
    )
)
if defined CONSOLE_COLS (
    if defined SDS_TEMPLATE_COLS (
        if %CONSOLE_COLS% GTR %SDS_TEMPLATE_COLS% (
            set /a "SDS_ANCHOR_COL=((%CONSOLE_COLS% - %SDS_TEMPLATE_COLS%) / 2) + 1"
        )
    )
)
if defined CONSOLE_ROWS (
    if defined SDS_TEMPLATE_ROWS (
        if %CONSOLE_ROWS% GTR %SDS_TEMPLATE_ROWS% (
            set /a "SDS_ANCHOR_ROW=((%CONSOLE_ROWS% - %SDS_TEMPLATE_ROWS%) / 2) + 1"
        )
    )
)

if "%MMM_USE_DYNAMIC%"=="1" (
    set "MMM_ANCHOR_COL=1"
    set "MMM_ANCHOR_ROW=1"
    set /a "MMM_FRAME_LEFT=2"
    set /a "MMM_FRAME_TOP=1"
    set /a "MMM_FRAME_RIGHT=%CONSOLE_COLS% - 1"
    set /a "MMM_FRAME_BOTTOM=%CONSOLE_ROWS% - 1"
    set /a "MMM_MENU_BOX_WIDTH=%MENU_BOX_INNER_WIDTH% + 6"
    set /a "MMM_MENU_BOX_HEIGHT=13"
    call set /a "MMM_MENU_BOX_LEFT=((%CONSOLE_COLS% - %%MMM_MENU_BOX_WIDTH%%) / 2 ) + 1"
    call set /a "MMM_MENU_BOX_TOP=((%CONSOLE_ROWS% - %%MMM_MENU_BOX_HEIGHT%%) / 2 ) + 1"
    call set /a "MMM_MENU_BOX_RIGHT=%%MMM_MENU_BOX_LEFT%% + %%MMM_MENU_BOX_WIDTH%% - 1"
    call set /a "MMM_MENU_BOX_BOTTOM=%%MMM_MENU_BOX_TOP%% + %%MMM_MENU_BOX_HEIGHT%% - 1"
    call set /a "MENU_POS_COL=%%MMM_MENU_BOX_LEFT%% + 3"
    call set /a "MENU_POS_ROW_1=%%MMM_MENU_BOX_TOP%% + 2"
    call set /a "MENU_POS_ROW_2=%%MMM_MENU_BOX_TOP%% + 4"
    call set /a "MENU_POS_ROW_3=%%MMM_MENU_BOX_TOP%% + 8"
    call set /a "MENU_POS_ROW_4=%%MMM_MENU_BOX_TOP%% + 10"
    call set /a "MMM_MENU_DIVIDER_ROW=%%MMM_MENU_BOX_TOP%% + 6"
    call set /a "MMM_MENU_DIVIDER_LEFT=%%MMM_MENU_BOX_LEFT%% + 2"
    call set /a "MMM_MENU_DIVIDER_RIGHT=%%MMM_MENU_BOX_RIGHT%% - 2"
    set /a "MMM_HELP_BOX_WIDTH=28"
    set /a "MMM_HELP_BOX_HEIGHT=3"
    call set /a "MMM_HELP_BOX_LEFT=((%CONSOLE_COLS% - %%MMM_HELP_BOX_WIDTH%%) / 2 ) + 1"
    call set /a "MMM_HELP_BOX_TOP=%%MMM_MENU_BOX_BOTTOM%% + 4"
    call set /a "MMM_HELP_BOX_RIGHT=%%MMM_HELP_BOX_LEFT%% + %%MMM_HELP_BOX_WIDTH%% - 1"
    call set /a "MMM_HELP_BOX_BOTTOM=%%MMM_HELP_BOX_TOP%% + %%MMM_HELP_BOX_HEIGHT%% - 1"
    call set /a "MMM_HELP_TEXT_ROW=%%MMM_HELP_BOX_TOP%% + 1"
    call set /a "MMM_HELP_TEXT_COL=%%MMM_HELP_BOX_LEFT%% + 2"
    set /a "MMM_TITLE_ROW=8"
    if /i "%RENDER_QUALITY%"=="LOW" set /a "MMM_TITLE_ROW=5"
    call set /a "MMM_SUBTITLE_ROW_1=%%MMM_TITLE_ROW%% + 3"
    call set /a "MMM_SUBTITLE_ROW_2=%%MMM_TITLE_ROW%% + 4"
    call set /a "MMM_SUBTITLE_ROW_3=%%MMM_TITLE_ROW%% + 5"
    set /a "MMM_FOOTER_ROW_1=%CONSOLE_ROWS% - 3"
    set /a "MMM_FOOTER_ROW_2=%CONSOLE_ROWS% - 2"
    set /a "MMM_FOOTER_LEFT_COL=3"
    call set /a "MMM_FOOTER_RIGHT_COL=%CONSOLE_COLS%-29"
    call :ClampMin MMM_FOOTER_RIGHT_COL 2
)

if "%SDS_USE_DYNAMIC%"=="1" (
    set "SDS_ANCHOR_COL=1"
    set "SDS_ANCHOR_ROW=1"
    set /a "SDS_FRAME_LEFT=2"
    set /a "SDS_FRAME_TOP=1"
    set /a "SDS_FRAME_RIGHT=%CONSOLE_COLS% - 1"
    set /a "SDS_FRAME_BOTTOM=%CONSOLE_ROWS% - 1"
    set /a "SDS_TITLE_ROW_1=2"
    set /a "SDS_TITLE_ROW_2=4"
    set /a "SDS_HELP_TEXT_ROW=%CONSOLE_ROWS% - 5"
    set /a "SDS_HELP_BOX_WIDTH=28"
    set /a "SDS_HELP_BOX_HEIGHT=3"
    set "SDS_SHOW_HELP_BOX=1"
    if %CONSOLE_ROWS% LSS 40 (
        set "SDS_SHOW_HELP_BOX=0"
        set /a "SDS_SLOT_POS_ROW=8"
    ) else (
        set /a "SDS_SLOT_POS_ROW=10"
    )
    call set /a "SDS_HELP_BOX_LEFT=((%CONSOLE_COLS% - %%SDS_HELP_BOX_WIDTH%%) / 2) + 1"
    set /a "SDS_HELP_BOX_TOP=%CONSOLE_ROWS% - 6"
    call set /a "SDS_HELP_BOX_RIGHT=%%SDS_HELP_BOX_LEFT%% + %%SDS_HELP_BOX_WIDTH%% - 1"
    call set /a "SDS_HELP_BOX_BOTTOM=%%SDS_HELP_BOX_TOP%% + %%SDS_HELP_BOX_HEIGHT%% - 1"
    set /a "SLOT_BOX_WIDTH=22"
    set /a "SDS_SLOT_BOX_HEIGHT=6"
    set /a "SLOT_ROW_PITCH=7"
    set /a "SLOT_TEXT_WIDTH=16"
    set /a "SDS_SLOT_GAP=4"
    if %CONSOLE_COLS% GEQ 140 set /a "SDS_SLOT_GAP=16"
    if %CONSOLE_COLS% GEQ 110 if %CONSOLE_COLS% LSS 140 set /a "SDS_SLOT_GAP=10"
    call set /a "SDS_GRID_WIDTH=(3 * %SLOT_BOX_WIDTH%) + (2 * %%SDS_SLOT_GAP%%)"
    call set /a "SDS_GRID_LEFT=((%CONSOLE_COLS% - %%SDS_GRID_WIDTH%%) / 2) + 1"
    call set /a "SLOT_POS_ROW=%%SDS_SLOT_POS_ROW%%"
    call set /a "SLOT_POS_COL_1=%%SDS_GRID_LEFT%%"
    call set /a "SLOT_POS_COL_2=%%SDS_GRID_LEFT%% + %SLOT_BOX_WIDTH% + %%SDS_SLOT_GAP%%"
    call set /a "SLOT_POS_COL_3=%%SDS_GRID_LEFT%% + (2 * (%SLOT_BOX_WIDTH% + %%SDS_SLOT_GAP%%))"
    call set /a "SDS_DIALOG_ROW=%SDS_SLOT_POS_ROW%-2"
    call :ClampMin SDS_DIALOG_ROW 6
    call set /a "SDS_DIALOG_COL=((%CONSOLE_COLS% - 30) / 2) + 1"
    set "SDS_SHOW_FOOTER=1"
    if %CONSOLE_ROWS% LSS 40 set "SDS_SHOW_FOOTER=0"
    set /a "SDS_FOOTER_ROW_1=%CONSOLE_ROWS% - 3"
    set /a "SDS_FOOTER_ROW_2=%CONSOLE_ROWS% - 2"
    set /a "SDS_FOOTER_LEFT_COL=3"
    call set /a "SDS_FOOTER_RIGHT_COL=%CONSOLE_COLS%-29"
    call :ClampMin SDS_FOOTER_RIGHT_COL 2
)

set "OPT_USE_DYNAMIC=1"
if "%OPT_USE_DYNAMIC%"=="1" (
    set "OPT_ANCHOR_COL=1"
    set "OPT_ANCHOR_ROW=1"
    set /a "OPT_FRAME_LEFT=2"
    set /a "OPT_FRAME_TOP=1"
    set /a "OPT_FRAME_RIGHT=%CONSOLE_COLS% - 1"
    set /a "OPT_FRAME_BOTTOM=%CONSOLE_ROWS% - 1"
    set /a "OPT_TITLE_ROW=4"
    if /i "%RENDER_QUALITY%"=="LOW" (
        set /a "OPT_TITLE_ROW=2"
    ) else if /i "%RENDER_QUALITY%"=="HIGH" (
        set /a "OPT_TITLE_ROW=6"
    )
    set /a "OPT_SUBTITLE_ROW=OPT_TITLE_ROW + 1"
    set /a "OPT_LIST_WIDTH=46"
    if %CONSOLE_COLS% GEQ 120 set /a "OPT_LIST_WIDTH=62"
    if %CONSOLE_COLS% LSS 85 set /a "OPT_LIST_WIDTH=38"
    call set /a "OPT_LIST_LEFT=((%CONSOLE_COLS% - %%OPT_LIST_WIDTH%%) / 2) + 1"
    set /a "OPT_LIST_TOP=OPT_TITLE_ROW + 4"
    set /a "OPT_HELP_BOX_WIDTH=36"
    if %CONSOLE_COLS% GEQ 120 set /a "OPT_HELP_BOX_WIDTH=50"
    set /a "OPT_HELP_BOX_HEIGHT=3"
    call set /a "OPT_HELP_BOX_LEFT=((%CONSOLE_COLS% - %%OPT_HELP_BOX_WIDTH%%) / 2) + 1"
    set /a "OPT_HELP_BOX_TOP=%CONSOLE_ROWS% - 6"
    if /i "%RENDER_QUALITY%"=="LOW" set /a "OPT_HELP_BOX_TOP=%CONSOLE_ROWS% - 5"
    call set /a "OPT_HELP_BOX_RIGHT=%%OPT_HELP_BOX_LEFT%% + %%OPT_HELP_BOX_WIDTH%% - 1"
    call set /a "OPT_HELP_BOX_BOTTOM=%%OPT_HELP_BOX_TOP%% + %%OPT_HELP_BOX_HEIGHT%% - 1"
    call set /a "OPT_HELP_TEXT_ROW=%%OPT_HELP_BOX_TOP%% + 1"
    call set /a "OPT_HELP_TEXT_COL=%%OPT_HELP_BOX_LEFT%% + 2"
    set /a "OPT_FOOTER_ROW_1=%CONSOLE_ROWS% - 3"
    set /a "OPT_FOOTER_ROW_2=%CONSOLE_ROWS% - 2"
    set "OPT_SHOW_FOOTER=1"
    if %CONSOLE_ROWS% LSS 20 set "OPT_SHOW_FOOTER=0"
    set /a "OPT_FOOTER_LEFT_COL=3"
    call set /a "OPT_FOOTER_RIGHT_COL=%CONSOLE_COLS%-29"
    call :ClampMin OPT_FOOTER_RIGHT_COL 2
)

if not defined SUPPRESS_STATIC_UI_TRACE if exist "%RCSU%" call "%RCSU%" -trace INFO StaticUIProfileSelector "exit quality=%RENDER_QUALITY% dynamic=%MMM_USE_DYNAMIC%/%SDS_USE_DYNAMIC% mmm_anchor=%MMM_ANCHOR_COL%,%MMM_ANCHOR_ROW% sds_anchor=%SDS_ANCHOR_COL%,%SDS_ANCHOR_ROW% menu_pos=%MENU_POS_COL%,%MENU_POS_ROW_1%/%MENU_POS_ROW_2%/%MENU_POS_ROW_3%/%MENU_POS_ROW_4%"
if "%MMM_USE_DYNAMIC%"=="1" (
    if not defined SUPPRESS_STATIC_UI_TRACE if exist "%RCSU%" call "%RCSU%" -trace INFO StaticUIProfileSelector "dynamic_mmm frame=%MMM_FRAME_LEFT%,%MMM_FRAME_TOP%-%MMM_FRAME_RIGHT%,%MMM_FRAME_BOTTOM% menu_box=%MMM_MENU_BOX_LEFT%,%MMM_MENU_BOX_TOP%-%MMM_MENU_BOX_RIGHT%,%MMM_MENU_BOX_BOTTOM% help_box=%MMM_HELP_BOX_LEFT%,%MMM_HELP_BOX_TOP%-%MMM_HELP_BOX_RIGHT%,%MMM_HELP_BOX_BOTTOM% footer=%MMM_FOOTER_LEFT_COL%/%MMM_FOOTER_RIGHT_COL%@%MMM_FOOTER_ROW_1%,%MMM_FOOTER_ROW_2%"
)
if "%SDS_USE_DYNAMIC%"=="1" (
    if not defined SUPPRESS_STATIC_UI_TRACE if exist "%RCSU%" call "%RCSU%" -trace INFO StaticUIProfileSelector "dynamic_sds frame=%SDS_FRAME_LEFT%,%SDS_FRAME_TOP%-%SDS_FRAME_RIGHT%,%SDS_FRAME_BOTTOM% grid_left=%SDS_GRID_LEFT% gap=%SDS_SLOT_GAP% slot_row=%SLOT_POS_ROW% dialog=%SDS_DIALOG_COL%,%SDS_DIALOG_ROW% footer=%SDS_FOOTER_LEFT_COL%/%SDS_FOOTER_RIGHT_COL%@%SDS_FOOTER_ROW_1%,%SDS_FOOTER_ROW_2%"
)
if not defined SUPPRESS_STATIC_UI_TRACE if exist "%RCSU%" call "%RCSU%" -trace INFO StaticUIProfileSelector "dynamic_opt frame=%OPT_FRAME_LEFT%,%OPT_FRAME_TOP%-%OPT_FRAME_RIGHT%,%OPT_FRAME_BOTTOM% list=%OPT_LIST_LEFT%,%OPT_LIST_TOP% width=%OPT_LIST_WIDTH% help=%OPT_HELP_BOX_LEFT%,%OPT_HELP_BOX_TOP%-%OPT_HELP_BOX_RIGHT%,%OPT_HELP_BOX_BOTTOM% footer=%OPT_FOOTER_LEFT_COL%/%OPT_FOOTER_RIGHT_COL%@%OPT_FOOTER_ROW_1%,%OPT_FOOTER_ROW_2%"

exit /b 0

:ClampMin
setlocal EnableDelayedExpansion
set "var_name=%~1"
set /a "var_value=!%~1!"
set /a "min_value=%~2"
if !var_value! LSS !min_value! set /a "var_value=min_value"
endlocal & set "%~1=%var_value%"
exit /b 0
