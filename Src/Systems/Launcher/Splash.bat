@echo off 
setlocal EnableExtensions EnableDelayedExpansion
::------------------------------------------------------------------------------
:: Splash.bat
:: HedgeHogSoft Splash Screen Sequence with Native System Loading Synchronization.
::
:: Arguments:
::   %1 - PROJECT_ROOT directory path.
::------------------------------------------------------------------------------



set "PROJECT_ROOT=%~1"
if "%PROJECT_ROOT%"=="" (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)



:: Define paths
set "BGM_PLAYER=%PROJECT_ROOT%\Src\Systems\Audio\BgmPlayer.bat"
set "SPLASH_BGM=%PROJECT_ROOT%\Assets\Sounds\孤独な少女.mp3"
set "INITIALIZER=%PROJECT_ROOT%\Src\Systems\Launcher\Splash_Initializer.bat"

:: Load user config if exists to apply saved font
set "USER_CONFIG_FILE=%PROJECT_ROOT%\Config\user_config.env"
if exist "%USER_CONFIG_FILE%" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%USER_CONFIG_FILE%") do (
        set "%%A=%%B"
    )
)

:: Apply user-configured font automatically at startup if it exists and not blocked
if defined CONSOLE_FONT (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        if exist "%PROJECT_ROOT%\Tools\cmdwiz.exe" (
            call "%PROJECT_ROOT%\Tools\cmdwiz.exe" setfont "%PROJECT_ROOT%\Tools\%CONSOLE_FONT%.fnt" >nul 2>&1
        )
    )
)

:: Get ESC character
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"

