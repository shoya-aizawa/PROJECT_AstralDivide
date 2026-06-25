@echo off
setlocal EnableExtensions EnableDelayedExpansion

if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not defined tools_dir set "tools_dir=%PROJECT_ROOT%\Tools"
if not defined src_display_dir set "src_display_dir=%PROJECT_ROOT%\Src\Systems\Display"
if not defined src_inventory_dir set "src_inventory_dir=%PROJECT_ROOT%\Src\Systems\Inventory"
if not defined player_money set "player_money=0"

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

call "%src_inventory_dir%\InventoryCore.bat" INIT_DEFAULTS
set "field_menu_map_item_id=key_town_map_chapter01"
if defined current_chapter if /i "%current_chapter%"=="Chapter01" set "field_menu_map_item_id=key_town_map_chapter01"

set "field_menu_left=26"
set "field_menu_top=10"
set "field_menu_mid=59"
set "field_menu_right=126"
set "field_menu_bottom=29"
set "field_menu_fill=                                                                                                                        "
set "field_menu_list_fill=                              "
set "field_menu_detail_fill=                                                               "
set "field_menu_message=項目を選択してください。"
set "field_menu_selected=1"

call :DefineEntries
call "%tools_dir%\cmdwiz.exe" flushkeys >nul 2>&1

:MenuLoop
call :RefreshDynamicState
call :RenderMenu
call :PollFieldMenuKey

if "%field_menu_pick%"=="CLOSE" goto :MenuExit
if "%field_menu_pick%"=="PREV" (
    set /a "field_menu_selected-=1"
    if !field_menu_selected! LSS 1 set "field_menu_selected=%field_menu_count%"
    goto :MenuLoop
)
if "%field_menu_pick%"=="NEXT" (
    set /a "field_menu_selected+=1"
    if !field_menu_selected! GTR %field_menu_count% set "field_menu_selected=1"
    goto :MenuLoop
)
if "%field_menu_pick%"=="OPEN_INVENTORY" (
    call :OpenInventoryOverlay
    set "field_menu_message=所持品を確認した。"
    goto :MenuLoop
)
if "%field_menu_pick%"=="ACTION" (
    call :ExecuteSelected
    goto :MenuLoop
)
goto :MenuLoop

:MenuExit
endlocal
exit /b 0

:DefineEntries
set "field_menu_count=8"

set "field_menu_1_id=STATUS"
set "field_menu_1_label=ステータス"
set "field_menu_1_state=INFO"
set "field_menu_1_summary=主人公や仲間の状態を確認"
set "field_menu_1_desc1=レベル、所持金、進行状況の要約を表示します。"
set "field_menu_1_desc2=詳細画面は将来接続予定です。"
set "field_menu_1_action=INFO"

set "field_menu_2_id=QUEST"
set "field_menu_2_label=クエスト"
set "field_menu_2_state=WIP"
set "field_menu_2_summary=受注・追跡・ピン止め"
set "field_menu_2_desc1=クエスト一覧と進捗表示の器です。"
set "field_menu_2_desc2=初版ではまだ画面未接続です。"
set "field_menu_2_action=WIP"

set "field_menu_3_id=INVENTORY"
set "field_menu_3_label=インベントリ"
set "field_menu_3_state=READY"
set "field_menu_3_summary=所持品一覧を開く"
set "field_menu_3_desc1=既存の InventoryMenu を右側配置で開きます。"
set "field_menu_3_desc2=I キーでも直接開けます。"
set "field_menu_3_action=INVENTORY"

set "field_menu_4_id=MAGIC"
set "field_menu_4_label=魔法術"
set "field_menu_4_state=WIP"
set "field_menu_4_summary=MAGIC セットと管理"
set "field_menu_4_desc1=装備枠や使用先を後で接続する予定です。"
set "field_menu_4_desc2=今はメニュー枠のみ確保します。"
set "field_menu_4_action=WIP"

set "field_menu_5_id=ASTRAL"
set "field_menu_5_label=星霊術"
set "field_menu_5_state=LOCKED"
set "field_menu_5_summary=セレノス系の固有術式"
set "field_menu_5_desc1=ストーリー進行で解放される想定です。"
set "field_menu_5_desc2=現段階ではまだ使用できません。"
set "field_menu_5_action=LOCKED"

