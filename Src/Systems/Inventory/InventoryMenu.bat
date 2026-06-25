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
if not defined src_inventory_dir set "src_inventory_dir=%PROJECT_ROOT%\Src\Systems\Inventory"
if not defined player_money set "player_money=0"

call "%src_inventory_dir%\InventoryCore.bat" INIT_DEFAULTS

set "tab_count=9"
set "tab_1=ALL"
set "tab_2=WPN"
set "tab_3=ARM"
set "tab_4=ACC"
set "tab_5=USE"
set "tab_6=MAT"
set "tab_7=SOC"
set "tab_8=KEY"
set "tab_9=LOR"

set "inventory_tab_index=1"
set "inventory_selected=1"
set "inventory_view_mode=LIST"
set "inventory_message=カテゴリを選択してください。"

if defined INVENTORY_MENU_LEFT (set "overlay_left=%INVENTORY_MENU_LEFT%") else set "overlay_left=16"
if defined INVENTORY_MENU_TOP (set "overlay_top=%INVENTORY_MENU_TOP%") else set "overlay_top=7"
if defined INVENTORY_MENU_RIGHT (set "overlay_right=%INVENTORY_MENU_RIGHT%") else set "overlay_right=142"
if defined INVENTORY_MENU_BOTTOM (set "overlay_bottom=%INVENTORY_MENU_BOTTOM%") else set "overlay_bottom=38"
if defined INVENTORY_MENU_MID (set "overlay_mid=%INVENTORY_MENU_MID%") else set "overlay_mid=67"
set /a "inventory_dx=overlay_left-16"
set /a "inventory_dy=overlay_top-7"
set "overlay_fill=                                                                                                                                                                                                                                                                "
set "pane_fill_left=                                              "
set "pane_fill_right=                                                          "
set "footer_fill=                                        "

call :BuildVisibleEntries
call :RenderInventoryOverlayStatic

:MenuLoop
call :BuildVisibleEntries
call :RenderInventoryOverlayDynamic
call :PollInventoryKey

if "%inventory_pick%"=="CLOSE" goto :MenuExit
if "%inventory_pick%"=="TAB_LEFT" (
    set /a "inventory_tab_index-=1"
    if !inventory_tab_index! LSS 1 set "inventory_tab_index=%tab_count%"
    set "inventory_selected=1"
    goto :MenuLoop
)
if "%inventory_pick%"=="TAB_RIGHT" (
    set /a "inventory_tab_index+=1"
    if !inventory_tab_index! GTR %tab_count% set "inventory_tab_index=1"
    set "inventory_selected=1"
    goto :MenuLoop
)
if "%inventory_pick%"=="PREV" (
    set /a "inventory_selected-=1"
    if !inventory_selected! LSS 1 set "inventory_selected=%visible_count%"
    if "%visible_count%"=="0" set "inventory_selected=1"
    goto :MenuLoop
)
if "%inventory_pick%"=="NEXT" (
    set /a "inventory_selected+=1"
    if !inventory_selected! GTR %visible_count% set "inventory_selected=1"
    if "%visible_count%"=="0" set "inventory_selected=1"
    goto :MenuLoop
)
if "%inventory_pick%"=="TOGGLE_VIEW" (
    if "%inventory_view_mode%"=="LIST" (
        set "inventory_view_mode=GRID"
        set "inventory_message=現在: グリッド表示"
    ) else (
        set "inventory_view_mode=LIST"
        set "inventory_message=現在: 一覧表示"
    )
    goto :MenuLoop
)
if "%inventory_pick%"=="ACTION" (
    if "%visible_count%"=="0" (
        set "inventory_message=対象がありません。"
    ) else if /i "%selected_entry_equipable%"=="1" (
        set "inventory_message=装備処理はまだ未実装です。"
    ) else (
        set "inventory_message=このアイテムには現在アクションがありません。"
    )
    goto :MenuLoop
)
goto :MenuLoop

:MenuExit
call :ClearInventoryOverlay
endlocal
exit /b 0

:BuildVisibleEntries
set "visible_count=0"
call set "active_category=%%tab_%inventory_tab_index%%%"

