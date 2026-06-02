@echo off
::------------------------------------------------------------------------------
:: Splash.RenderFrame.bat
:: Renders the current frame by reading variables set by UpdateState.
::------------------------------------------------------------------------------
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

:: Draw Stars
for /L %%i in (1,1,3) do (
    set "act=!star%%i_active!"
    set "x=!star%%i_x!"
    set "y=!star%%i_y!"
    set "lx=!star%%i_lx!"
    set "ly=!star%%i_ly!"
    set "col=!star%%i_color!"
    set "char=!star%%i_char!"
    
    if "!act!"=="1" (
        :: Erase previous star position if it was drawn (buffered)
        if defined ly (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![!ly!;!lx!H "
        )
        
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
            set "star%%i_ly=!y!"
            set "star%%i_lx=!x!"
        ) else (
            set "star%%i_ly="
            set "star%%i_lx="
        )
    )
)

:: -- UI and Status rendering --
if "!state!"=="0" (
    :: -- Render Remote Debugging Indicator (Top Header Overlay) --
    if "%REMOTE_MODE%"=="1" (
        if defined REMOTE_TOKEN (
            set /a "sp_idx=(frame / 1) %% 4"
            for %%i in (!sp_idx!) do set "spinner_char=!spinner_pattern:~%%i,1!"
            set /a "r_blink=(frame / 8) %% 2"
            if "!r_blink!"=="0" (
                set "FRAME_RENDER=!FRAME_RENDER!!esc![3;25H!esc![38;5;196m● LIVE REMOTE ACTIVE [!spinner_char!]!C_RESET!"
            ) else (
                set "FRAME_RENDER=!FRAME_RENDER!!esc![3;25H!esc![38;5;88m● LIVE REMOTE ACTIVE [!spinner_char!]!C_RESET!"
            )
        )
    )

    set /a "bar_len=(pct * 30) / 100"
    set "bar="
    if !bar_len! GTR 0 for /L %%b in (1,1,!bar_len!) do set "bar=!bar!█"
    set "space="
    set /a rem=30-bar_len
    if !rem! GTR 0 for /L %%s in (1,1,!rem!) do set "space=!space!-"
    
    set "status_col=30"
    set "status_msg=INITIALIZING SYSTEM"
    if "%REMOTE_MODE%"=="1" (
        if defined REMOTE_LOGGED_IN (
            if not defined REMOTE_TOKEN (
                set "status_col=22"
                set "status_msg=Waiting for developer's approval"
            )
        )
    )
    
    set "FRAME_RENDER=!FRAME_RENDER!!esc![19;!status_col!H!C_TEXT!!status_msg!!dots!"
    set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!C_TEXT![!C_LOAD!!bar!!C_TEXT!!space!] !pct!%% !C_RESET!"
    
    if !pct! GEQ 100 (
        set "state=2"
        set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!C_TEXT!     SYSTEM READY.               !C_RESET!"
        set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!C_TEXT!        Press any key to start...        !C_RESET!"
        if exist "!cmdwiz_path!" (
            call "!cmdwiz_path!" flushkeys >nul 2>&1
        )
    )
) else (
    if "!state!"=="2" (
        set "FRAME_RENDER=!FRAME_RENDER!!esc![19;30H!C_TEXT!     SYSTEM READY.               !C_RESET!"
        set /a "blink=frame %% 20"
        if !blink! LSS 10 (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H!C_TEXT!        Press any key to start...        !C_RESET!"
        ) else (
            set "FRAME_RENDER=!FRAME_RENDER!!esc![21;22H                                         "
        )
    )
)

exit /b
