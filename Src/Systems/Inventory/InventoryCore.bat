@echo off

if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not defined src_itemdata_dir set "src_itemdata_dir=%PROJECT_ROOT%\Src\Data\ItemData"
if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

set "inventory_action=%~1"
if /i "%inventory_action%"=="INIT_DEFAULTS" goto :InitDefaults
if /i "%inventory_action%"=="LOAD_ITEM" goto :LoadItem
if /i "%inventory_action%"=="ADD" goto :AddItem
exit /b 0

:InitDefaults
if not defined inventory_stack_count set "inventory_stack_count=0"
if not defined inventory_unique_count set "inventory_unique_count=0"
exit /b 0

:LoadItem
set "target_item_id=%~2"
set "target_prefix=%~3"
if not defined target_prefix set "target_prefix=item_"
if not defined target_item_id exit /b 1

set "item_file=%src_itemdata_dir%\Items\%target_item_id%.dat"
if not exist "%item_file%" (
    if exist "%RCSU%" call "%RCSU%" -trace WARN InventoryCore "missing item master id=%target_item_id%"
    exit /b 2
)

for %%V in (
    item_id name category icon stackable max_stack buy_price sell_price
    usable equipable equip_slot description feature_socket
    feature_astral_core feature_prefix_suffix
) do set "%target_prefix%%%V="

for /f "usebackq tokens=1* delims==" %%A in ("%item_file%") do (
    if not "%%A"=="" set "%target_prefix%%%A=%%B"
)
exit /b 0

:AddItem
setlocal EnableDelayedExpansion
call :InitDefaults
set "target_item_id=%~2"
set "target_count=%~3"
if not defined target_count set "target_count=1"
if not defined target_item_id exit /b 1

call "%~f0" LOAD_ITEM "%target_item_id%" "inv_add_"
if errorlevel 1 exit /b 2

if "!inv_add_stackable!"=="1" (
    for /l %%I in (1,1,!inventory_stack_count!) do (
        for /f "tokens=1,2 delims=," %%A in ("!inventory_stack_%%I!") do (
            if /i "%%A"=="!target_item_id!" (
                set /a "new_count=%%B + target_count"
                set "inventory_stack_%%I=%%A,!new_count!"
                goto :ExportInventoryState
            )
        )
    )
    set /a "inventory_stack_count+=1"
    set "inventory_stack_!inventory_stack_count!=!target_item_id!,!target_count!"
    goto :ExportInventoryState
)

for /l %%I in (1,1,!target_count!) do (
    set /a "inventory_unique_count+=1"
    set "inventory_unique_!inventory_unique_count!=!target_item_id!"
)

:ExportInventoryState
set "inventory_export_file=%TEMP%\ad_inventory_export_%RANDOM%_%RANDOM%.cmd"
> "!inventory_export_file!" (
    echo set "inventory_stack_count=!inventory_stack_count!"
    for /l %%I in (1,1,!inventory_stack_count!) do echo set "inventory_stack_%%I=!inventory_stack_%%I!"
    echo set "inventory_unique_count=!inventory_unique_count!"
    for /l %%I in (1,1,!inventory_unique_count!) do echo set "inventory_unique_%%I=!inventory_unique_%%I!"
)
endlocal & call "%inventory_export_file%" & del "%inventory_export_file%" >nul 2>&1
exit /b 0