for /l %%I in (1,1,%inventory_stack_count%) do (
    set "entry_item_id="
    set "entry_count="
    for /f "tokens=1,2 delims=," %%A in ("!inventory_stack_%%I!") do (
        set "entry_item_id=%%A"
        set "entry_count=%%B"
    )
    if defined entry_item_id (
        call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "!entry_item_id!" "entry_"
        if "!active_category!"=="ALL" (
            call :AppendVisibleEntry "!entry_item_id!" "!entry_count!"
        ) else if /i "!entry_category!"=="!active_category!" (
            call :AppendVisibleEntry "!entry_item_id!" "!entry_count!"
        )
    )
)

for /l %%I in (1,1,%inventory_unique_count%) do (
    set "entry_item_id=!inventory_unique_%%I!"
    if defined entry_item_id (
        call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "!entry_item_id!" "entry_"
        if "!active_category!"=="ALL" (
            call :AppendVisibleEntry "!entry_item_id!" "1"
        ) else if /i "!entry_category!"=="!active_category!" (
            call :AppendVisibleEntry "!entry_item_id!" "1"
        )
    )
)

if %visible_count% LEQ 0 (
    set "selected_entry_name=未所持"
    set "selected_entry_icon=."
    set "selected_entry_category=%active_category%"
    set "selected_entry_description=このカテゴリにはまだ何もありません。"
    set "selected_entry_count=0"
    set "selected_entry_stackable=0"
    set "selected_entry_buy_price=0"
    set "selected_entry_sell_price=0"
    set "selected_entry_equipable=0"
    set "selected_entry_equip_slot="
    set "selected_entry_feature_socket=WIP"
    set "selected_entry_feature_astral_core=WIP"
    set "selected_entry_feature_prefix_suffix=WIP"
    exit /b 0
)

if %inventory_selected% GTR %visible_count% set "inventory_selected=%visible_count%"
if %inventory_selected% LSS 1 set "inventory_selected=1"
call set "selected_entry_name=%%visible_%inventory_selected%_name%%"
call set "selected_entry_icon=%%visible_%inventory_selected%_icon%%"
call set "selected_entry_category=%%visible_%inventory_selected%_category%%"
call set "selected_entry_description=%%visible_%inventory_selected%_description%%"
call set "selected_entry_count=%%visible_%inventory_selected%_count%%"
call set "selected_entry_stackable=%%visible_%inventory_selected%_stackable%%"
call set "selected_entry_buy_price=%%visible_%inventory_selected%_buy_price%%"
call set "selected_entry_sell_price=%%visible_%inventory_selected%_sell_price%%"
call set "selected_entry_equipable=%%visible_%inventory_selected%_equipable%%"
call set "selected_entry_equip_slot=%%visible_%inventory_selected%_equip_slot%%"
call set "selected_entry_feature_socket=%%visible_%inventory_selected%_feature_socket%%"
call set "selected_entry_feature_astral_core=%%visible_%inventory_selected%_feature_astral_core%%"
call set "selected_entry_feature_prefix_suffix=%%visible_%inventory_selected%_feature_prefix_suffix%%"
exit /b 0

:AppendVisibleEntry
set /a "visible_count+=1"
set "visible_%visible_count%_item_id=%~1"
set "visible_%visible_count%_count=%~2"
set "visible_%visible_count%_name=%entry_name%"
set "visible_%visible_count%_icon=%entry_icon%"
set "visible_%visible_count%_category=%entry_category%"
set "visible_%visible_count%_description=%entry_description%"
set "visible_%visible_count%_stackable=%entry_stackable%"
set "visible_%visible_count%_buy_price=%entry_buy_price%"
set "visible_%visible_count%_sell_price=%entry_sell_price%"
set "visible_%visible_count%_equipable=%entry_equipable%"
set "visible_%visible_count%_equip_slot=%entry_equip_slot%"
set "visible_%visible_count%_feature_socket=%entry_feature_socket%"
set "visible_%visible_count%_feature_astral_core=%entry_feature_astral_core%"
set "visible_%visible_count%_feature_prefix_suffix=%entry_feature_prefix_suffix%"
exit /b 0

:RenderInventoryOverlay
call :DrawOverlayFill
call :DrawOverlayFrame
call :RenderInventoryOverlayDynamic
exit /b 0

