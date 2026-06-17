@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: Resolve project root path
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..") do set "PROJECT_ROOT=%%~fA"
)
set "cmdwiz_path=%PROJECT_ROOT%\Tools\cmdwiz.exe"
if not exist "%cmdwiz_path%" (
    echo [ERROR] cmdwiz.exe not found at "%cmdwiz_path%".
    echo Please ensure this script is run within the PROJECT_AstralDivide workspace.
    pause
    exit /b 1
)

:: Initialize screen dimensions (80 columns, 25 rows)
mode con cols=80 lines=25

:: Obtain ANSI Escape character
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"

:: Define camera viewport size
set /a V_WIDTH=60
set /a V_HEIGHT=15
set /a V_WIDTH_MINUS_1=V_WIDTH - 1
set /a V_HEIGHT_MINUS_1=V_HEIGHT - 1

:: Set active map state (Initial map is ElysionTown)
call :LoadMap ElysionTown 15 10

:MainLoop
    :: Calculate camera top-left offset centered around player (PX, PY)
    set /a "cam_x=PX - (V_WIDTH / 2)"
    set /a "cam_y=PY - (V_HEIGHT / 2)"
    
    :: Clamp camera offsets to map boundaries
    if !cam_x! lss 0 set /a cam_x=0
    if !cam_y! lss 0 set /a cam_y=0
    
    set /a "max_cam_x=MAP_WIDTH - V_WIDTH"
    set /a "max_cam_y=MAP_HEIGHT - V_HEIGHT"
    if !cam_x! gtr !max_cam_x! set /a cam_x=!max_cam_x!
    if !cam_y! gtr !max_cam_y! set /a cam_y=!max_cam_y!

    :: Draw frame and background viewport
    if "%REDRAW_ALL%"=="1" (
        echo !esc![1;1H Astral Divide - Map Exploration Demo
        echo !esc![2;1H================================================================================
        set /a "bottom_y=V_HEIGHT + 4"
        set /a "ctrl_y=bottom_y + 1"
        set /a "stat_y=bottom_y + 2"
        echo !esc![!ctrl_y!;1HControls: WASD / Arrows = Move ^| F = Interact ^| Q = Quit
        set "REDRAW_ALL=0"
    )
    
    :: Render viewport rows
    echo !esc![3;4H+------------------------------------------------------------+
    for /l %%y in (0,1,%V_HEIGHT_MINUS_1%) do (
        set /a "map_y=cam_y + %%y + 1"
        for %%g in (!map_y!) do set "row_data=!MAP_ROW_%%g!"
        for /f "tokens=1,2" %%A in ("!cam_x! !V_WIDTH!") do (
            set "visible_part=!row_data:~%%A,%%B!"
        )
        set /a "print_y=%%y + 4"
        echo !esc![!print_y!;4H^|!visible_part!^|
    )
    set /a "bottom_y=V_HEIGHT + 4"
    echo !esc![!bottom_y!;4H+------------------------------------------------------------+

    :: Render events within camera viewport bounds
    for /l %%i in (1,1,%event_count%) do (
        set /a "ex=EVENT_X_%%i"
        set /a "ey=EVENT_Y_%%i"
        set "ev_type=!EVENT_TYPE_%%i!"
        set "ev_param=!EVENT_PARAM_%%i!"
        
        :: Check if event is within camera bounds
        set /a "rel_ex=ex - cam_x"
        set /a "rel_ey=ey - cam_y"
        if !rel_ex! geq 0 if !rel_ex! lss %V_WIDTH% if !rel_ey! geq 0 if !rel_ey! lss %V_HEIGHT% (
            set /a "scr_x=rel_ex + 5"
            set /a "scr_y=rel_ey + 3"
            if "!ev_type!"=="SHOP" (
                echo !esc![!scr_y!;!scr_x!H!esc![93mS!esc![0m
            ) else if "!ev_type!"=="NPC" (
                echo !esc![!scr_y!;!scr_x!H!esc![92mN!esc![0m
            ) else if "!ev_type!"=="TRANSFER" (
                echo !esc![!scr_y!;!scr_x!H!esc![96mT!esc![0m
            )
        )
    )

    :: Render player icon
    set /a "rel_px=PX - cam_x + 5"
    set /a "rel_py=PY - cam_y + 3"
    echo !esc![!rel_py!;!rel_px!H!esc![91m@!esc![0m

    :: Check if player is standing on any event
    set "ACTIVE_EVENT_IDX="
    for /l %%i in (1,1,%event_count%) do (
        if "!EVENT_X_%%i!"=="%PX%" (
            if "!EVENT_Y_%%i!"=="%PY%" (
                set "ACTIVE_EVENT_IDX=%%i"
            )
        )
    )

    :: Update status bar (coords and active prompt)
    set /a "stat_y=V_HEIGHT + 6"
    set /a "clear_y=V_HEIGHT + 7"
    set /a "dbg_y=V_HEIGHT + 8"
    echo !esc![!stat_y!;1H!esc![0KCoordinates: Global (X=%PX%, Y=%PY%) ^| Camera (X=!cam_x!, Y=!cam_y!)
    echo !esc![!dbg_y!;1H!esc![0KDebug: cell_char='!cell_char!' tx=!tx! ty=!ty!
    if defined ACTIVE_EVENT_IDX (
        set "ev_type=!EVENT_TYPE_%ACTIVE_EVENT_IDX%!"
        set "ev_param=!EVENT_PARAM_%ACTIVE_EVENT_IDX%!"
        if "!ev_type!"=="TRANSFER" (
            :: Trigger area transfer immediately
            for /f "tokens=1-3 delims=," %%a in ("!ev_param!") do (
                set "target_map=%%a"
                set "target_x=%%b"
                set "target_y=%%c"
            )
            call :LoadMap !target_map! !target_x! !target_y!
            goto :MainLoop
        ) else (
            echo !esc![!clear_y!;1H!esc![0K!esc![93m[F] Interact with !ev_param! ^(!ev_type!^)!esc![0m
        )
    ) else (
        echo !esc![!clear_y!;1H!esc![0K
    )

    :: Scan keyboard input with delay (controls FPS)
    call :GetInput
    if "%choice%"=="1" call :TryMove 0 -1
    if "%choice%"=="2" call :TryMove 0 1
    if "%choice%"=="3" call :TryMove -1 0
    if "%choice%"=="4" call :TryMove 1 0
    if "%choice%"=="5" (
        if defined ACTIVE_EVENT_IDX (
            call :ExecuteInteraction !ACTIVE_EVENT_IDX!
        )
    )
    if "%choice%"=="6" goto :ExitDemo

    goto :MainLoop

:ExitDemo
    cls
    echo Thank you for playing the Astral Divide Map System Demo!
    exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: Resolve Keyboard Input
:: -----------------------------------------------------------------------------
:GetInput
    set "choice=0"
    "%cmdwiz_path%" getch noWait >nul 2>&1
    set "scan_code=%errorlevel%"
    if "%scan_code%"=="0" (
        "%cmdwiz_path%" delay 30 >nul 2>&1
        exit /b 0
    )
    :: W / w / Up Arrow
    if "%scan_code%"=="87" set "choice=1"
    if "%scan_code%"=="119" set "choice=1"
    if "%scan_code%"=="72" set "choice=1"
    :: S / s / Down Arrow
    if "%scan_code%"=="83" set "choice=2"
    if "%scan_code%"=="115" set "choice=2"
    if "%scan_code%"=="80" set "choice=2"
    :: A / a / Left Arrow
    if "%scan_code%"=="65" set "choice=3"
    if "%scan_code%"=="97" set "choice=3"
    if "%scan_code%"=="75" set "choice=3"
    :: D / d / Right Arrow
    if "%scan_code%"=="68" set "choice=4"
    if "%scan_code%"=="100" set "choice=4"
    if "%scan_code%"=="77" set "choice=4"
    :: F / f (Interact)
    if "%scan_code%"=="70" set "choice=5"
    if "%scan_code%"=="102" set "choice=5"
    :: Q / q / ESC (Quit)
    if "%scan_code%"=="81" set "choice=6"
    if "%scan_code%"=="113" set "choice=6"
    if "%scan_code%"=="27" set "choice=6"
    exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: Check Collision & Move Player
:: -----------------------------------------------------------------------------
:TryMove
    set /a "dx=%1"
    set /a "dy=%2"
    set /a "tx=PX + dx"
    set /a "ty=PY + dy"
    
    :: Bounds check
    if !tx! lss 0 exit /b 0
    if !ty! lss 1 exit /b 0
    if !tx! geq !MAP_WIDTH! exit /b 0
    if !ty! gtr !MAP_HEIGHT! exit /b 0

    :: Collision character check
    for %%g in (!ty!) do set "target_row=!MAP_ROW_%%g!"
    for %%A in (!tx!) do set "cell_char=!target_row:~%%A,1!"
    
    if "!cell_char!"=="#" exit /b 0
    if "!cell_char!"=="~" exit /b 0
    if "!cell_char!"=="T" exit /b 0
    
    :: Apply movement
    set /a PX=tx
    set /a PY=ty
    exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: Load Map and Events into RAM
:: -----------------------------------------------------------------------------
:LoadMap
    set "map_name=%~1"
    set /a PX=%~2
    set /a PY=%~3

    :: Loading transition screen
    cls
    echo !esc![10;25H+-------------------------------+
    echo !esc![11;25H^|   Loading Area: !map_name!    ^|
    echo !esc![12;25H^|   Please wait...              ^|
    echo !esc![13;25H+-------------------------------+
    "%cmdwiz_path%" delay 500

    :: Clear previous map cache
    for /l %%i in (1,1,150) do set "MAP_ROW_%%i="
    :: Clear previous events
    for /l %%i in (1,1,50) do (
        set "EVENT_X_%%i="
        set "EVENT_Y_%%i="
        set "EVENT_TYPE_%%i="
        set "EVENT_PARAM_%%i="
    )

    :: Configure dimensions
    if /i "%map_name%"=="ElysionTown" (
        set /a MAP_WIDTH=100
        set /a MAP_HEIGHT=30
    )
    if /i "%map_name%"=="CastleGate" (
        set /a MAP_WIDTH=60
        set /a MAP_HEIGHT=20
    )

    :: Load map text rows
    set "map_file=%~dp0DemoMap_!map_name!.map"
    set /a row_count=0
    for /f "usebackq delims= eol=" %%L in ("!map_file!") do (
        set /a row_count+=1
        set "MAP_ROW_!row_count!=%%L"
    )

    :: Load events
    set "event_file=%~dp0DemoMap_!map_name!.event"
    set /a event_count=0
    for /f "usebackq tokens=1-4 delims=," %%a in ("!event_file!") do (
        set /a event_count+=1
        set "EVENT_X_!event_count!=%%a"
        set "EVENT_Y_!event_count!=%%b"
        set "EVENT_TYPE_!event_count!=%%c"
        set "EVENT_PARAM_!event_count!=%%d"
    )

    call :DrawCompleteMap
    exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: Force Complete Frame Redraw
:: -----------------------------------------------------------------------------
:DrawCompleteMap
    cls
    set "REDRAW_ALL=1"
    exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: Execute Interaction (Shop or NPC dialogue)
:: -----------------------------------------------------------------------------
:ExecuteInteraction
    set "idx=%~1"
    set "ev_type=!EVENT_TYPE_%idx%!"
    set "ev_param=!EVENT_PARAM_%idx%!"

    if "!ev_type!"=="SHOP" (
        call :ShowShopMenu "!ev_param!"
    ) else if "!ev_type!"=="NPC" (
        call :ShowNPCDialog "!ev_param!"
    )
    exit /b 0

:ShowShopMenu
    set "shop_name=%~1"
    echo !esc![8;15H+--------------------------------------------------+
    echo !esc![9;15H^|               !shop_name! [SHOP]                  ^|
    echo !esc![10;15H^|                                                  ^|
    echo !esc![11;15H^|  1. Buy Healing Potion   (10 Gold)               ^|
    echo !esc![12;15H^|  2. Buy Steel Sword      (50 Gold)               ^|
    echo !esc![13;15H^|  3. Exit Shop                                    ^|
    echo !esc![14;15H+--------------------------------------------------+
    
:ShopInputLoop
    "%cmdwiz_path%" getch noWait >nul 2>&1
    set "sc=%errorlevel%"
    if "%sc%"=="49" (
        echo !esc![16;15H!esc![92mBought Healing Potion! ^(10 Gold deducted^)!esc![0m
        "%cmdwiz_path%" delay 1000
        goto :ShopEnd
    )
    if "%sc%"=="50" (
        echo !esc![16;15H!esc![92mBought Steel Sword! ^(50 Gold deducted^)!esc![0m
        "%cmdwiz_path%" delay 1000
        goto :ShopEnd
    )
    if "%sc%"=="51" (
        goto :ShopEnd
    )
    if "%sc%"=="27" goto :ShopEnd
    "%cmdwiz_path%" delay 30
    goto :ShopInputLoop

:ShopEnd
    call :DrawCompleteMap
    exit /b 0

:ShowNPCDialog
    set "npc_name=%~1"
    set "dialogue_text=Welcome to Elysion Town, traveler."
    if "%npc_name%"=="Guard_Aizawa" set "dialogue_text=Good morning! We are preparing the festival for tomorrow."
    if "%npc_name%"=="Captain_Harinezumi" set "dialogue_text=Halt! Castle is secure. Please watch your steps."

    echo !esc![10;15H+--------------------------------------------------+
    echo !esc![11;15H^| !npc_name!:                                     ^|
    echo !esc![12;15H^|   "!dialogue_text!"                              ^|
    echo !esc![13;15H^|                                                  ^|
    echo !esc![14;15H^|              [ Press F to Continue ]             ^|
    echo !esc![15;15H+--------------------------------------------------+

:NPCInputLoop
    "%cmdwiz_path%" getch noWait >nul 2>&1
    set "sc=%errorlevel%"
    if "%sc%"=="70" goto :NPCEnd
    if "%sc%"=="102" goto :NPCEnd
    if "%sc%"=="27" goto :NPCEnd
    "%cmdwiz_path%" delay 30
    goto :NPCInputLoop

:NPCEnd
    call :DrawCompleteMap
    exit /b 0
