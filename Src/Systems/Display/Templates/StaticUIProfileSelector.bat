@echo off
chcp 65001 >nul
rem -----------------------------------------------------------------------------
rem StaticUIProfileSelector.bat
rem Role:
rem   - Read console size from user_config.env.
rem   - Determine RENDER_QUALITY (HIGH/MIDDLE/LOW) based on size.
rem   - Export perfectly aligned static coordinates for menus and slots.
rem -----------------------------------------------------------------------------

rem Ensure PROJECT_ROOT is resolved (4 levels up from Display\Templates)
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)

rem Path Resolution Guard
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

rem Load configuration if it exists to get CONSOLE_COLS and CONSOLE_ROWS
set "USER_CONFIG_PATH=%PROJECT_ROOT%\Config\user_config.env"
if exist "%USER_CONFIG_PATH%" (
    for /f "usebackq delims== tokens=1,2 eol=#" %%i in ("%USER_CONFIG_PATH%") do (
        set "%%i=%%j"
    )
)

rem Set default values if not detected
if not defined CONSOLE_COLS set CONSOLE_COLS=90
if not defined CONSOLE_ROWS set CONSOLE_ROWS=35

rem Auto-detect RENDER_QUALITY if not already set by user
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

rem Export Coordinate Table based on RENDER_QUALITY
if /i "%RENDER_QUALITY%"=="HIGH" (
    rem ==============================================================
    rem HIGH Profile Coordinates (Optimized for 210x58 Monospace)
    rem ==============================================================
    rem Main Menu Options Row Coordinates
    set MENU_POS_ROW_1=24
    set MENU_POS_ROW_2=26
    set MENU_POS_ROW_3=30
    set MENU_POS_ROW_4=32
    set MENU_POS_COL=96

    rem Save Data Selector Title (Pre-rendered in template)
    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    rem Save Data Slots Grid (Mathematical Symmetric Alignment)
    set SLOT_POS_ROW=20
    set SLOT_POS_COL_1=28
    set SLOT_POS_COL_2=96
    set SLOT_POS_COL_3=164
    
) else if /i "%RENDER_QUALITY%"=="MIDDLE" (
    rem ==============================================================
    rem MIDDLE Profile Coordinates (Optimized for 90x35 Standard)
    rem ==============================================================
    rem Main Menu Options Row Coordinates
    set MENU_POS_ROW_1=17
    set MENU_POS_ROW_2=19
    set MENU_POS_ROW_3=23
    set MENU_POS_ROW_4=25
    set MENU_POS_COL=36

    rem Save Data Selector Title (Pre-rendered in template)
    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    rem Save Data Slots Grid (Symmetric Aligned)
    set SLOT_POS_ROW=11
    set SLOT_POS_COL_1=6
    set SLOT_POS_COL_2=34
    set SLOT_POS_COL_3=62

) else (
    rem ==============================================================
    rem LOW Profile Coordinates (Optimized for 80x25 Fallback)
    rem ==============================================================
    rem Main Menu Options Row Coordinates
    set MENU_POS_ROW_1=10
    set MENU_POS_ROW_2=12
    set MENU_POS_ROW_3=16
    set MENU_POS_ROW_4=18
    set MENU_POS_COL=31

    rem Save Data Selector Title (Pre-rendered in template)
    set SLOGO_POS_ROW=0
    set SLOGO_POS_COL=0
    set SSUBTITLE_POS_ROW=0
    set SSUBTITLE_POS_COL=0

    rem Save Data Slots Grid (Symmetric Aligned)
    set SLOT_POS_ROW=7
    set SLOT_POS_COL_1=4
    set SLOT_POS_COL_2=30
    set SLOT_POS_COL_3=56
)

exit /b 0