:RenderInventoryOverlayStatic
call :DrawOverlayFill
call :DrawOverlayFrame
exit /b 0

:RenderInventoryOverlayDynamic
call :DrawTabs
if /i "%inventory_view_mode%"=="GRID" (
    call :DrawGridPane
) else (
    call :DrawListPane
)
call :DrawDetailPane
call :DrawFooter
exit /b 0

:DrawOverlayFill
setlocal EnableDelayedExpansion
set /a "overlay_width=overlay_right-overlay_left+1"
set "fill_line=!overlay_fill:~0,%overlay_width%!"
for /l %%R in (%overlay_top%,1,%overlay_bottom%) do (
    echo !ESC![%%R;%overlay_left%H!ESC![48;5;233m!fill_line!!ESC![0m
)
endlocal
exit /b 0

:DrawOverlayFrame
setlocal EnableDelayedExpansion
set /a "left_inner=overlay_mid-overlay_left-1"
set /a "right_inner=overlay_right-overlay_mid-1"
set /a "frame_inner_top=overlay_top+1"
set /a "frame_inner_bottom=overlay_bottom-1"
set "left_rule="
set "right_rule="
for /l %%I in (1,1,!left_inner!) do set "left_rule=!left_rule!─"
for /l %%I in (1,1,!right_inner!) do set "right_rule=!right_rule!─"
echo !ESC![%overlay_top%;%overlay_left%H!ESC![97m┌!left_rule!┬!right_rule!┐!ESC![0m
for /l %%R in (!frame_inner_top!,1,!frame_inner_bottom!) do (
    echo %ESC%[%%R;%overlay_left%H%ESC%[97m│%ESC%[0m%ESC%[%%R;%overlay_mid%H%ESC%[97m│%ESC%[0m%ESC%[%%R;%overlay_right%H%ESC%[97m│%ESC%[0m
)
echo !ESC![%overlay_bottom%;%overlay_left%H!ESC![97m└!left_rule!┴!right_rule!┘!ESC![0m
set /a "title_row=7+inventory_dy"
set /a "title_col_left=28+inventory_dx"
set /a "title_col_right=88+inventory_dx"
echo !ESC![!title_row!;!title_col_left!H!ESC![96m所持品!ESC![0m
echo !ESC![!title_row!;!title_col_right!H!ESC![96m説明!ESC![0m
endlocal
exit /b 0

:ClearInventoryOverlay
setlocal EnableDelayedExpansion
set /a "overlay_width=overlay_right-overlay_left+1"
set "clear_line=!overlay_fill:~0,%overlay_width%!"
for /l %%R in (%overlay_top%,1,%overlay_bottom%) do (
    echo !ESC![%%R;%overlay_left%H!ESC![0m!clear_line!
)
endlocal
exit /b 0

:DrawTabs
setlocal EnableDelayedExpansion
set /a "tab_row=9+inventory_dy"
set /a "tab_col=20+inventory_dx"
for /l %%I in (1,1,%tab_count%) do (
    call set "tab_name=%%tab_%%I%%"
    if "%%I"=="%inventory_tab_index%" (
        <nul set /p="!ESC![!tab_row!;!tab_col!H!ESC![30;103m !tab_name! !ESC![0m"
    ) else (
        <nul set /p="!ESC![!tab_row!;!tab_col!H!ESC![37m !tab_name! !ESC![0m"
    )
    set /a "tab_col+=5"
)
echo.
endlocal
exit /b 0

:DrawListPane
set /a "header_row=11+inventory_dy"
set /a "left_col=20+inventory_dx"
set /a "list_start_row=12+inventory_dy"
set /a "list_max_row=30+inventory_dy"
echo %ESC%[!header_row!;!left_col!H%ESC%[90m%pane_fill_left%%ESC%[0m
echo %ESC%[!header_row!;!left_col!H%ESC%[90m表示: 一覧%ESC%[0m
for /l %%I in (1,1,20) do (
    set /a "row=list_start_row+%%I"
    echo !ESC![!row!;!left_col!H!ESC![90m%pane_fill_left%!ESC![0m
)
if "%visible_count%"=="0" (
    set /a "empty_row=13+inventory_dy"
    echo %ESC%[!empty_row!;!left_col!H%ESC%[90mアイテムはありません。%ESC%[0m
    exit /b 0
)
for /l %%I in (1,1,%visible_count%) do (
    set /a "row=list_start_row+%%I"
    if !row! GTR !list_max_row! goto :ListPaneDone
    call set "entry_name=%%visible_%%I_name%%"
    call set "entry_icon=%%visible_%%I_icon%%"
    call set "entry_count=%%visible_%%I_count%%"
    set "entry_suffix="
    if not "!entry_count!"=="1" set "entry_suffix=x!entry_count!"
    if "%%I"=="%inventory_selected%" (
        echo %ESC%[!row!;!left_col!H%ESC%[30;103m ^> !entry_icon! !entry_name! !entry_suffix! %ESC%[0m
    ) else (
        echo %ESC%[!row!;!left_col!H%ESC%[97m   !entry_icon! !entry_name! !entry_suffix!%ESC%[0m
    )
)
:ListPaneDone
exit /b 0

:DrawGridPane
setlocal EnableDelayedExpansion
set "grid_cols=12"
set /a "header_row=11+inventory_dy"
set /a "left_col=20+inventory_dx"
set /a "grid_start_row=13+inventory_dy"
set /a "grid_start_col=22+inventory_dx"
set /a "grid_max_row=29+inventory_dy"
echo !ESC![!header_row!;!left_col!H!ESC![90m%pane_fill_left%!ESC![0m
echo !ESC![!header_row!;!left_col!H!ESC![90m表示: グリッド!ESC![0m
for /l %%R in (12,1,30) do (
    set /a "draw_row=%%R+inventory_dy"
    echo !ESC![!draw_row!;!left_col!H!ESC![90m%pane_fill_left%!ESC![0m
)
if "%visible_count%"=="0" (
    set /a "empty_row=13+inventory_dy"
    echo !ESC![!empty_row!;!left_col!H!ESC![90mアイテムはありません。!ESC![0m
    endlocal
    exit /b 0
)
for /l %%I in (1,1,%visible_count%) do (
    set /a "grid_index=%%I-1"
    set /a "grid_row=grid_start_row + (grid_index / grid_cols) * 2"
    set /a "grid_col=grid_start_col + (grid_index %% grid_cols) * 3"
    if !grid_row! GTR !grid_max_row! goto :GridDone
    call set "entry_icon=%%visible_%%I_icon%%"
    if "%%I"=="%inventory_selected%" (
        <nul set /p="!ESC![!grid_row!;!grid_col!H!ESC![30;103m !entry_icon! !ESC![0m"
    ) else (
        <nul set /p="!ESC![!grid_row!;!grid_col!H!ESC![97m !entry_icon! !ESC![0m"
    )
)
:GridDone
echo.
endlocal
exit /b 0

:DrawDetailPane
setlocal EnableDelayedExpansion
set /a "detail_col=70+inventory_dx"
set /a "detail_row_1=11+inventory_dy"
set /a "detail_row_3=13+inventory_dy"
set /a "detail_row_4=14+inventory_dy"
set /a "detail_row_5=15+inventory_dy"
set /a "detail_row_7=17+inventory_dy"
set /a "detail_row_8=18+inventory_dy"
set /a "detail_row_10=20+inventory_dy"
set /a "detail_row_11=21+inventory_dy"
set /a "detail_row_12=22+inventory_dy"
set /a "detail_row_14=24+inventory_dy"
set /a "detail_row_15=25+inventory_dy"
set /a "detail_row_18=28+inventory_dy"
set /a "detail_row_19=29+inventory_dy"
set /a "detail_row_20=30+inventory_dy"
for /l %%R in (11,1,36) do (
    set /a "draw_row=%%R+inventory_dy"
    echo !ESC![!draw_row!;!detail_col!H!ESC![90m%pane_fill_right%!ESC![0m
)
echo !ESC![!detail_row_1!;!detail_col!H!ESC![93m!selected_entry_name!!ESC![0m
echo !ESC![!detail_row_3!;!detail_col!H!ESC![97m記号  : !selected_entry_icon!!ESC![0m
echo !ESC![!detail_row_4!;!detail_col!H!ESC![97m分類  : !selected_entry_category!!ESC![0m
if "!selected_entry_equipable!"=="1" (
    echo !ESC![!detail_row_5!;!detail_col!H!ESC![97m装備枠: !selected_entry_equip_slot!!ESC![0m
) else (
    echo !ESC![!detail_row_5!;!detail_col!H!ESC![97m所持数: !selected_entry_count!!ESC![0m
)
echo !ESC![!detail_row_7!;!detail_col!H!ESC![97m購入額: !selected_entry_buy_price!G!ESC![0m
echo !ESC![!detail_row_8!;!detail_col!H!ESC![97m売却額: !selected_entry_sell_price!G!ESC![0m
echo !ESC![!detail_row_10!;!detail_col!H!ESC![97mSocket: !selected_entry_feature_socket!!ESC![0m
echo !ESC![!detail_row_11!;!detail_col!H!ESC![97m星核  : !selected_entry_feature_astral_core!!ESC![0m
echo !ESC![!detail_row_12!;!detail_col!H!ESC![97m補正  : !selected_entry_feature_prefix_suffix!!ESC![0m
echo !ESC![!detail_row_14!;!detail_col!H!ESC![90m説明!ESC![0m
echo !ESC![!detail_row_15!;!detail_col!H!ESC![97m!selected_entry_description!!ESC![0m
echo !ESC![!detail_row_18!;!detail_col!H!ESC![90m所持状況!ESC![0m
echo !ESC![!detail_row_19!;!detail_col!H!ESC![97m件数  : %visible_count%!ESC![0m
echo !ESC![!detail_row_20!;!detail_col!H!ESC![97m所持金: %player_money%G!ESC![0m
endlocal
exit /b 0

:DrawFooter
set /a "footer_col=20+inventory_dx"
set /a "footer_row_1=33+inventory_dy"
set /a "footer_row_2=34+inventory_dy"
set /a "footer_row_3=35+inventory_dy"
set /a "footer_row_4=36+inventory_dy"
echo %ESC%[!footer_row_1!;!footer_col!H%ESC%[90m%footer_fill%%ESC%[0m
echo %ESC%[!footer_row_2!;!footer_col!H%ESC%[96mW/S%ESC%[0m 選択  %ESC%[96mA/D%ESC%[0m カテゴリ  %ESC%[96mG%ESC%[0m 表示切替
echo %ESC%[!footer_row_3!;!footer_col!H%ESC%[96mF%ESC%[0m 装備/WIP  %ESC%[96mQ/E%ESC%[0m 閉じる
echo %ESC%[!footer_row_4!;!footer_col!H%ESC%[90m%footer_fill%%ESC%[0m
echo %ESC%[!footer_row_4!;!footer_col!H%ESC%[90m%inventory_message%%ESC%[0m
exit /b 0

:PollInventoryKey
set "inventory_pick=NONE"
:PollInventoryKeyLoop
"%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "scan_code=%errorlevel%"
if "%scan_code%"=="0" (
    "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :PollInventoryKeyLoop
)
if "%scan_code%"=="65" set "inventory_pick=TAB_LEFT"
if "%scan_code%"=="97" set "inventory_pick=TAB_LEFT"
if "%scan_code%"=="68" set "inventory_pick=TAB_RIGHT"
if "%scan_code%"=="100" set "inventory_pick=TAB_RIGHT"
if "%scan_code%"=="87" set "inventory_pick=PREV"
if "%scan_code%"=="119" set "inventory_pick=PREV"
if "%scan_code%"=="83" set "inventory_pick=NEXT"
if "%scan_code%"=="115" set "inventory_pick=NEXT"
if "%scan_code%"=="71" set "inventory_pick=TOGGLE_VIEW"
if "%scan_code%"=="103" set "inventory_pick=TOGGLE_VIEW"
if "%scan_code%"=="70" set "inventory_pick=ACTION"
if "%scan_code%"=="102" set "inventory_pick=ACTION"
if "%scan_code%"=="81" set "inventory_pick=CLOSE"
if "%scan_code%"=="113" set "inventory_pick=CLOSE"
if "%scan_code%"=="69" set "inventory_pick=CLOSE"
if "%scan_code%"=="101" set "inventory_pick=CLOSE"
if "%scan_code%"=="27" set "inventory_pick=CLOSE"
exit /b 0