set "field_menu_6_id=CRAFT"
set "field_menu_6_label=調合,クラフト"
set "field_menu_6_state=WIP"
set "field_menu_6_summary=素材加工と合成"
set "field_menu_6_desc1=インベントリに近い画面構成で接続予定です。"
set "field_menu_6_desc2=合成結果プレビューは未実装です。"
set "field_menu_6_action=WIP"

set "field_menu_7_id=MAP"
set "field_menu_7_label=マップ"
set "field_menu_7_state=LOCKED"
set "field_menu_7_summary=所持中の地図を確認"
set "field_menu_7_desc1=地図アイテムを所持すると開ける想定です。"
set "field_menu_7_desc2=現状は未解放です。"
set "field_menu_7_action=LOCKED"

set "field_menu_8_id=LORE"
set "field_menu_8_label=知識"
set "field_menu_8_state=WIP"
set "field_menu_8_summary=LOR や会話由来の知識を蓄積"
set "field_menu_8_desc1=図鑑・知識帳として後で拡張します。"
set "field_menu_8_desc2=今は所持 LOR 件数だけ要約します。"
set "field_menu_8_action=WIP"
exit /b 0

:RefreshDynamicState
set /a "field_menu_total_item_kinds=inventory_stack_count + inventory_unique_count"
set /a "field_menu_lor_count=0"
for /l %%I in (1,1,%inventory_stack_count%) do (
    set "entry_item_id="
    for /f "tokens=1 delims=," %%A in ("!inventory_stack_%%I!") do set "entry_item_id=%%A"
    if defined entry_item_id (
        call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "!entry_item_id!" "field_menu_item_"
        if /i "!field_menu_item_category!"=="LOR" set /a "field_menu_lor_count+=1"
    )
)
for /l %%I in (1,1,%inventory_unique_count%) do (
    set "entry_item_id=!inventory_unique_%%I!"
    if defined entry_item_id (
        call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "!entry_item_id!" "field_menu_item_"
        if /i "!field_menu_item_category!"=="LOR" set /a "field_menu_lor_count+=1"
    )
)

set "field_menu_1_runtime1=名前  : %player_name%"
if not defined player_name set "field_menu_1_runtime1=名前  : シオン"
set "field_menu_1_runtime2=Lv    : %player_level%   所持金: %player_money%G"
if not defined player_level set "field_menu_1_runtime2=Lv    : 0   所持金: %player_money%G"

set "field_menu_2_runtime1=現在の受注一覧は未接続です。"
if "%chapter01_quest_tavern_intro%"=="1" (
    set "field_menu_2_runtime2=Chapter1 酒場導線フラグ: 進行中"
) else (
    set "field_menu_2_runtime2=Chapter1 酒場導線フラグ: 未到達"
)

set "field_menu_3_runtime1=所持種類: %field_menu_total_item_kinds%"
set "field_menu_3_runtime2=F / Enter でインベントリを開く"

set "field_menu_4_runtime1=魔法術の管理画面は WIP です。"
set "field_menu_4_runtime2=将来の戦闘・装備導線に接続予定"

set "field_menu_5_runtime1=星霊術は未解放です。"
set "field_menu_5_runtime2=進行で SP 系上位術式も解放予定"

set "field_menu_6_runtime1=調合とクラフトは WIP です。"
set "field_menu_6_runtime2=素材加工画面を後で接続予定"

set "field_menu_map_owned=0"
call :HasInventoryItem "%field_menu_map_item_id%" field_menu_map_owned
if "%field_menu_map_owned%"=="1" (
    set "field_menu_7_state=READY"
    set "field_menu_7_action=MAP"
    set "field_menu_7_runtime1=地図アイテムを所持しています。"
    set "field_menu_7_runtime2=画面接続は次段階で実装予定"
    set "field_menu_7_desc2=地図画面そのものはまだ未実装です。"
)
if not "%field_menu_map_owned%"=="1" (
    set "field_menu_7_state=LOCKED"
    set "field_menu_7_action=LOCKED"
    set "field_menu_7_runtime1=地図アイテム未所持"
    set "field_menu_7_runtime2=所持後に開ける設計です"
)

set "field_menu_8_runtime1=LOR 所持件数: %field_menu_lor_count%"
set "field_menu_8_runtime2=知識帳画面は WIP です"
exit /b 0

