@echo off

if /i not "%DEBUG_STATE%"=="1" exit /b 0

if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not defined tools_dir set "tools_dir=%PROJECT_ROOT%\Tools"
if not defined src_inventory_dir set "src_inventory_dir=%PROJECT_ROOT%\Src\Systems\Inventory"
if not defined src_itemdata_dir set "src_itemdata_dir=%PROJECT_ROOT%\Src\Data\ItemData"

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

call "%src_inventory_dir%\InventoryCore.bat" INIT_DEFAULTS
call :LoadIndex
if not defined dbg_item_count exit /b 0
set "dbg_selected=1"
set "dbg_message=F:+1  G:+5  R:+10  W/S:選択  Q/Esc:戻る"

:DebugLoop
call :Render
call :PollKey
if "%dbg_pick%"=="CLOSE" exit /b 0
if "%dbg_pick%"=="UP" (
    set /a "dbg_selected-=1"
    if !dbg_selected! LSS 1 set "dbg_selected=%dbg_item_count%"
    goto :DebugLoop
)
if "%dbg_pick%"=="DOWN" (
    set /a "dbg_selected+=1"
    if !dbg_selected! GTR %dbg_item_count% set "dbg_selected=1"
    goto :DebugLoop
)
if "%dbg_pick%"=="ADD1" call :GrantSelected 1
if "%dbg_pick%"=="ADD5" call :GrantSelected 5
if "%dbg_pick%"=="ADD10" call :GrantSelected 10
goto :DebugLoop

:LoadIndex
set "dbg_item_count="
for /f "usebackq tokens=1* delims==" %%A in ("%src_itemdata_dir%\ItemIndex.dat") do (
    if /i "%%A"=="item_count" set "dbg_item_count=%%B"
    if /i not "%%A"=="item_count" set "dbg_%%A=%%B"
)
exit /b 0

:GrantSelected
call set "grant_item_id=%%dbg_item_%dbg_selected%%%"
call "%src_inventory_dir%\InventoryCore.bat" ADD "%grant_item_id%" "%~1"
call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "%grant_item_id%" "grant_"
set "dbg_message=%grant_name% を %~1 個付与しました。"
exit /b 0

:Render
cls
echo %ESC%[3;6H%ESC%[96mDEBUG ITEM GRANT%ESC%[0m
echo %ESC%[4;6H%ESC%[90m────────────────────────────────────────────────────────────────────────%ESC%[0m
echo %ESC%[5;6H%ESC%[90m%dbg_message%%ESC%[0m
for /l %%I in (1,1,%dbg_item_count%) do (
    set /a "row=7+%%I"
    if !row! GTR 28 goto :RenderDone
    call set "entry_id=%%dbg_item_%%I%%"
    call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "!entry_id!" "dbg_entry_"
    if "%%I"=="%dbg_selected%" (
        echo %ESC%[!row!;8H%ESC%[30;103m ^> !dbg_entry_icon! !dbg_entry_name!  [!entry_id!] %ESC%[0m
    ) else (
        echo %ESC%[!row!;8H%ESC%[97m   !dbg_entry_icon! !dbg_entry_name!  [!entry_id!]%ESC%[0m
    )
)
:RenderDone
call :RenderDetail
exit /b 0

:RenderDetail
call set "entry_id=%%dbg_item_%dbg_selected%%%"
call "%src_inventory_dir%\InventoryCore.bat" LOAD_ITEM "%entry_id%" "dbg_detail_"
echo %ESC%[8;86H%ESC%[93m%dbg_detail_name%%ESC%[0m
echo %ESC%[10;86H%ESC%[97mID    : %entry_id%%ESC%[0m
echo %ESC%[11;86H%ESC%[97m分類  : %dbg_detail_category%%ESC%[0m
echo %ESC%[12;86H%ESC%[97m記号  : %dbg_detail_icon%%ESC%[0m
echo %ESC%[13;86H%ESC%[97mStack : %dbg_detail_stackable%%ESC%[0m
echo %ESC%[14;86H%ESC%[97m最大数: %dbg_detail_max_stack%%ESC%[0m
echo %ESC%[16;86H%ESC%[90m説明%ESC%[0m
echo %ESC%[17;86H%ESC%[97m%dbg_detail_description%%ESC%[0m
exit /b 0

:PollKey
set "dbg_pick=NONE"
:PollKeyLoop
"%tools_dir%\cmdwiz.exe" getch noWait >nul 2>&1
set "scan_code=%errorlevel%"
if "%scan_code%"=="0" (
    "%tools_dir%\cmdwiz.exe" delay 15 >nul 2>&1
    goto :PollKeyLoop
)
if "%scan_code%"=="87" set "dbg_pick=UP"
if "%scan_code%"=="119" set "dbg_pick=UP"
if "%scan_code%"=="72" set "dbg_pick=UP"
if "%scan_code%"=="83" set "dbg_pick=DOWN"
if "%scan_code%"=="115" set "dbg_pick=DOWN"
if "%scan_code%"=="80" set "dbg_pick=DOWN"
if "%scan_code%"=="70" set "dbg_pick=ADD1"
if "%scan_code%"=="102" set "dbg_pick=ADD1"
if "%scan_code%"=="71" set "dbg_pick=ADD5"
if "%scan_code%"=="103" set "dbg_pick=ADD5"
if "%scan_code%"=="82" set "dbg_pick=ADD10"
if "%scan_code%"=="114" set "dbg_pick=ADD10"
if "%scan_code%"=="81" set "dbg_pick=CLOSE"
if "%scan_code%"=="113" set "dbg_pick=CLOSE"
if "%scan_code%"=="69" set "dbg_pick=CLOSE"
if "%scan_code%"=="101" set "dbg_pick=CLOSE"
if "%scan_code%"=="27" set "dbg_pick=CLOSE"
exit /b 0