:: Hide the blinking cursor for a cleaner look
echo !esc![?25l

:: Start test BGM playback using native PresentationCore player
if exist "%SPLASH_BGM%" (
    call "%BGM_PLAYER%" PLAY "%SPLASH_BGM%" 100 0 1
)

:: Set standard window size to ensure layout is centered
mode con cols=80 lines=25
echo !esc![2J

:: Define colors (Using 256-color ANSI codes)
set "C_BORDER=!esc![38;5;239m"
set "C_TEXT=!esc![38;5;250m"
set "C_LOAD=!esc![38;5;82m"
set "C_RESET=!esc![0m"

:: Define background colors
set "C_HILL=!esc![38;5;235m"
set "C_SKY=!esc![38;5;18m"
set "C_WINDOW=!esc![38;5;220m"
set "C_MOON=!esc![38;5;222m"
set "C_STAR_BRIGHT=!esc![38;5;255m"

:: Define star brightness levels for dynamic twinkling (deep blue to bright cyan)
set "sc[0]=18"
set "sc[1]=19"
set "sc[2]=20"
set "sc[3]=21"
set "sc[4]=27"
set "sc[5]=33"
set "sc[6]=39"
set "sc[7]=45"
set "sc[8]=51"

:: Define background panning state variables
set "pan_state=0"
set "camera_y=14"
set "pan_timer=0"

:: Define virtual background lines (38 rows, exactly 78 columns when padded)
set "bg[1]=   ·             .            +                 .                  ·       "
set "bg[2]=       +                .             ·                  .             +   "
set "bg[3]=  .                      ✦              ·              +              .         "
set "bg[4]=      ·                                         ☾                  ·                 + "
set "bg[5]=   +                +                 .              .                     "
set "bg[6]=        .                    ·                 +               ·       "
set "bg[7]=  ·                .               .              ·                       "
set "bg[8]=       +                .             ·                  .             +   "
set "bg[9]=   .             ·            +                 .                  ·       "
set "bg[10]=       ·                .             +                  .             ·   "
set "bg[11]=  +         .                  ✦              +              .             "
set "bg[12]=       .                +             .                  ·             +   "
set "bg[13]=   ·             .            +                 .                  ·       "
set "bg[14]=       +                .             ·                  .             +   "
set "bg[15]=  .         ·                  .              +              .         ·   "
set "bg[16]=      ·              .              ·                 +             .     "
set "bg[17]=   +          +                 .              .          ·                 "
set "bg[18]=        .            ·                 +               ·            .      "
set "bg[19]=  ·             .               .              ·                 +         "
set "bg[20]=       +                ·                  .             +              · "
set "bg[21]=   .             +                 .                  ·             .      "
set "bg[22]=       ·                .             +                  .             ·   "
set "bg[23]=  +         .                  ·              +              .             "
set "bg[24]=       .                +             .                  ·             +   "
set "bg[25]=                                                                              "
set "bg[26]=                                                                              "
set "bg[27]=                                                                   .          "
set "bg[28]=                                                                  / \         "
set "bg[29]=                                                                 /   \        "
set "bg[30]=                                                         .       |   |        "
set "bg[31]=                                                        / \     /_____\       "
set "bg[32]=                                                       /   \    |  [] |       "
set "bg[33]=               .                                      /_____\   |_____|       "
set "bg[34]=        .     / \                                     |  [] |  /       \      "
set "bg[35]=       / \   /   \                                    |_____| /         \     "
set "bg[36]=______/   \_/_____\___________________________________|_____|/___________\____"
set "bg[37]=______________________________________________________________________________"
set "bg[38]=______________________________________________________________________________"

:: ---------------------------------------------------------
:: 1. Draw a static border GUI frame
:: ---------------------------------------------------------
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

:: ---------------------------------------------------------
:: 2. Prepare Logo Animation Data
:: ---------------------------------------------------------
:: Split the ASCII art into 6 segments: H1, edge, H2, og, S, oft
set "A1_1=  _   _ "&set "A1_2=         _            "&set "A1_3=_   _ "&set "A1_4=              "&set "A1_5=____    "&set "A1_6=     __ _   "
set "A2_1= | | | |"&set "A2_2= ___  __| | __ _  ___"&set "A2_3=| | | |"&set "A2_4= ___   __ _  "&set "A2_5=/ ___|  "&set "A2_6=___  / _| |_ "
set "A3_1= | |_| |"&set "A3_2=/ _ \/ _` |/ _` |/ _ \ "&set "A3_3=|_| |"&set "A3_4=/ _ \ / _` | "&set "A3_5=\___ \ "&set "A3_6=/ _ \| |_| __|"
set "A4_1= |  _  |"&set "A4_2=  __/ (_| | (_| |  __/"&set "A4_3=  _  |"&set "A4_4= (_) | (_| | "&set "A4_5= ___) |"&set "A4_6= (_) |  _| |_ "
set "A5_1= |_| |_|"&set "A5_2=\___|\__,_|\__, |\___|"&set "A5_3=_| |_|"&set "A5_4=\___/ \__, | "&set "A5_5=|____/ "&set "A5_6=\___/|_|  \__|"
set "A6_1=        "&set "A6_2=           |___/      "&set "A6_3=      "&set "A6_4=      |___/ "&set "A6_5=       "&set "A6_6=              "

:: Define fade palette (0=Darkest Grey, 8=Brightest Cyan)
set "pal[0]=233"
set "pal[1]=236"
set "pal[2]=239"
set "pal[3]=244"
set "pal[4]=24"
set "pal[5]=31"
set "pal[6]=38"
set "pal[7]=45"
set "pal[8]=51"
set "MAX_PAL=8"

set "PRESENTS_TEXT=P R E S E N T S"

:: ---------------------------------------------------------
:: 3. Background Task & IPC (Inter-Process Communication)
:: ---------------------------------------------------------

:: [1] Return Code System (RCS) Initialization
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not exist "%RCSU%" (
    exit /b 90610001
)
call "%PROJECT_ROOT%\Src\Systems\Debug\RCS_Const.bat"
if not "%errorlevel%"=="0" (
    exit /b 90610002
)

set "SPLASH_RUNNING=1"

:: Clean up any stale temporary files from previous runs to ensure clean state
if exist "%TEMP%\splash_ui_req.tmp" del "%TEMP%\splash_ui_req.tmp" >nul 2>&1
if exist "%TEMP%\ad_boot_diag_result.env" del "%TEMP%\ad_boot_diag_result.env" >nul 2>&1
if exist "%TEMP%\splash_progress.tmp" del "%TEMP%\splash_progress.tmp" >nul 2>&1

:: Create a temporary file for progress tracking
set "PROGRESS_FILE=%TEMP%\splash_progress.tmp"
echo 0 > "!PROGRESS_FILE!"

:: Start the background initialization process
start "" /b cmd /c call "%INITIALIZER%" "!PROGRESS_FILE!" "%PROJECT_ROOT%"

set "pct=0"
set "actual_pct=0"
set "frame=0"
set "state=0"
set "keep_frame=0"
set "cmdwiz_path=%PROJECT_ROOT%\Tools\cmdwiz.exe"

:: Initialize shooting star states
for /L %%i in (1,1,3) do (
    set "star%%i_active=0"
    set "star%%i_lx="
    set "star%%i_ly="
)

:ProgressLoop
set /a frame+=1

:: -- Camera Panning Logic (Pans up once progress reaches 50%, then stays forever) --
set /a pan_timer+=1
if !pan_state! == 0 (
    if !pct! GEQ 50 (
        set "pan_state=1"
    )
)
if !pan_state! == 1 (
    set /a "step=pan_timer %% 2"
    if !step! == 0 (
        set /a camera_y-=1
        if !camera_y! LEQ 0 (
            set "camera_y=0"
            set "pan_state=2"
        )
    )
)

:: -- Dynamic Twinkling Oscillators (Triangle waves with staggered frequencies and phases) --
set /a "t1 = (frame / 3) %% 16"
if !t1! GTR 8 ( set /a "b1 = 16 - t1" ) else ( set /a "b1 = t1" )

set /a "t2 = ((frame + 5) / 4) %% 16"
if !t2! GTR 8 ( set /a "b2 = 16 - t2" ) else ( set /a "b2 = t2" )

set /a "t3 = ((frame + 10) / 2) %% 16"
if !t3! GTR 8 ( set /a "b3 = 16 - t3" ) else ( set /a "b3 = t3" )

for %%b in (!b1!) do set "C_S1=!esc![38;5;!sc[%%b]!m"
for %%b in (!b2!) do set "C_S2=!esc![38;5;!sc[%%b]!m"
for %%b in (!b3!) do set "C_S3=!esc![38;5;!sc[%%b]!m"

:: -- Initialize Frame Buffer --
set "FRAME_RENDER="

:: -- Draw Background to Frame Buffer --
for /L %%y in (2,1,23) do (
    set /a "v_y=%%y + camera_y"
    for %%v in (!v_y!) do (
        set "row_str=!bg[%%v]!                                                                                      "
        set "row_str=!row_str:~0,78!"
        if %%v GEQ 27 (
            set "row_str=!C_HILL!!row_str!"
            set "row_str=!row_str:[]=%C_WINDOW%[]%C_HILL%!"
        ) else (
            set "row_str=!C_SKY!!row_str!"
            set "row_str=!row_str:☾=%C_MOON%☾%C_SKY%!"
            set "row_str=!row_str:✦=%C_STAR_BRIGHT%✦%C_SKY%!"
            set "row_str=!row_str:·=%C_S1%·%C_SKY%!"
            set "row_str=!row_str:.=%C_S2%.%C_SKY%!"
            set "row_str=!row_str:+=%C_S3%+%C_SKY%!"
        )
        set "FRAME_RENDER=!FRAME_RENDER!!esc![%%y;2H!row_str!"
    )
)
set "FRAME_RENDER=!FRAME_RENDER!!C_RESET!"

:: -- Logo Animation Logic --
set /a "i_HHS = frame / 4"
if !i_HHS! GTR !MAX_PAL! set "i_HHS=!MAX_PAL!"

set /a "i_C2 = (frame - 20) / 4"
if !i_C2! LSS 0 set "i_C2=0"
if !i_C2! GTR !MAX_PAL! set "i_C2=!MAX_PAL!"

set /a "i_C4 = (frame - 35) / 4"
if !i_C4! LSS 0 set "i_C4=0"
if !i_C4! GTR !MAX_PAL! set "i_C4=!MAX_PAL!"

set /a "i_C6 = (frame - 50) / 4"
if !i_C6! LSS 0 set "i_C6=0"
if !i_C6! GTR !MAX_PAL! set "i_C6=!MAX_PAL!"

for %%i in (!i_HHS!) do set "C_HHS=!esc![38;5;!pal[%%i]!m"
for %%i in (!i_C2!) do set "C_C2=!esc![38;5;!pal[%%i]!m"
for %%i in (!i_C4!) do set "C_C4=!esc![38;5;!pal[%%i]!m"
for %%i in (!i_C6!) do set "C_C6=!esc![38;5;!pal[%%i]!m"

set "D1=!esc![6;6H!C_HHS!!A1_1!!C_C2!!A1_2!!C_HHS!!A1_3!!C_C4!!A1_4!!C_HHS!!A1_5!!C_C6!!A1_6!"
set "D2=!esc![7;6H!C_HHS!!A2_1!!C_C2!!A2_2!!C_HHS!!A2_3!!C_C4!!A2_4!!C_HHS!!A2_5!!C_C6!!A2_6!"
set "D3=!esc![8;6H!C_HHS!!A3_1!!C_C2!!A3_2!!C_HHS!!A3_3!!C_C4!!A3_4!!C_HHS!!A3_5!!C_C6!!A3_6!"
set "D4=!esc![9;6H!C_HHS!!A4_1!!C_C2!!A4_2!!C_HHS!!A4_3!!C_C4!!A4_4!!C_HHS!!A4_5!!C_C6!!A4_6!"
set "D5=!esc![10;6H!C_HHS!!A5_1!!C_C2!!A5_2!!C_HHS!!A5_3!!C_C4!!A5_4!!C_HHS!!A5_5!!C_C6!!A5_6!"
set "D6=!esc![11;6H!C_HHS!!A6_1!!C_C2!!A6_2!!C_HHS!!A6_3!!C_C4!!A6_4!!C_HHS!!A6_5!!C_C6!!A6_6!"
set "FRAME_RENDER=!FRAME_RENDER!!D1!!D2!!D3!!D4!!D5!!D6!"

:: Typewriter effect for "P R E S E N T S"
if !frame! GEQ 82 (
    set /a "p_chars=(frame - 82) / 2"
    if !p_chars! GTR 15 set "p_chars=15"
    for %%c in (!p_chars!) do set "C_PRESENTS=!PRESENTS_TEXT:~0,%%c!"
    set "FRAME_RENDER=!FRAME_RENDER!!esc![14;33H!C_TEXT!!C_PRESENTS!"
)

:: Animate dots and text for "INITIALIZING SYSTEM" (Always drawn)
set /a "dot_idx=(frame / 5) %% 3"
if !dot_idx! == 0 set "dots=.  "
if !dot_idx! == 1 set "dots=.. "
if !dot_idx! == 2 set "dots=..."
set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!C_TEXT!INITIALIZING SYSTEM!dots!"

:: Animate shooting stars in the background
for /L %%i in (1,1,3) do (
    set "act=!star%%i_active!"
    set "x=!star%%i_x!"
    set "y=!star%%i_y!"
    set "dx=!star%%i_dx!"
    set "dy=!star%%i_dy!"
    set "lx=!star%%i_lx!"
    set "ly=!star%%i_ly!"
    set "col=!star%%i_color!"
    set "char=!star%%i_char!"
    
    if "!act!"=="1" (
        :: Erase previous star position if it was drawn (buffered)
        if defined ly (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![!ly!;!lx!H "
            set "ly="
            set "lx="
        )
        
        :: Move star
        set /a "x+=dx"
        set /a "y+=dy"
        
        :: Check boundaries (strictly avoid borders at y=1, y=24, x=1, x=80)
        if !y! LEQ 1 set "act=0"
        if !y! GEQ 24 set "act=0"
        if !x! LEQ 1 set "act=0"
        if !x! GEQ 80 set "act=0"
        
        if "!act!"=="1" (
            :: Check safety (not colliding with UI elements or the hill silhouette)
            set "safe=1"
            if !y! GEQ 6 if !y! LEQ 11 if !x! GEQ 6 if !x! LEQ 75 set "safe=0"
            if !y! == 14 if !x! GEQ 33 if !x! LEQ 47 set "safe=0"
            if !y! == 19 if !x! GEQ 30 if !x! LEQ 52 set "safe=0"
            if !y! == 21 if !x! GEQ 22 if !x! LEQ 58 set "safe=0"
            
            :: Dynamic hill collision
            set /a "hill_y=27 - camera_y"
            if !y! GEQ !hill_y! set "safe=0"
            
            if "!safe!"=="1" (
                set "FRAME_RENDER=!FRAME_RENDER!!esc![!y!;!x!H!esc![38;5;!col!m!char!!C_RESET!"
                set "ly=!y!"
                set "lx=!x!"
            )
        )
    ) else (
        :: Spawn a new star (only when logo fade is done: frame >= 82)
        if !frame! GEQ 82 (
            set /a "spawn=!RANDOM! %% 10"
            if !spawn! == 0 (
                set "act=1"
                set "y=2"
                
                :: Choose random pattern/direction (0 to 5) and set logical spawn range
                set /a "pat=!RANDOM! %% 6"
                if !pat! == 0 ( set "dx=-2" & set "dy=1" & set /a "x=35 + !RANDOM! %% 40" )
                if !pat! == 1 ( set "dx=2" & set "dy=1" & set /a "x=5 + !RANDOM! %% 40" )
                if !pat! == 2 ( set "dx=-1" & set "dy=1" & set /a "x=20 + !RANDOM! %% 55" )
                if !pat! == 3 ( set "dx=1" & set "dy=1" & set /a "x=5 + !RANDOM! %% 55" )
                if !pat! == 4 ( set "dx=-3" & set "dy=1" & set /a "x=45 + !RANDOM! %% 30" )
                if !pat! == 5 ( set "dx=3" & set "dy=1" & set /a "x=5 + !RANDOM! %% 30" )
                
                :: Randomize character symbol (sparkle, solid star, dot, standard, tiny)
                set /a "char_rand=!RANDOM! %% 5"
                if !char_rand! == 0 set "char=✦"
                if !char_rand! == 1 set "char=★"
                if !char_rand! == 2 set "char=•"
                if !char_rand! == 3 set "char=*"
                if !char_rand! == 4 set "char=."
                
                :: Randomize color (pastels, whites, neons)
                set /a "color_rand=!RANDOM! %% 8"
                if !color_rand! == 0 set "col=255"
                if !color_rand! == 1 set "col=123"
                if !color_rand! == 2 set "col=81"
                if !color_rand! == 3 set "col=207"
                if !color_rand! == 4 set "col=147"
                if !color_rand! == 5 set "col=229"
                if !color_rand! == 6 set "col=121"
                if !color_rand! == 7 set "col=246"
            )
        )
    )
    
    :: Write back changes
    set "star%%i_active=!act!"
    set "star%%i_x=!x!"
    set "star%%i_y=!y!"
    set "star%%i_dx=!dx!"
    set "star%%i_dy=!dy!"
    set "star%%i_lx=!lx!"
    set "star%%i_ly=!ly!"
    set "star%%i_color=!col!"
    set "star%%i_char=!char!"
)

:: Check for interactive setup wizard request (for first-time launch / WT warning)
if exist "%TEMP%\splash_ui_req.tmp" (
    findstr /i "NEED_SETUP" "%TEMP%\splash_ui_req.tmp" >nul
    if "!errorlevel!"=="0" (
        :: Import temporary environment validation cache to the parent shell
        if exist "%TEMP%\ad_boot_diag_result.env" (
            for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%TEMP%\ad_boot_diag_result.env") do (
                set "%%A=%%B"
            )
            del "%TEMP%\ad_boot_diag_result.env" >nul 2>&1
        )
        call :RenderLanguageWizard
        call :RenderFontWizard
        call :RenderStorageWizard
    )
    findstr /i "NEED_WT_WARN" "%TEMP%\splash_ui_req.tmp" >nul
    if "!errorlevel!"=="0" (
        call :RenderWTWarning
    )
    del "%TEMP%\splash_ui_req.tmp" >nul 2>&1
)

:: Read & calculate progress only during loading state (state=0)
if "!state!"=="0" (
    if exist "!PROGRESS_FILE!" (
        for /f "usebackq delims=" %%p in ("!PROGRESS_FILE!") do set "actual_pct=%%p"
    )
    set /a "pct=!actual_pct!+0"
) else (
    set "pct=100"
)

:: -- State-specific UI and Transition Logic (FSM) --
if "!state!"=="0" (
    :: State 0: Loading bar rising
    set /a "bar_len=(pct * 30) / 100"
    set "bar="
    if !bar_len! GTR 0 for /L %%b in (1,1,!bar_len!) do set "bar=!bar!█"
    set "space="
    set /a rem=30-bar_len
    if !rem! GTR 0 for /L %%s in (1,1,!rem!) do set "space=!space!-"
    
    set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!C_TEXT!INITIALIZING SYSTEM!dots!"
    set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!C_TEXT![!C_LOAD!!bar!!C_TEXT!!space!] !pct!%% !C_RESET!"
    
    if !pct! GEQ 100 (
        set "state=2"
        set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!esc![K!C_TEXT!     SYSTEM READY.    !C_RESET!"
        set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!esc![K!C_TEXT!        Press any key to start...        !C_RESET!"
        if exist "!cmdwiz_path!" (
            call "!cmdwiz_path!" flushkeys >nul 2>&1
        )
    )
) else (
    if "!state!"=="2" (
        set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!esc![K!C_TEXT!     SYSTEM READY.    !C_RESET!"
        set /a "blink=frame %% 20"
        if !blink! LSS 10 (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!esc![K!C_TEXT!        Press any key to start...        !C_RESET!"
        ) else (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!esc![K"
        )
    )
)

:: FLUSH FRAME BUFFER ATOMICALLY (Swaps buffer in a single write call!)
set "FRAME_RENDER=!FRAME_RENDER!!esc![24;80H!esc![?25l"
<nul set /p ="!FRAME_RENDER!"

:: Precise delay to smooth out rendering and make the animation fully enjoyable!
for /L %%d in (1,1,11) do rem /? >nul 2>&1

:: State-specific Loop Control
if !state! LSS 2 (
    goto ProgressLoop
) else (
    if exist "!cmdwiz_path!" (
        "!cmdwiz_path!" getch noWait >nul 2>&1
        if errorlevel 1 goto LoopExit
    ) else (
        pause >nul
        goto LoopExit
    )
    goto ProgressLoop
)
:LoopExit
:: Cleanup progress file
if exist "!PROGRESS_FILE!" del "!PROGRESS_FILE!" >nul 2>&1

:: 1. BGM STOP (Fade out and stop the BGM with robust retry logic)
if exist "%SPLASH_BGM%" (
    set "bgm_stopped=0"
    for /L %%r in (1,1,3) do (
        if "!bgm_stopped!"=="0" (
            call "%BGM_PLAYER%" STOP 1500
            if !ERRORLEVEL! == 0 (
                set "bgm_stopped=1"
            ) else (
                :: Wait a moment before retrying
                for /L %%d in (1,1,10) do sc query >nul
                if %%r == 3 (
                    :: Last resort: force close the background Powershell player to prevent dangling audio
                    taskkill /f /im powershell.exe >nul 2>&1
                    set "bgm_stopped=1"
                )
            )
        )
    )
)

:: 2. Maximize and Animation (Trigger Fullscreen and the immersive cosmic warp transition!)
:: [Bypassed] Managed by Main.bat instead to allow parent window to serve as WatchDog.

:: 3. End (Restore cursor and clear screen to transition to game)
echo !esc![?25h!esc![2J!esc![1;1H
endlocal
exit /b 0


:: =============================================================================
:: INTERACTIVE SETUP WIZARDS (RUN WITHIN SPLASH FRAME BUFFER ON FIRST LAUNCH)
:: =============================================================================

:RenderFontWizard
:: If external tools are blocked, skip font selection wizard safely
if "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
    if defined RCSU call "%RCSU%" -trace WARN Splash "Wizard - External tools blocked. Skipping Font Selection."
    exit /b
)
if not exist "!cmdwiz_path!" (
    if defined RCSU call "%RCSU%" -trace WARN Splash "Wizard - cmdwiz.exe not found at !cmdwiz_path!. Skipping Font Selection."
    exit /b
)

:: Ensure UTF-8 active
chcp 65001 >nul

:FontSelectionLoop
:: Clear screen and redraw outer GUI frame
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

:: Render font selection title
echo !esc![4;24H!C_TEXT!Font Configuration / フォント設定!C_RESET!
echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![8;10H!C_TEXT![1] SimSun   (推奨 / Recommended - Beautiful backslash \)!C_RESET!
echo !esc![10;10H!C_TEXT![2] Consolas (等幅フォント / Elegant monospaced - Good for code)!C_RESET!
echo !esc![12;10H!C_TEXT![3] MSGothic (標準フォント / Standard Japanese Gothic font)!C_RESET!

echo !esc![15;10H!C_TEXT!Please select a font (Press 1, 2, or 3):!C_RESET!
echo !esc![16;10H!C_TEXT!フォントを選択してください (1, 2, 3):!C_RESET!

echo !esc![18;38H!C_RESET!

choice /c 123 /n /m "> "
set "_font_choice=%errorlevel%"

set "TEMP_FONT="
if "%_font_choice%"=="1" set "TEMP_FONT=SimSun"
if "%_font_choice%"=="2" set "TEMP_FONT=Consolas"
if "%_font_choice%"=="3" set "TEMP_FONT=MSGothic"

if not defined TEMP_FONT goto FontSelectionLoop

:: Apply selected font temporarily via cmdwiz.exe to let the user preview it immediately!
call "!cmdwiz_path!" setfont "%PROJECT_ROOT%\Tools\!TEMP_FONT!.fnt" >nul 2>&1

:: Display premium preview frame to show characters clearly
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

echo !esc![4;22H!C_TEXT!Font Selection Preview  /  プレビュー!C_RESET!
echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![7;10H!C_TEXT!Selected Font: !C_LOAD!!TEMP_FONT!!C_RESET!
echo !esc![9;10H!C_BORDER!┌──────────────────────────────────────────────────────────────┐!C_RESET!
echo !esc![10;10H!C_BORDER!│ !C_TEXT!Preview Text:                                                !C_BORDER!│!C_RESET!
echo !esc![11;10H!C_BORDER!│ !C_TEXT!Path / パス:  C:\Users\shoya\Desktop\AstralDivide            !C_BORDER!│!C_RESET!
echo !esc![12;10H!C_BORDER!│ !C_TEXT!Slash / 円記号: \  (Should display as a backslash, not ¥)    !C_BORDER!│!C_RESET!
echo !esc![13;10H!C_BORDER!│ !C_TEXT!Symbols / 記号: [ ] { } ( ) ^< ^> * # @ ^& ^| ? + - = _ /        !C_BORDER!│!C_RESET!
echo !esc![14;10H!C_BORDER!└──────────────────────────────────────────────────────────────┘!C_RESET!

echo !esc![16;10H!C_TEXT!Apply this font? / このフォントを設定しますか？ (Y/N):!C_RESET!
echo !esc![18;10H!C_TEXT!Y: Confirm ^& Proceed / 決定して次へ!C_RESET!
echo !esc![19;10H!C_TEXT!N: Try another font / 選び直す!C_RESET!

echo !esc![21;38H!C_RESET!

choice /c yn /n /m "> "
set "_confirm_choice=%errorlevel%"

if "%_confirm_choice%"=="2" (
    goto FontSelectionLoop
)

set "SELECTED_FONT=!TEMP_FONT!"
if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Selected font is !SELECTED_FONT!"
exit /b


:RenderLanguageWizard
:: Clear screen and redraw outer GUI frame
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

:: Render setup screen text
echo !esc![5;22H!C_TEXT!Language Selection  /  言語設定!C_RESET!
echo !esc![6;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![9;25H!C_TEXT![1] 日本語 (ja-JP) - 既定!C_RESET!
echo !esc![11;25H!C_TEXT![2] English (en-US)!C_RESET!

echo !esc![15;15H!C_TEXT!Please select your language (Press 1 or 2):!C_RESET!
echo !esc![16;15H!C_TEXT!使用する言語を選択してください (1 または 2 を押す):!C_RESET!

echo !esc![18;38H!C_RESET!

choice /c 12 /n /m "> "
set "_lang_choice=%errorlevel%"

if "%_lang_choice%"=="1" (
    set "SELECTED_LANG=ja-JP"
) else (
    set "SELECTED_LANG=en-US"
)
if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Selected language is !SELECTED_LANG!"
exit /b


:RenderStorageWizard
:: Clear screen and redraw outer GUI frame
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

:: Render storage setup text
echo !esc![4;20H!C_TEXT!Save Data Location Wizard  /  セーブ先設定!C_RESET!
echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![8;10H!C_TEXT![1] Project folder (推奨 / ポータブル / portable)!C_RESET!
echo !esc![9;14H!esc![38;5;244m➔ %%PROJECT_ROOT%%\Saves!C_RESET!

echo !esc![12;10H!C_TEXT![2] AppData (ローカル / per-user)!C_RESET!
echo !esc![13;14H!esc![38;5;244m➔ !LOCALAPPDATA!\HedgeHogSoft\AstralDivide\Saves!C_RESET!

echo !esc![16;10H!C_TEXT![3] Custom path (独自の絶対パスを指定する)!C_RESET!

echo !esc![19;12H!C_TEXT!Select Save Data Location (Press 1, 2 or 3):!C_RESET!
echo !esc![20;12H!C_TEXT!セーブデータの保存先を選択してください (1, 2, 3):!C_RESET!

echo !esc![21;38H!C_RESET!

choice /c 123 /n /m "> "
set "_store_choice=%errorlevel%"

if "%_store_choice%"=="1" (
    set "SAVE_MODE=portable"
    set "SAVE_DIR=%PROJECT_ROOT%\Saves"
) else if "%_store_choice%"=="2" (
    set "SAVE_MODE=localappdata"
    set "SAVE_DIR=!LOCALAPPDATA!\HedgeHogSoft\AstralDivide\Saves"
) else (
    :: Prompt for custom path within the same GUI framework
    echo !esc![22;12H!esc![K!C_TEXT!Enter absolute path: !C_RESET!
    set /p "CUSTOM_DIR="
    
    if "!CUSTOM_DIR!"=="" (
        set "SAVE_MODE=portable"
        set "SAVE_DIR=%PROJECT_ROOT%\Saves"
    ) else (
        set "SAVE_MODE=custom"
        set "SAVE_DIR=!CUSTOM_DIR!"
    )
)

:: Resolve path
for %%A in ("!SAVE_DIR!") do set "SAVE_DIR=%%~fA"

:: Create the save directory
if not exist "!SAVE_DIR!" md "!SAVE_DIR!" >nul 2>&1

if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Save mode is !SAVE_MODE! - Path: !SAVE_DIR!"

:: Proceed to Screen Resolution Probe Wizard!
call :RenderScreenDetectionWizard
exit /b

:: Clean up screen and redraw final frame border to return to main sequence
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝
exit /b


:RenderWTWarning
:: Clear screen and redraw outer GUI frame
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

:: Render Windows Terminal warning text
echo !esc![4;18H!esc![91m[WARNING] Windows Terminal {wt.exe} Detected!C_RESET!
echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![8;10H!C_TEXT!This game is designed and optimized for standard console (conhost.exe).!C_RESET!
echo !esc![10;10H!C_TEXT!Running under Windows Terminal may cause:!C_RESET!
echo !esc![12;12H!C_TEXT!1. Window size adjustments being ignored.!C_RESET!
echo !esc![13;12H!C_TEXT!2. Text UI and layout rendering misalignments.!C_RESET!
echo !esc![14;12H!C_TEXT!3. Misbehavior in external console utility tools.!C_RESET!

echo !esc![17;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!
echo !esc![19;12H!esc![92m[Recommendation] Close this window and relaunch via conhost.exe.!C_RESET!
echo !esc![20;12H!C_TEXT!To force launch anyway, press any key to continue...!C_RESET!

echo !esc![21;38H!C_RESET!
pause >nul
if defined RCSU call "%RCSU%" -trace WARN Splash "Windows Terminal warning acknowledged by user. Forcing boot."

:: Clean up screen and redraw final frame border to return to main sequence
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝
exit /b


:RenderScreenDetectionWizard
:: Clear screen and redraw outer GUI frame
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝

echo !esc![4;20H!C_TEXT!Screen Resolution Probe  /  画面サイズ自動測定!C_RESET!
echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!

echo !esc![8;10H!C_TEXT!ゲーム画面のレイアウトをあなたのモニターに最適化するため、!C_RESET!
echo !esc![9;10H!C_TEXT!ディスプレイの最大表示可能数を自動的に測定します。!C_RESET!
echo.
echo !esc![11;10H!esc![91m※測定中、一時的に画面が最大化（全画面表示）に切り替わりますが、!C_RESET!
echo !esc![12;10H!esc![91m　測定完了後に自動的に元のサイズに戻りますのでご安心ください。!C_RESET!
echo.
echo !esc![15;10H!C_TEXT!This game will temporarily switch to fullscreen mode!C_RESET!
echo !esc![16;10H!C_TEXT!to detect your monitor's maximum supported dimensions.!C_RESET!

echo !esc![19;12H!C_TEXT!Press any key to start the screen detection wizard...!C_RESET!
echo !esc![20;12H!C_TEXT!準備ができたら、どれかキーを押して測定を開始してください...!C_RESET!

echo !esc![21;38H!C_RESET!
pause >nul

:: Foreground screen environment detection
set "SPLASH_RUNNING="
call "%PROJECT_ROOT%\Src\Systems\Environment\ScreenEnvironmentDetection.bat" "%PROJECT_ROOT%"

:: Load results from screen_config.env
set "screen_cfg_file=%PROJECT_ROOT%\Config\Cache\Screen\%COMPUTERNAME%\screen_config.env"
set "PROBED_COLS="
set "PROBED_ROWS="
if exist "%screen_cfg_file%" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%screen_cfg_file%") do (
        if "%%a"=="CONSOLE_WIDTH" set "PROBED_COLS=%%b"
        if "%%a"=="CONSOLE_HEIGHT" set "PROBED_ROWS=%%b"
    )
)

:: Guard defaults
if not defined PROBED_COLS set "PROBED_COLS=90"
if not defined PROBED_ROWS set "PROBED_ROWS=35"

:: Write to user_config.env
set "_config_file=%PROJECT_ROOT%\Config\user_config.env"
if not exist "%PROJECT_ROOT%\Config" md "%PROJECT_ROOT%\Config" >nul 2>&1
echo # Astral Divide profile [auto-written by Splash Wizard]> "%_config_file%.tmp"
echo PROFILE_SCHEMA=1>> "%_config_file%.tmp"
echo CODEPAGE=65001>> "%_config_file%.tmp"
echo LANGUAGE=!SELECTED_LANG!>> "%_config_file%.tmp"
if defined SELECTED_FONT echo CONSOLE_FONT=!SELECTED_FONT!>> "%_config_file%.tmp"
echo SAVE_MODE=!SAVE_MODE!>> "%_config_file%.tmp"
echo SAVE_DIR=!SAVE_DIR!>> "%_config_file%.tmp"
echo CONSOLE_COLS=%PROBED_COLS%>> "%_config_file%.tmp"
echo CONSOLE_ROWS=%PROBED_ROWS%>> "%_config_file%.tmp"
move /y "%_config_file%.tmp" "%_config_file%" >nul

:: Restore standard console size for splash continuation
mode con cols=80 lines=25
echo !esc![2J
echo !esc![1;1H!C_BORDER!╔══════════════════════════════════════════════════════════════════════════════╗
for /L %%i in (2,1,23) do (
    echo !esc![%%i;1H!C_BORDER!║!esc![%%i;80H!C_BORDER!║
)
echo !esc![24;1H!C_BORDER!╚══════════════════════════════════════════════════════════════════════════════╝
exit /b