:HasInventoryItem
set "%~2=0"
if "%~1"=="" exit /b 0
for /l %%I in (1,1,%inventory_stack_count%) do (
    for /f "tokens=1 delims=," %%A in ("!inventory_stack_%%I!") do (
        if /i "%%A"=="%~1" set "%~2=1"
    )
)
for /l %%I in (1,1,%inventory_unique_count%) do (
    if /i "!inventory_unique_%%I!"=="%~1" set "%~2=1"
)
exit /b 0

:RenderMenu
call :DrawPanels
call :DrawMenuList
call :DrawDetailPane
call :DrawFooter
exit /b 0

:DrawPanels
setlocal EnableDelayedExpansion
set /a "menu_inner=field_menu_mid-field_menu_left-1"
set /a "detail_inner=field_menu_right-field_menu_mid-1"
set /a "panel_inner_top=field_menu_top+1"
set /a "panel_inner_bottom=field_menu_bottom-1"
set /a "field_menu_title_col=field_menu_left+4"
set /a "field_menu_detail_title_col=field_menu_mid+4"
set "menu_rule="
set "detail_rule="
for /l %%I in (1,1,!menu_inner!) do set "menu_rule=!menu_rule!─"
for /l %%I in (1,1,!detail_inner!) do set "detail_rule=!detail_rule!─"
echo !ESC![!field_menu_top!;!field_menu_left!H!ESC![97m┌!menu_rule!┬!detail_rule!┐!ESC![0m
for /l %%R in (!panel_inner_top!,1,!panel_inner_bottom!) do (
    echo !ESC![%%R;!field_menu_left!H!ESC![97m│!ESC![0m!ESC![%%R;!field_menu_mid!H!ESC![97m│!ESC![0m!ESC![%%R;!field_menu_right!H!ESC![97m│!ESC![0m
)
echo !ESC![!field_menu_bottom!;!field_menu_left!H!ESC![97m└!menu_rule!┴!detail_rule!┘!ESC![0m
echo !ESC![!field_menu_top!;!field_menu_title_col!H!ESC![96mFieldMenu!ESC![0m
echo !ESC![!field_menu_top!;!field_menu_detail_title_col!H!ESC![96m選択項目!ESC![0m
endlocal
exit /b 0

:DrawMenuList
setlocal EnableDelayedExpansion
for /l %%R in (11,1,27) do echo !ESC![%%R;28H!ESC![97m!field_menu_list_fill!!ESC![0m
for /l %%I in (1,1,%field_menu_count%) do (
    set /a "row=11+%%I"
    call set "entry_label=%%field_menu_%%I_label%%"
    call set "entry_state=%%field_menu_%%I_state%%"
    set "state_color=90"
    if /i "!entry_state!"=="READY" set "state_color=92"
    if /i "!entry_state!"=="INFO" set "state_color=96"
    if /i "!entry_state!"=="WIP" set "state_color=93"
    if /i "!entry_state!"=="LOCKED" set "state_color=90"
    if "%%I"=="%field_menu_selected%" (
        echo !ESC![!row!;28H!ESC![30;103m ^> !entry_label! !ESC![0m !ESC![!state_color!m[!entry_state!]!ESC![0m
    ) else (
        echo !ESC![!row!;28H!ESC![97m   !entry_label!!ESC![0m !ESC![!state_color!m[!entry_state!]!ESC![0m
    )
)
endlocal
exit /b 0

:DrawDetailPane
setlocal EnableDelayedExpansion
call set "entry_label=%%field_menu_%field_menu_selected%_label%%"
call set "entry_summary=%%field_menu_%field_menu_selected%_summary%%"
call set "entry_desc1=%%field_menu_%field_menu_selected%_desc1%%"
call set "entry_desc2=%%field_menu_%field_menu_selected%_desc2%%"
call set "entry_state=%%field_menu_%field_menu_selected%_state%%"
call set "entry_runtime1=%%field_menu_%field_menu_selected%_runtime1%%"
call set "entry_runtime2=%%field_menu_%field_menu_selected%_runtime2%%"
for /l %%R in (11,1,27) do echo !ESC![%%R;62H!ESC![97m!field_menu_detail_fill!!ESC![0m
echo !ESC![12;62H!ESC![93m!entry_label!!ESC![0m
echo !ESC![14;62H!ESC![97m概要  : !entry_summary!!ESC![0m
echo !ESC![15;62H!ESC![97m状態  : !entry_state!!ESC![0m
echo !ESC![17;62H!ESC![97m!entry_desc1!!ESC![0m
echo !ESC![18;62H!ESC![97m!entry_desc2!!ESC![0m
echo !ESC![21;62H!ESC![90m現在の情報!ESC![0m
echo !ESC![22;62H!ESC![97m!entry_runtime1!!ESC![0m
echo !ESC![23;62H!ESC![97m!entry_runtime2!!ESC![0m
echo !ESC![26;62H!ESC![90mF / Enter: 実行   E / Q / Esc: 閉じる   I: 所持品!ESC![0m
endlocal
exit /b 0

:DrawFooter
echo %ESC%[30;28H%ESC%[90m現在地:%ESC%[0m %current_location%
echo %ESC%[31;28H%ESC%[90mW/S%ESC%[0m 項目選択   %ESC%[90mF%ESC%[0m 実行   %ESC%[90mI%ESC%[0m 所持品   %ESC%[90mE/Q/Esc%ESC%[0m 閉じる
echo %ESC%[32;28H%ESC%[0K%ESC%[92m%field_menu_message%%ESC%[0m
exit /b 0

:PollFieldMenuKey
set "field_menu_pick=NONE"
:PollFieldMenuLoop
"%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "scan_code=%errorlevel%"
if "%scan_code%"=="0" (
    "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :PollFieldMenuLoop
)
if "%scan_code%"=="87" set "field_menu_pick=PREV"
if "%scan_code%"=="119" set "field_menu_pick=PREV"
if "%scan_code%"=="83" set "field_menu_pick=NEXT"
if "%scan_code%"=="115" set "field_menu_pick=NEXT"
if "%scan_code%"=="70" set "field_menu_pick=ACTION"
if "%scan_code%"=="102" set "field_menu_pick=ACTION"
if "%scan_code%"=="13" set "field_menu_pick=ACTION"
if "%scan_code%"=="28" set "field_menu_pick=ACTION"
if "%scan_code%"=="73" set "field_menu_pick=OPEN_INVENTORY"
if "%scan_code%"=="105" set "field_menu_pick=OPEN_INVENTORY"
if "%scan_code%"=="69" set "field_menu_pick=CLOSE"
if "%scan_code%"=="101" set "field_menu_pick=CLOSE"
if "%scan_code%"=="81" set "field_menu_pick=CLOSE"
if "%scan_code%"=="113" set "field_menu_pick=CLOSE"
if "%scan_code%"=="27" set "field_menu_pick=CLOSE"
exit /b 0

:ExecuteSelected
call set "selected_action=%%field_menu_%field_menu_selected%_action%%"
call set "selected_label=%%field_menu_%field_menu_selected%_label%%"
if /i "%selected_action%"=="INVENTORY" (
    call :OpenInventoryOverlay
    set "field_menu_message=所持品を確認した。"
    exit /b 0
)
if /i "%selected_action%"=="MAP" (
    set "field_menu_message=%selected_label% は次の段階で画面接続します。"
    exit /b 0
)
if /i "%selected_action%"=="INFO" (
    set "field_menu_message=%selected_label% の詳細画面は将来接続予定です。"
    exit /b 0
)
if /i "%selected_action%"=="WIP" (
    set "field_menu_message=%selected_label% はまだ WIP です。"
    exit /b 0
)
if /i "%selected_action%"=="LOCKED" (
    set "field_menu_message=%selected_label% はまだ利用できません。"
    exit /b 0
)
set "field_menu_message=%selected_label% はまだ接続されていません。"
exit /b 0

:OpenInventoryOverlay
set "INVENTORY_MENU_LEFT=82"
set "INVENTORY_MENU_TOP=8"
set "INVENTORY_MENU_RIGHT=208"
set "INVENTORY_MENU_BOTTOM=39"
set "INVENTORY_MENU_MID=133"
call "%src_inventory_dir%\InventoryMenu.bat"
set "INVENTORY_MENU_LEFT="
set "INVENTORY_MENU_TOP="
set "INVENTORY_MENU_RIGHT="
set "INVENTORY_MENU_BOTTOM="
set "INVENTORY_MENU_MID="
call "%tools_dir%\cmdwiz.exe" flushkeys >nul 2>&1
exit /b 0
