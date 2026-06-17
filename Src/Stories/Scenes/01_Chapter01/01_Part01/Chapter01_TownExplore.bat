@echo off
setlocal EnableExtensions EnableDelayedExpansion

if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
if not defined tools_dir set "tools_dir=%PROJECT_ROOT%\Tools"
if not defined src_display_dir set "src_display_dir=%PROJECT_ROOT%\Src\Systems\Display"
if not defined assets_images_dir set "assets_images_dir=%PROJECT_ROOT%\Assets\Images"

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

set "MODULE_NAME=Chapter01TownExplore"
set "CURRENT_SKIP_POLICY=1"
set "current_chapter=Chapter01"
set "player_storyroute=Chapter01_Part01"
set "current_scene=Chapter01_TownExplore"
set "current_save_supported=1"
set "resume_storyroute=Chapter01_Part01"
set "resume_scene=Chapter01_TownExplore"
set "resume_location=%current_location%"
set "town_should_exit=0"
set "town_exit_rc=0"
set "town_message="
set "town_dirty=1"
set "last_bg="

call :DefineNodes
if not defined chapter01_town_node set "chapter01_town_node=Town01_HomeFront"
call :EnterNode "%chapter01_town_node%"
call "%tools_dir%\cmdwiz.exe" setquickedit 0 <nul >nul 2>&1

