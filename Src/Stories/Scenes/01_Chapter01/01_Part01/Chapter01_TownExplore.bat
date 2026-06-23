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
if not defined src_inventory_dir set "src_inventory_dir=%PROJECT_ROOT%\Src\Systems\Inventory"
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
if "%pick%"=="ACTION" (
    call :HandleAction E
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="INVENTORY" (
    call "%src_inventory_dir%\InventoryMenu.bat"
    set "town_message=所持品を確認した。"
    set "town_dirty=1"
    if "%town_should_exit%"=="1" goto :ExitNormal
    goto :TownLoop
)
if "%pick%"=="DEBUG_GRANT" (
    call "%src_inventory_dir%\InventoryDebugGrantMenu.bat"
    set "town_message=デバッグアイテム付与を終了した。"
    set "town_dirty=1"
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
    set "inventory_stack_count=%inventory_stack_count%"
    set "inventory_stack_1=%inventory_stack_1%"
    set "inventory_stack_2=%inventory_stack_2%"
    set "inventory_stack_3=%inventory_stack_3%"
    set "inventory_stack_4=%inventory_stack_4%"
    set "inventory_stack_5=%inventory_stack_5%"
    set "inventory_stack_6=%inventory_stack_6%"
    set "inventory_stack_7=%inventory_stack_7%"
    set "inventory_stack_8=%inventory_stack_8%"
    set "inventory_unique_count=%inventory_unique_count%"
    set "inventory_unique_1=%inventory_unique_1%"
    set "inventory_unique_2=%inventory_unique_2%"
    set "inventory_unique_3=%inventory_unique_3%"
    set "inventory_unique_4=%inventory_unique_4%"
    set "inventory_unique_5=%inventory_unique_5%"
    set "inventory_unique_6=%inventory_unique_6%"
    set "inventory_unique_7=%inventory_unique_7%"
    set "inventory_unique_8=%inventory_unique_8%"
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
if "%scan_code%"=="70" set "pick=ACTION"
if "%scan_code%"=="102" set "pick=ACTION"
if "%scan_code%"=="13" if "%pick%"=="0" set "pick=ACTION"
if "%scan_code%"=="69" if "%pick%"=="0" set "pick=INVENTORY"
if "%scan_code%"=="101" if "%pick%"=="0" set "pick=INVENTORY"
if /i "%DEBUG_STATE%"=="1" (
    if "%scan_code%"=="73" if "%pick%"=="0" set "pick=DEBUG_GRANT"
    if "%scan_code%"=="105" if "%pick%"=="0" set "pick=DEBUG_GRANT"
)
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
    set "town_message=この方向には進めない。"
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
set "town_message=この方向には進めない。"
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
call :DrawInputMap
call :DrawActionList
exit /b 0

:DrawFrame
echo %ESC%[3;24H%ESC%[96mCHAPTER 1 王都に生きる者%ESC%[0m
echo %ESC%[4;24H%ESC%[90m第一節 : 王都の朝 -祝祭前日-%ESC%[0m
echo %ESC%[5;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[55;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[56;24H%ESC%[90m──────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[56;104H%ESC%[90m───────── %ESC%[96mINPUT%ESC%[90m ─────────%ESC%[0m
echo %ESC%[56;150H%ESC%[90m──────────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[65;24H%ESC%[90m──────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[65;104H%ESC%[90m─────────────────────────%ESC%[0m
echo %ESC%[65;150H%ESC%[90m──────────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[57;28H%ESC%[96m状況%ESC%[0m
echo %ESC%[57;154H%ESC%[96m操作%ESC%[0m
echo %ESC%[59;28H%ESC%[90m現在地:%ESC%[0m %current_location%
exit /b 0

:DrawInputMap
call :SetInputKeyStyle W
set "key_w_style=%key_style%"
call :SetInputKeyStyle A
set "key_a_style=%key_style%"
call :SetInputKeyStyle S
set "key_s_style=%key_style%"
call :SetInputKeyStyle D
set "key_d_style=%key_style%"
echo %ESC%[60;115H%ESC%[%key_w_style%m W %ESC%[0m
echo %ESC%[61;111H%ESC%[%key_a_style%m A %ESC%[0m %ESC%[1;30;103m F %ESC%[0m %ESC%[%key_d_style%m D %ESC%[0m
echo %ESC%[62;115H%ESC%[%key_s_style%m S %ESC%[0m
echo %ESC%[61;121H%ESC%[30;46m E %ESC%[0m
exit /b 0

:SetInputKeyStyle
set "key_name=%~1"
set "key_style=90"
set "key_action="
set "key_action_type="
call set "key_action=%%NODE_%chapter01_town_node%_%key_name%%%"
for /f "tokens=1 delims=:" %%A in ("%key_action%") do set "key_action_type=%%A"
if /i "%key_action_type%"=="move" set "key_style=1;92"
if /i "%key_action_type%"=="finish" set "key_style=1;92"
exit /b 0

:DrawBody
call set "scene_title=%%NODE_%chapter01_town_node%_TITLE%%"
call set "desc_1=%%NODE_%chapter01_town_node%_DESC1%%"
call set "desc_2=%%NODE_%chapter01_town_node%_DESC2%%"
echo %ESC%[58;28H%ESC%[93m[%scene_title%]%ESC%[0m
echo %ESC%[60;28H%ESC%[0K%desc_1%
echo %ESC%[61;28H%ESC%[0K%desc_2%
if defined town_message (
    echo %ESC%[63;28H%ESC%[0K%ESC%[92m%town_message%%ESC%[0m
)
if not defined town_message (
    echo %ESC%[63;28H%ESC%[0K%ESC%[90m移動先か調査対象を選んでください。%ESC%[0m
)
exit /b 0

:DrawActionList
call set "label_w=%%NODE_%chapter01_town_node%_W_LABEL%%"
call set "label_a=%%NODE_%chapter01_town_node%_A_LABEL%%"
call set "label_s=%%NODE_%chapter01_town_node%_S_LABEL%%"
call set "label_d=%%NODE_%chapter01_town_node%_D_LABEL%%"
call set "label_e=%%NODE_%chapter01_town_node%_E_LABEL%%"
echo %ESC%[59;154H%ESC%[96mW%ESC%[0m %label_w%
if /i "%DEBUG_STATE%"=="1" echo %ESC%[58;154H%ESC%[95mI%ESC%[0m デバッグ付与
echo %ESC%[60;154H%ESC%[96mA%ESC%[0m %label_a%
echo %ESC%[61;154H%ESC%[96mS%ESC%[0m %label_s%
echo %ESC%[62;154H%ESC%[96mD%ESC%[0m %label_d%
echo %ESC%[63;154H%ESC%[96mF%ESC%[0m %label_e%
echo %ESC%[64;154H%ESC%[96mE%ESC%[0m インベントリを開く
exit /b 0

:DefineNodes
set "NODE_Town01_HomeFront_BG=Chapter01_Town_01_HomeFront.png"
set "NODE_Town01_HomeFront_LOCATION=王都エリュシオン - 自宅前"
set "NODE_Town01_HomeFront_TITLE=家の前"
set "NODE_Town01_HomeFront_DESC1=家を出ると、白い石壁の街並みがゆるやかな坂の先まで続いていた。"
set "NODE_Town01_HomeFront_DESC2=王都の中心へ続く一日の始まりだ。"
set "NODE_Town01_HomeFront_W=move:Town02_DownhillRoad"
set "NODE_Town01_HomeFront_A=text:左手には自宅の壁と花壇がある。"
set "NODE_Town01_HomeFront_S=text:まだ家の中へ戻る気にはなれない。"
set "NODE_Town01_HomeFront_D=text:右手には静かな住宅の並びが続いている。"
set "NODE_Town01_HomeFront_E=text:玄関先には手入れの行き届いた鉢植えが並んでいる。"
set "NODE_Town01_HomeFront_W_LABEL=坂を下る"
set "NODE_Town01_HomeFront_A_LABEL=左を見る"
set "NODE_Town01_HomeFront_S_LABEL=後ろを見る"
set "NODE_Town01_HomeFront_D_LABEL=右を見る"
set "NODE_Town01_HomeFront_E_LABEL=玄関先を調べる"

set "NODE_Town02_DownhillRoad_BG=Chapter01_Town_02_DownhillRoad.png"
set "NODE_Town02_DownhillRoad_LOCATION=王都エリュシオン - 坂道"
set "NODE_Town02_DownhillRoad_TITLE=坂道の途中"
set "NODE_Town02_DownhillRoad_DESC1=商店街に向かう人の流れが少しずつ増えていく。"
set "NODE_Town02_DownhillRoad_DESC2=ここからは王都の広がりがよく見える。"
set "NODE_Town02_DownhillRoad_W=move:Town03_MarketStreet"
set "NODE_Town02_DownhillRoad_A=text:左手の家々からは朝の生活音が漏れてくる。"
set "NODE_Town02_DownhillRoad_S=move:Town01_HomeFront"
set "NODE_Town02_DownhillRoad_D=text:右手の露店はこれから店開きの準備をしているようだ。"
set "NODE_Town02_DownhillRoad_E=text:行き交う人々の足取りには、王都の朝らしい活気がある。"
set "NODE_Town02_DownhillRoad_W_LABEL=商店街へ進む"
set "NODE_Town02_DownhillRoad_A_LABEL=左を見る"
set "NODE_Town02_DownhillRoad_S_LABEL=家の前へ戻る"
set "NODE_Town02_DownhillRoad_D_LABEL=右を見る"
set "NODE_Town02_DownhillRoad_E_LABEL=通りを調べる"

set "NODE_Town03_MarketStreet_BG=Chapter01_Town_03_MarketStreet.png"
set "NODE_Town03_MarketStreet_LOCATION=王都エリュシオン - 商店街"
set "NODE_Town03_MarketStreet_TITLE=商店街"
set "NODE_Town03_MarketStreet_DESC1=露店と看板が並び、人通りの多い商店街が広がっている。"
set "NODE_Town03_MarketStreet_DESC2=正面には広場、右手には細い路地が伸びている。"
set "NODE_Town03_MarketStreet_W=move:Town04_MainSquare"
set "NODE_Town03_MarketStreet_A=text:左手の店先には果物や日用品が所狭しと並べられている。"
set "NODE_Town03_MarketStreet_S=move:Town02_DownhillRoad"
set "NODE_Town03_MarketStreet_D=move:Town09_BackAlley"
set "NODE_Town03_MarketStreet_E=text:呼び込みの声や値切り交渉の音が絶えない。"
set "NODE_Town03_MarketStreet_W_LABEL=広場へ進む"
set "NODE_Town03_MarketStreet_A_LABEL=左の店並みを見る"
set "NODE_Town03_MarketStreet_S_LABEL=坂道へ戻る"
set "NODE_Town03_MarketStreet_D_LABEL=路地裏へ入る"
set "NODE_Town03_MarketStreet_E_LABEL=商店街を調べる"

set "NODE_Town04_MainSquare_BG=Chapter01_Town_04_MainSquare.png"
set "NODE_Town04_MainSquare_LOCATION=王都エリュシオン - 中央広場"
set "NODE_Town04_MainSquare_TITLE=中央広場"
set "NODE_Town04_MainSquare_DESC1=噴水を中心に、王都の人々が行き交う広場が開けている。"
set "NODE_Town04_MainSquare_DESC2=ここを起点に酒場や城方面へ向かえそうだ。"
set "NODE_Town04_MainSquare_W=move:Town06_CastleRoad"
set "NODE_Town04_MainSquare_A=move:Town05_TavernFront"
set "NODE_Town04_MainSquare_S=move:Town03_MarketStreet"
set "NODE_Town04_MainSquare_D=move:Town12_SquareFountainView"
set "NODE_Town04_MainSquare_E=text:広場の空気は賑やかだが、どこか上品に整っている。"
set "NODE_Town04_MainSquare_W_LABEL=城方面へ向かう"
set "NODE_Town04_MainSquare_A_LABEL=酒場へ向かう"
set "NODE_Town04_MainSquare_S_LABEL=商店街へ戻る"
set "NODE_Town04_MainSquare_D_LABEL=噴水側を見る"
set "NODE_Town04_MainSquare_E_LABEL=広場を調べる"

set "NODE_Town05_TavernFront_BG=Chapter01_Town_05_TavernFront.png"
set "NODE_Town05_TavernFront_LOCATION=王都エリュシオン - 酒場前"
set "NODE_Town05_TavernFront_TITLE=酒場の前"
set "NODE_Town05_TavernFront_DESC1=木製の看板と開け放たれた扉が、客を気軽に迎え入れている。"
set "NODE_Town05_TavernFront_DESC2=昼間から賑わっているらしく、中からざわめきが聞こえる。"
set "NODE_Town05_TavernFront_W=text:店の奥へ進むには、まず中に入る必要がある。"
set "NODE_Town05_TavernFront_A=text:通りに面した樽や看板が目を引く。"
set "NODE_Town05_TavernFront_S=move:Town04_MainSquare"
set "NODE_Town05_TavernFront_D=move:Town04_MainSquare"
set "NODE_Town05_TavernFront_E=move:Town08_TavernInterior"
set "NODE_Town05_TavernFront_W_LABEL=奥を見る"
set "NODE_Town05_TavernFront_A_LABEL=店先を見る"
set "NODE_Town05_TavernFront_S_LABEL=広場へ戻る"
set "NODE_Town05_TavernFront_D_LABEL=広場へ戻る"
set "NODE_Town05_TavernFront_E_LABEL=酒場に入る"

set "NODE_Town06_CastleRoad_BG=Chapter01_Town_06_CastleRoad.png"
set "NODE_Town06_CastleRoad_LOCATION=王都エリュシオン - 城へ向かう道"
set "NODE_Town06_CastleRoad_TITLE=城へ向かう道"
set "NODE_Town06_CastleRoad_DESC1=大通りの先には、城へ続く大階段がまっすぐ伸びている。"
set "NODE_Town06_CastleRoad_DESC2=左へ折れれば士官学校の方角だ。"
set "NODE_Town06_CastleRoad_W=move:Town10_CastleApproach"
set "NODE_Town06_CastleRoad_A=move:Town07_AcademyGate"
set "NODE_Town06_CastleRoad_S=move:Town04_MainSquare"
set "NODE_Town06_CastleRoad_D=text:右手には整った建物と商いの気配が続く。"
set "NODE_Town06_CastleRoad_E=text:城へ向かう人々の歩調は自然と引き締まって見える。"
set "NODE_Town06_CastleRoad_W_LABEL=階段の方へ進む"
set "NODE_Town06_CastleRoad_A_LABEL=士官学校へ向かう"
set "NODE_Town06_CastleRoad_S_LABEL=広場へ戻る"
set "NODE_Town06_CastleRoad_D_LABEL=右を見る"
set "NODE_Town06_CastleRoad_E_LABEL=道を調べる"

set "NODE_Town07_AcademyGate_BG=Chapter01_Town_07_AcademyGate.png"
set "NODE_Town07_AcademyGate_LOCATION=王都エリュシオン - 士官学校門前"
set "NODE_Town07_AcademyGate_TITLE=士官学校門前"
set "NODE_Town07_AcademyGate_DESC1=重厚な門の先に、士官学校の建物が堂々と構えている。"
set "NODE_Town07_AcademyGate_DESC2=門衛の姿も見え、学院の規律がそのまま空気になっていた。"
set "NODE_Town07_AcademyGate_W=text:正面玄関に近づくなら、そのまま中へ入るのが早い。"
set "NODE_Town07_AcademyGate_A=text:門柱に掲げられた校章がよく見える。"
set "NODE_Town07_AcademyGate_S=move:Town06_CastleRoad"
set "NODE_Town07_AcademyGate_D=move:Town06_CastleRoad"
set "NODE_Town07_AcademyGate_E=move:Town11_AcademyLobby"
set "NODE_Town07_AcademyGate_W_LABEL=正面を見る"
set "NODE_Town07_AcademyGate_A_LABEL=門柱を見る"
set "NODE_Town07_AcademyGate_S_LABEL=城への道へ戻る"
set "NODE_Town07_AcademyGate_D_LABEL=城への道へ戻る"
set "NODE_Town07_AcademyGate_E_LABEL=中へ入る"

set "NODE_Town08_TavernInterior_BG=Chapter01_Town_08_TavernInterior.png"
set "NODE_Town08_TavernInterior_LOCATION=王都エリュシオン - 酒場"
set "NODE_Town08_TavernInterior_TITLE=酒場の店内"
set "NODE_Town08_TavernInterior_DESC1=木の香りと食器の触れ合う音が、店の賑わいを心地よく包んでいる。"
set "NODE_Town08_TavernInterior_DESC2=中央のカウンターには店主が立ち、左右の卓では客が談笑していた。"
set "NODE_Town08_TavernInterior_W=text:店主のいるカウンターがまっすぐ正面に見える。"
set "NODE_Town08_TavernInterior_A=text:左の卓では常連客らしき人々が静かに飲んでいる。"
set "NODE_Town08_TavernInterior_S=move:Town05_TavernFront"
set "NODE_Town08_TavernInterior_D=text:右の卓では何やら景気のいい笑い声が上がっている。"
set "NODE_Town08_TavernInterior_E=text:店主に声をかければ、何か王都の話が聞けるかもしれない。"
set "NODE_Town08_TavernInterior_W_LABEL=カウンターを見る"
set "NODE_Town08_TavernInterior_A_LABEL=左の客席を見る"
set "NODE_Town08_TavernInterior_S_LABEL=外へ出る"
set "NODE_Town08_TavernInterior_D_LABEL=右の客席を見る"
set "NODE_Town08_TavernInterior_E_LABEL=店主を調べる"

set "NODE_Town09_BackAlley_BG=Chapter01_Town_09_BackAlley.png"
set "NODE_Town09_BackAlley_LOCATION=王都エリュシオン - 路地裏"
set "NODE_Town09_BackAlley_TITLE=路地裏"
set "NODE_Town09_BackAlley_DESC1=表通りの喧騒が遠のき、湿った石畳と古い扉だけが残る。"
set "NODE_Town09_BackAlley_DESC2=貼り紙や木箱が多く、人目につかない話が交わされてもおかしくない。"
set "NODE_Town09_BackAlley_W=text:奥へ行けば、さらに人通りの少ない区画へ入れそうだ。"
set "NODE_Town09_BackAlley_A=text:左の壁には古い貼り紙が幾重にも重なっている。"
set "NODE_Town09_BackAlley_S=move:Town03_MarketStreet"
set "NODE_Town09_BackAlley_D=text:右手の扉は固く閉ざされている。"
set "NODE_Town09_BackAlley_E=text:誰かの視線があった気もするが、気のせいかもしれない。"
set "NODE_Town09_BackAlley_W_LABEL=奥を見る"
set "NODE_Town09_BackAlley_A_LABEL=貼り紙を見る"
set "NODE_Town09_BackAlley_S_LABEL=商店街へ戻る"
set "NODE_Town09_BackAlley_D_LABEL=右の扉を見る"
set "NODE_Town09_BackAlley_E_LABEL=周囲を探る"

set "NODE_Town10_CastleApproach_BG=Chapter01_Town_10_CastleApproach.png"
set "NODE_Town10_CastleApproach_LOCATION=王都エリュシオン - 城前階段"
set "NODE_Town10_CastleApproach_TITLE=城に近づいた"
set "NODE_Town10_CastleApproach_DESC1=大階段の先に城がそびえ、街全体を見下ろしている。"
set "NODE_Town10_CastleApproach_DESC2=現状の実装では、ここが城方面ルートの仮終点だ。"
set "NODE_Town10_CastleApproach_W=finish:城方面の続きは次の実装で接続する。"
set "NODE_Town10_CastleApproach_A=text:左手にも衛兵の姿があり、この先の警備の厳しさが分かる。"
set "NODE_Town10_CastleApproach_S=move:Town06_CastleRoad"
set "NODE_Town10_CastleApproach_D=text:右手の建物にも城勤めらしき人影が見える。"
set "NODE_Town10_CastleApproach_E=finish:城方面の続きは次の実装で接続する。"
set "NODE_Town10_CastleApproach_W_LABEL=さらに進む"
set "NODE_Town10_CastleApproach_A_LABEL=左を見る"
set "NODE_Town10_CastleApproach_S_LABEL=城への道へ戻る"
set "NODE_Town10_CastleApproach_D_LABEL=右を見る"
set "NODE_Town10_CastleApproach_E_LABEL=先へ進む"

set "NODE_Town11_AcademyLobby_BG=Chapter01_Town_11_AcademyLobby.png"
set "NODE_Town11_AcademyLobby_LOCATION=王都エリュシオン - 士官学校ロビー"
set "NODE_Town11_AcademyLobby_TITLE=士官学校ロビー"
set "NODE_Town11_AcademyLobby_DESC1=磨き上げられた床と掲示板、制服姿の生徒たちが学院の気風を物語っている。"
set "NODE_Town11_AcademyLobby_DESC2=この先は学院内部の導線へ広げられそうだ。"
set "NODE_Town11_AcademyLobby_W=text:学院内部の続きは次のシーン追加でつなげられる。"
set "NODE_Town11_AcademyLobby_A=text:掲示板には講義予定や通達が整然と並んでいる。"
set "NODE_Town11_AcademyLobby_S=move:Town07_AcademyGate"
set "NODE_Town11_AcademyLobby_D=text:生徒たちは慣れた様子で資料を見比べている。"
set "NODE_Town11_AcademyLobby_E=text:今はロビーの雰囲気を確かめるだけに留めておこう。"
set "NODE_Town11_AcademyLobby_W_LABEL=奥を見る"
set "NODE_Town11_AcademyLobby_A_LABEL=掲示板を見る"
set "NODE_Town11_AcademyLobby_S_LABEL=門前へ戻る"
set "NODE_Town11_AcademyLobby_D_LABEL=生徒を見る"
set "NODE_Town11_AcademyLobby_E_LABEL=周囲を調べる"

set "NODE_Town12_SquareFountainView_BG=Chapter01_Town_12_SquareFountainView.png"
set "NODE_Town12_SquareFountainView_LOCATION=王都エリュシオン - 中央広場"
set "NODE_Town12_SquareFountainView_TITLE=広場の別視点"
set "NODE_Town12_SquareFountainView_DESC1=噴水とベンチが手前に見え、広場を行き交う人の流れがよく分かる。"
set "NODE_Town12_SquareFountainView_DESC2=滞在して人の様子を眺めるなら、この視点の方が向いている。"
set "NODE_Town12_SquareFountainView_W=text:噴水のそばまで寄れば、もっと人々の会話が聞こえそうだ。"
set "NODE_Town12_SquareFountainView_A=move:Town04_MainSquare"
set "NODE_Town12_SquareFountainView_S=move:Town04_MainSquare"
set "NODE_Town12_SquareFountainView_D=text:露店側には食べ物や日用品の店が並んでいる。"
set "NODE_Town12_SquareFountainView_E=text:ベンチに腰かければ、広場全体をゆっくり見渡せそうだ。"
set "NODE_Town12_SquareFountainView_W_LABEL=噴水へ寄る"
set "NODE_Town12_SquareFountainView_A_LABEL=広場中央へ戻る"
set "NODE_Town12_SquareFountainView_S_LABEL=広場中央へ戻る"
set "NODE_Town12_SquareFountainView_D_LABEL=露店側を見る"
set "NODE_Town12_SquareFountainView_E_LABEL=周囲を調べる"
exit /b 0
