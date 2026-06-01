@echo off
::------------------------------------------------------------------------------
:: Splash.Context.bat
:: Defines constants and initial states for the Splash screen.
::------------------------------------------------------------------------------

:: Audio Paths
set "BGM_PLAYER=%PROJECT_ROOT%\Src\Systems\Audio\BgmPlayer.bat"
set "SPLASH_BGM=%PROJECT_ROOT%\Assets\Sounds\孤独な少女.mp3"
set "INITIALIZER=%PROJECT_ROOT%\Src\Systems\Launcher\Splash_Initializer.bat"
set "PLAY_SE=%PROJECT_ROOT%\Src\Systems\Audio\Play_SE.bat"
set "SE_ENTER=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect\Enter.wav"
set "SE_ENTER3=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect\Enter3.wav"
set "SE_CANCEL=%PROJECT_ROOT%\Assets\Sounds\_SoundEffect\Cancel.wav"

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

:: Define background panning state variables
set "pan_state=0"
set "camera_y=14"
set "pan_timer=0"

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

:: Logo Animation Data
set "A1_1=  _   _ "&set "A1_2=         _            "&set "A1_3=_   _ "&set "A1_4=              "&set "A1_5=____    "&set "A1_6=     __ _   "
set "A2_1= | | | |"&set "A2_2= ___  __| | __ _  ___"&set "A2_3=| | | |"&set "A2_4= ___   __ _  "&set "A2_5=/ ___|  "&set "A2_6=___  / _| |_ "
set "A3_1= | |_| |"&set "A3_2=/ _ \/ _` |/ _` |/ _ \ "&set "A3_3=|_| |"&set "A3_4=/ _ \ / _` | "&set "A3_5=\___ \ "&set "A3_6=/ _ \| |_| __|"
set "A4_1= |  _  |"&set "A4_2=  __/ (_| | (_| |  __/"&set "A4_3=  _  |"&set "A4_4= (_) | (_| | "&set "A4_5= ___) |"&set "A4_6= (_) |  _| |_ "
set "A5_1= |_| |_|"&set "A5_2=\___|\__,_|\__, |\___|"&set "A5_3=_| |_|"&set "A5_4=\___/ \__, | "&set "A5_5=|____/ "&set "A5_6=\___/|_|  \__|"
set "A6_1=        "&set "A6_2=           |___/      "&set "A6_3=      "&set "A6_4=      |___/ "&set "A6_5=       "&set "A6_6=              "

:: Fade palette
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
set "spinner_pattern=-\|/"

:: Star initialization
for /L %%i in (1,1,3) do (
    set "star%%i_active=0"
    set "star%%i_lx="
    set "star%%i_ly="
)

exit /b
