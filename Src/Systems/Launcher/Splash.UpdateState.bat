@echo off
::------------------------------------------------------------------------------
:: Splash.UpdateState.bat
:: Handles state updates (frame, pan, colors, star positions).
::------------------------------------------------------------------------------

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

:: Animate shooting stars in the background
for /L %%i in (1,1,3) do (
    set "act=!star%%i_active!"
    set "x=!star%%i_x!"
    set "y=!star%%i_y!"
    set "dx=!star%%i_dx!"
    set "dy=!star%%i_dy!"
    set "col=!star%%i_color!"
    set "char=!star%%i_char!"
    
    if "!act!"=="1" (
        :: Move star
        set /a "x+=dx"
        set /a "y+=dy"
        
        :: Check boundaries (strictly avoid borders at y=1, y=24, x=1, x=80)
        if !y! LEQ 1 set "act=0"
        if !y! GEQ 24 set "act=0"
        if !x! LEQ 1 set "act=0"
        if !x! GEQ 80 set "act=0"
    ) else (
        :: Spawn a new star (only when logo fade is done: frame >= 42)
        if !frame! GEQ 42 (
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
    
    :: Write back changes (RenderFrame will handle ly/lx)
    set "star%%i_active=!act!"
    set "star%%i_x=!x!"
    set "star%%i_y=!y!"
    set "star%%i_dx=!dx!"
    set "star%%i_dy=!dy!"
    set "star%%i_color=!col!"
    set "star%%i_char=!char!"
)
exit /b