:TownLoop
if "%town_dirty%"=="1" (
    call :RenderScene
    set "town_dirty=0"
)
call :PollInput
if "%pick%"=="0" (
    "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :TownLoop
)
if "%pick%"=="PAUSE" (
    call "%src_display_dir%\PauseManager.bat" ENTER FULL
    set "pause_rc=!errorlevel!"
    if "!pause_rc!"=="641" goto :ExitToTitle
    if "!pause_rc!"=="642" goto :ExitGame
    set "last_bg="
    set "town_dirty=1"
    goto :TownLoop
)
if "%pick%"=="W" (
    call :HandleAction W
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="A" (
    call :HandleAction A
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="S" (
    call :HandleAction S
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="D" (
    call :HandleAction D
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="E" (
    call :HandleAction E
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
goto :TownLoop

:ExitNormal
if exist "%RCSU%" call "%RCSU%" -trace INFO "%MODULE_NAME%" "exit normal rc=%town_exit_rc% node=%chapter01_town_node%"
endlocal & (
    set "current_chapter=%current_chapter%"
    set "player_storyroute=%player_storyroute%"
    set "current_scene=%current_scene%"
    set "current_location=%current_location%"
    set "resume_storyroute=%resume_storyroute%"
    set "resume_scene=%resume_scene%"
    set "resume_location=%resume_location%"
    set "current_save_supported=%current_save_supported%"
    set "chapter01_town_started=%chapter01_town_started%"
    set "chapter01_town_node=%chapter01_town_node%"
    set "chapter01_seen_home_intro=%chapter01_seen_home_intro%"
    set "chapter01_seen_plaza=%chapter01_seen_plaza%"
    set "chapter01_seen_tavern=%chapter01_seen_tavern%"
    set "chapter01_seen_academy_gate=%chapter01_seen_academy_gate%"
    set "chapter01_quest_tavern_intro=%chapter01_quest_tavern_intro%"
    exit /b %town_exit_rc%
)

:ExitToTitle
endlocal
exit /b 641

:ExitGame
endlocal
exit /b 642

:PollInput
set "pick=0"
"%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "scan_code=%errorlevel%"
if "%scan_code%"=="87" set "pick=W"
if "%scan_code%"=="119" set "pick=W"
if "%scan_code%"=="72" set "pick=W"
if "%scan_code%"=="65" set "pick=A"
if "%scan_code%"=="97" set "pick=A"
if "%scan_code%"=="75" set "pick=A"
if "%scan_code%"=="83" set "pick=S"
if "%scan_code%"=="115" set "pick=S"
if "%scan_code%"=="80" set "pick=S"
if "%scan_code%"=="68" set "pick=D"
if "%scan_code%"=="100" set "pick=D"
if "%scan_code%"=="77" set "pick=D"
if "%scan_code%"=="70" set "pick=E"
if "%scan_code%"=="102" set "pick=E"
if "%scan_code%"=="13" if "%pick%"=="0" set "pick=E"
if "%scan_code%"=="27" set "pick=PAUSE"
if "%scan_code%"=="112" if "%pick%"=="0" set "pick=PAUSE"
if "%scan_code%"=="25" if "%pick%"=="0" set "pick=PAUSE"
exit /b 0

:HandleAction
set "action_key=%~1"
set "action_spec="
set "action_type="
set "action_value="
call set "action_spec=%%NODE_%chapter01_town_node%_%action_key%%%"
if not defined action_spec (
    set "town_message=No path."
    set "town_dirty=1"
    exit /b 0
)
for /f "tokens=1* delims=:" %%A in ("%action_spec%") do (
    set "action_type=%%A"
    set "action_value=%%B"
)
if /i "%action_type%"=="move" (
    call :EnterNode "%action_value%"
    exit /b 0
)
if /i "%action_type%"=="text" (
    set "town_message=%action_value%"
    set "town_dirty=1"
    exit /b 0
)
if /i "%action_type%"=="finish" (
    set "town_message=%action_value%"
    set "current_scene=Chapter01_TownExplore_Complete"
    set "resume_scene=Chapter01_TownExplore_Complete"
    set "resume_location=%current_location%"
    set "town_should_exit=1"
    set "town_exit_rc=0"
    exit /b 0
)
set "town_message=No path."
set "town_dirty=1"
exit /b 0

:EnterNode
set "chapter01_town_node=%~1"
set "chapter01_town_started=1"
call set "current_location=%%NODE_%chapter01_town_node%_LOCATION%%"
call set "resume_location=%%NODE_%chapter01_town_node%_LOCATION%%"
set "current_scene=Chapter01_TownExplore_%chapter01_town_node%"
set "resume_scene=Chapter01_TownExplore_%chapter01_town_node%"
set "town_message="
if /i "%chapter01_town_node%"=="Town01_HomeFront" if not "%chapter01_seen_home_intro%"=="1" set "chapter01_seen_home_intro=1"
if /i "%chapter01_town_node%"=="Town04_MainSquare" if not "%chapter01_seen_plaza%"=="1" set "chapter01_seen_plaza=1"
if /i "%chapter01_town_node%"=="Town05_TavernFront" if not "%chapter01_seen_tavern%"=="1" set "chapter01_seen_tavern=1"
if /i "%chapter01_town_node%"=="Town07_AcademyGate" if not "%chapter01_seen_academy_gate%"=="1" set "chapter01_seen_academy_gate=1"
if /i "%chapter01_town_node%"=="Town08_TavernInterior" if not "%chapter01_quest_tavern_intro%"=="1" set "chapter01_quest_tavern_intro=1"
set "town_dirty=1"
exit /b 0

:RenderScene
call set "bg_name=%%NODE_%chapter01_town_node%_BG%%"
set "bg_path=%assets_images_dir%\%bg_name%"
if /i not "%last_bg%"=="%bg_path%" (
    if exist "%bg_path%" "%tools_dir%\cmdbkg.exe" "%bg_path%" /b /t 33 >nul 2>&1
    set "last_bg=%bg_path%"
)
cls
call :DrawFrame
call :DrawBody
call :DrawActionList
exit /b 0

:DrawFrame
echo %ESC%[3;24H%ESC%[96mCHAPTER 1 TOWN EXPLORE%ESC%[0m
echo %ESC%[4;24H%ESC%[90mWASD move / F or Enter inspect / P or Esc pause%ESC%[0m
echo %ESC%[5;24H%ESC%[90m================================================================================================================================================================%ESC%[0m
echo %ESC%[58;24H%ESC%[90m================================================================================================================================================================%ESC%[0m
echo %ESC%[59;24H%ESC%[90mLocation:%ESC%[0m %current_location%
exit /b 0

:DrawBody
call set "scene_title=%%NODE_%chapter01_town_node%_TITLE%%"
call set "desc_1=%%NODE_%chapter01_town_node%_DESC1%%"
call set "desc_2=%%NODE_%chapter01_town_node%_DESC2%%"
echo %ESC%[61;24H%ESC%[93m[%scene_title%]%ESC%[0m
echo %ESC%[62;24H%ESC%[0K%desc_1%
echo %ESC%[63;24H%ESC%[0K%desc_2%
if defined town_message (
    echo %ESC%[64;24H%ESC%[0K%ESC%[92m%town_message%%ESC%[0m
)
if not defined town_message (
    echo %ESC%[64;24H%ESC%[0K%ESC%[90mChoose an action.%ESC%[0m
)
exit /b 0

:DrawActionList
call set "label_w=%%NODE_%chapter01_town_node%_W_LABEL%%"
call set "label_a=%%NODE_%chapter01_town_node%_A_LABEL%%"
call set "label_s=%%NODE_%chapter01_town_node%_S_LABEL%%"
call set "label_d=%%NODE_%chapter01_town_node%_D_LABEL%%"
call set "label_e=%%NODE_%chapter01_town_node%_E_LABEL%%"
echo %ESC%[60;130H%ESC%[96mW%ESC%[0m %label_w%
echo %ESC%[61;130H%ESC%[96mA%ESC%[0m %label_a%
echo %ESC%[62;130H%ESC%[96mS%ESC%[0m %label_s%
echo %ESC%[63;130H%ESC%[96mD%ESC%[0m %label_d%
echo %ESC%[64;130H%ESC%[96mE%ESC%[0m %label_e%
exit /b 0

:DefineNodes
set "NODE_Town01_HomeFront_BG=Chapter01_Town_01_HomeFront.png"
set "NODE_Town01_HomeFront_LOCATION=Elysion - Home Front"
set "NODE_Town01_HomeFront_TITLE=Home Front"
set "NODE_Town01_HomeFront_DESC1=The street opens toward the city center beyond the slope."
set "NODE_Town01_HomeFront_DESC2=Your walk through the capital starts here."
set "NODE_Town01_HomeFront_W=move:Town02_DownhillRoad"
set "NODE_Town01_HomeFront_A=text:The wall and flowerbeds frame the doorway."
set "NODE_Town01_HomeFront_S=text:You are not going back inside right now."
set "NODE_Town01_HomeFront_D=text:Quiet homes continue along the right side."
set "NODE_Town01_HomeFront_E=text:The plants near the entrance are neatly cared for."
set "NODE_Town01_HomeFront_W_LABEL=Go downhill"
set "NODE_Town01_HomeFront_A_LABEL=Look left"
set "NODE_Town01_HomeFront_S_LABEL=Look back"
set "NODE_Town01_HomeFront_D_LABEL=Look right"
set "NODE_Town01_HomeFront_E_LABEL=Inspect entrance"

set "NODE_Town02_DownhillRoad_BG=Chapter01_Town_02_DownhillRoad.png"
set "NODE_Town02_DownhillRoad_LOCATION=Elysion - Downhill Road"
set "NODE_Town02_DownhillRoad_TITLE=Downhill Road"
set "NODE_Town02_DownhillRoad_DESC1=More people are heading toward the market as the road descends."
set "NODE_Town02_DownhillRoad_DESC2=The castle feels closer from here."
set "NODE_Town02_DownhillRoad_W=move:Town03_MarketStreet"
set "NODE_Town02_DownhillRoad_A=text:Morning sounds leak from the houses on the left."
set "NODE_Town02_DownhillRoad_S=move:Town01_HomeFront"
set "NODE_Town02_DownhillRoad_D=text:A few stalls are still setting up on the right."
set "NODE_Town02_DownhillRoad_E=text:The road already carries the rhythm of the capital."
set "NODE_Town02_DownhillRoad_W_LABEL=Go to market"
set "NODE_Town02_DownhillRoad_A_LABEL=Look left"
set "NODE_Town02_DownhillRoad_S_LABEL=Return home front"
set "NODE_Town02_DownhillRoad_D_LABEL=Look right"
set "NODE_Town02_DownhillRoad_E_LABEL=Inspect road"

set "NODE_Town03_MarketStreet_BG=Chapter01_Town_03_MarketStreet.png"
set "NODE_Town03_MarketStreet_LOCATION=Elysion - Market Street"
set "NODE_Town03_MarketStreet_TITLE=Market Street"
set "NODE_Town03_MarketStreet_DESC1=Shops and stalls line the road with steady traffic in both directions."
set "NODE_Town03_MarketStreet_DESC2=The square lies ahead and a back alley opens to the right."
set "NODE_Town03_MarketStreet_W=move:Town04_MainSquare"
set "NODE_Town03_MarketStreet_A=text:Fruit and daily goods fill the storefronts on the left."
set "NODE_Town03_MarketStreet_S=move:Town02_DownhillRoad"
set "NODE_Town03_MarketStreet_D=move:Town09_BackAlley"
set "NODE_Town03_MarketStreet_E=text:Calls from vendors overlap with the sound of bargaining."
set "NODE_Town03_MarketStreet_W_LABEL=Go to square"
set "NODE_Town03_MarketStreet_A_LABEL=See left shops"
set "NODE_Town03_MarketStreet_S_LABEL=Back to slope"
set "NODE_Town03_MarketStreet_D_LABEL=Enter alley"
set "NODE_Town03_MarketStreet_E_LABEL=Inspect market"

set "NODE_Town04_MainSquare_BG=Chapter01_Town_04_MainSquare.png"
set "NODE_Town04_MainSquare_LOCATION=Elysion - Main Square"
set "NODE_Town04_MainSquare_TITLE=Main Square"
set "NODE_Town04_MainSquare_DESC1=The square opens around a fountain with people crossing in every direction."
set "NODE_Town04_MainSquare_DESC2=This is the town hub for the tavern, the castle road, and the plaza view."
set "NODE_Town04_MainSquare_W=move:Town06_CastleRoad"
set "NODE_Town04_MainSquare_A=move:Town05_TavernFront"
set "NODE_Town04_MainSquare_S=move:Town03_MarketStreet"
set "NODE_Town04_MainSquare_D=move:Town12_SquareFountainView"
set "NODE_Town04_MainSquare_E=text:The square is lively but still feels orderly."
set "NODE_Town04_MainSquare_W_LABEL=To castle road"
set "NODE_Town04_MainSquare_A_LABEL=To tavern"
set "NODE_Town04_MainSquare_S_LABEL=Back to market"
set "NODE_Town04_MainSquare_D_LABEL=View fountain"
set "NODE_Town04_MainSquare_E_LABEL=Inspect square"

set "NODE_Town05_TavernFront_BG=Chapter01_Town_05_TavernFront.png"
set "NODE_Town05_TavernFront_LOCATION=Elysion - Tavern Front"
set "NODE_Town05_TavernFront_TITLE=Tavern Front"
set "NODE_Town05_TavernFront_DESC1=The open door and signboard invite anyone passing by."
set "NODE_Town05_TavernFront_DESC2=Voices spill out from inside."
set "NODE_Town05_TavernFront_W=text:To go deeper, you should enter the tavern first."
set "NODE_Town05_TavernFront_A=text:Barrels and the signboard dominate the frontage."
set "NODE_Town05_TavernFront_S=move:Town04_MainSquare"
set "NODE_Town05_TavernFront_D=move:Town04_MainSquare"
set "NODE_Town05_TavernFront_E=move:Town08_TavernInterior"
set "NODE_Town05_TavernFront_W_LABEL=Look ahead"
set "NODE_Town05_TavernFront_A_LABEL=Inspect front"
set "NODE_Town05_TavernFront_S_LABEL=Back to square"
set "NODE_Town05_TavernFront_D_LABEL=Back to square"
set "NODE_Town05_TavernFront_E_LABEL=Enter tavern"

set "NODE_Town06_CastleRoad_BG=Chapter01_Town_06_CastleRoad.png"
set "NODE_Town06_CastleRoad_LOCATION=Elysion - Castle Road"
set "NODE_Town06_CastleRoad_TITLE=Castle Road"
set "NODE_Town06_CastleRoad_DESC1=A broad avenue leads straight toward the castle stairs."
set "NODE_Town06_CastleRoad_DESC2=The officer academy lies off to the right."
set "NODE_Town06_CastleRoad_W=move:Town10_CastleApproach"
set "NODE_Town06_CastleRoad_A=text:Well-kept buildings continue on the left."
set "NODE_Town06_CastleRoad_S=move:Town04_MainSquare"
set "NODE_Town06_CastleRoad_D=move:Town07_AcademyGate"
set "NODE_Town06_CastleRoad_E=text:The mood on this road is naturally more formal."
set "NODE_Town06_CastleRoad_W_LABEL=Go to stairs"
set "NODE_Town06_CastleRoad_A_LABEL=Look left"
set "NODE_Town06_CastleRoad_S_LABEL=Back to square"
set "NODE_Town06_CastleRoad_D_LABEL=To academy"
set "NODE_Town06_CastleRoad_E_LABEL=Inspect road"

set "NODE_Town07_AcademyGate_BG=Chapter01_Town_07_AcademyGate.png"
set "NODE_Town07_AcademyGate_LOCATION=Elysion - Academy Gate"
set "NODE_Town07_AcademyGate_TITLE=Academy Gate"
set "NODE_Town07_AcademyGate_DESC1=The academy stands beyond a formal gate watched by guards."
set "NODE_Town07_AcademyGate_DESC2=The place carries its own strict atmosphere."
set "NODE_Town07_AcademyGate_W=text:If you want to get closer, enter the building."
set "NODE_Town07_AcademyGate_A=move:Town06_CastleRoad"
set "NODE_Town07_AcademyGate_S=move:Town06_CastleRoad"
set "NODE_Town07_AcademyGate_D=text:The crest on the stone pillar is clearly visible."
set "NODE_Town07_AcademyGate_E=move:Town11_AcademyLobby"
set "NODE_Town07_AcademyGate_W_LABEL=Look ahead"
set "NODE_Town07_AcademyGate_A_LABEL=Back to road"
set "NODE_Town07_AcademyGate_S_LABEL=Back to road"
set "NODE_Town07_AcademyGate_D_LABEL=See pillar"
set "NODE_Town07_AcademyGate_E_LABEL=Enter academy"

set "NODE_Town08_TavernInterior_BG=Chapter01_Town_08_TavernInterior.png"
set "NODE_Town08_TavernInterior_LOCATION=Elysion - Tavern"
set "NODE_Town08_TavernInterior_TITLE=Tavern Interior"
set "NODE_Town08_TavernInterior_DESC1=Wood, lamplight, and table chatter make the room feel warm and busy."
set "NODE_Town08_TavernInterior_DESC2=The keeper stands at the center counter while guests occupy both sides."
set "NODE_Town08_TavernInterior_W=text:The counter draws your eyes straight ahead."
set "NODE_Town08_TavernInterior_A=text:Regulars on the left drink quietly."
set "NODE_Town08_TavernInterior_S=move:Town05_TavernFront"
set "NODE_Town08_TavernInterior_D=text:Laughter rises from the right tables."
set "NODE_Town08_TavernInterior_E=text:The keeper may know useful stories about the city."
set "NODE_Town08_TavernInterior_W_LABEL=See counter"
set "NODE_Town08_TavernInterior_A_LABEL=See left tables"
set "NODE_Town08_TavernInterior_S_LABEL=Exit tavern"
set "NODE_Town08_TavernInterior_D_LABEL=See right tables"
set "NODE_Town08_TavernInterior_E_LABEL=Inspect keeper"

set "NODE_Town09_BackAlley_BG=Chapter01_Town_09_BackAlley.png"
set "NODE_Town09_BackAlley_LOCATION=Elysion - Back Alley"
set "NODE_Town09_BackAlley_TITLE=Back Alley"
set "NODE_Town09_BackAlley_DESC1=The noise of the market falls away into damp stone and old doors."
set "NODE_Town09_BackAlley_DESC2=Posters and crates suggest a more private side of town."
set "NODE_Town09_BackAlley_W=text:The alley seems to continue deeper into quieter streets."
set "NODE_Town09_BackAlley_A=text:Layers of old notices cover the wall on the left."
set "NODE_Town09_BackAlley_S=move:Town03_MarketStreet"
set "NODE_Town09_BackAlley_D=text:The door on the right is shut tight."
set "NODE_Town09_BackAlley_E=text:You feel like someone may be watching from somewhere."
set "NODE_Town09_BackAlley_W_LABEL=Look deeper"
set "NODE_Town09_BackAlley_A_LABEL=See posters"
set "NODE_Town09_BackAlley_S_LABEL=Back to market"
set "NODE_Town09_BackAlley_D_LABEL=See right door"
set "NODE_Town09_BackAlley_E_LABEL=Inspect alley"

set "NODE_Town10_CastleApproach_BG=Chapter01_Town_10_CastleApproach.png"
set "NODE_Town10_CastleApproach_LOCATION=Elysion - Castle Stairs"
set "NODE_Town10_CastleApproach_TITLE=Castle Approach"
set "NODE_Town10_CastleApproach_DESC1=The castle dominates the stairs ahead and watches over the entire city."
set "NODE_Town10_CastleApproach_DESC2=This is the temporary end point for the current prototype."
set "NODE_Town10_CastleApproach_W=finish:Castle-side continuation will be connected next."
set "NODE_Town10_CastleApproach_A=text:Guards along the left side make the route feel even stricter."
set "NODE_Town10_CastleApproach_S=move:Town06_CastleRoad"
set "NODE_Town10_CastleApproach_D=text:More officials seem to move through the buildings on the right."
set "NODE_Town10_CastleApproach_E=finish:Castle-side continuation will be connected next."
set "NODE_Town10_CastleApproach_W_LABEL=Proceed"
set "NODE_Town10_CastleApproach_A_LABEL=Look left"
set "NODE_Town10_CastleApproach_S_LABEL=Back to road"
set "NODE_Town10_CastleApproach_D_LABEL=Look right"
set "NODE_Town10_CastleApproach_E_LABEL=Confirm end"

set "NODE_Town11_AcademyLobby_BG=Chapter01_Town_11_AcademyLobby.png"
set "NODE_Town11_AcademyLobby_LOCATION=Elysion - Academy Lobby"
set "NODE_Town11_AcademyLobby_TITLE=Academy Lobby"
set "NODE_Town11_AcademyLobby_DESC1=Polished floors, notices, and uniformed students define the academy mood."
set "NODE_Town11_AcademyLobby_DESC2=This area can branch deeper into academy scenes later."
set "NODE_Town11_AcademyLobby_W=text:Further academy scenes can connect beyond this point."
set "NODE_Town11_AcademyLobby_A=text:Lecture notices and instructions fill the board."
set "NODE_Town11_AcademyLobby_S=move:Town07_AcademyGate"
set "NODE_Town11_AcademyLobby_D=text:Students compare papers and seem used to the place."
set "NODE_Town11_AcademyLobby_E=text:For now, this lobby serves as an arrival point."
set "NODE_Town11_AcademyLobby_W_LABEL=Look ahead"
set "NODE_Town11_AcademyLobby_A_LABEL=See notice board"
set "NODE_Town11_AcademyLobby_S_LABEL=Back to gate"
set "NODE_Town11_AcademyLobby_D_LABEL=See students"
set "NODE_Town11_AcademyLobby_E_LABEL=Inspect lobby"

set "NODE_Town12_SquareFountainView_BG=Chapter01_Town_12_SquareFountainView.png"
set "NODE_Town12_SquareFountainView_LOCATION=Elysion - Fountain View"
set "NODE_Town12_SquareFountainView_TITLE=Square Fountain View"
set "NODE_Town12_SquareFountainView_DESC1=The fountain and benches in the foreground make it easier to watch the flow of people."
set "NODE_Town12_SquareFountainView_DESC2=This angle works better for quiet plaza moments."
set "NODE_Town12_SquareFountainView_W=text:If you move closer, you may catch more of the plaza chatter."
set "NODE_Town12_SquareFountainView_A=move:Town04_MainSquare"
set "NODE_Town12_SquareFountainView_S=move:Town04_MainSquare"
set "NODE_Town12_SquareFountainView_D=text:Food and daily-goods stalls line the right side."
set "NODE_Town12_SquareFountainView_E=text:The bench looks like a good place to pause and observe."
set "NODE_Town12_SquareFountainView_W_LABEL=Closer to fountain"
set "NODE_Town12_SquareFountainView_A_LABEL=Back to square"
set "NODE_Town12_SquareFountainView_S_LABEL=Back to square"
set "NODE_Town12_SquareFountainView_D_LABEL=See stalls"
set "NODE_Town12_SquareFountainView_E_LABEL=Inspect view"
exit /b 0
