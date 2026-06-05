@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: -----------------------------------------------------------------------------
:: SaveDataDeleter.bat
:: Role: Modular save data deletion controller.
::       Invokes SaveDataSelector in DELETE mode and physically deletes slot files.
:: -----------------------------------------------------------------------------

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "src_savesys_dir=%PROJECT_ROOT%\Src\Systems\SaveSys"
set "src_audio_dir=%PROJECT_ROOT%\Src\Systems\Audio"
if not defined assets_sounds_fx_dir set "assets_sounds_fx_dir=%PROJECT_ROOT%\Assets\Sounds\FX"
if not defined saves_active_dir set "saves_active_dir=%PROJECT_ROOT%\Saves"

if not defined esc (
    for /f "delims=" %%a in ('echo prompt $E^| cmd /d') do set "esc=%%a"
)

:DeleterLoop
    :: Call the selector in DELETE mode
    call "%src_savesys_dir%\SaveDataSelector.bat" DELETE
    
    :: If user cancelled or backed out, return to SettingsMenu
    if not "%UI_ACTION%"=="DELETE" (
        endlocal
        exit /b 0
    )
    
    set "target_slot=%UI_PARAM%"
    if "%target_slot%"=="" goto :DeleterLoop
    
    :: Double confirmation prompt for deleting the save slot
    call :ShowConfirmDialog "スロット%target_slot%のデータを削除しますか？ (F=はい/Q=いいえ)"
    set "confirm_res=%errorlevel%"
    
    if "%confirm_res%"=="1" (
        :: physically delete SaveData_X.txt and ESD_X.txt
        if exist "%saves_active_dir%\SaveData_%target_slot%.txt" (
            del "%saves_active_dir%\SaveData_%target_slot%.txt" >nul 2>&1
        )
        if exist "%saves_active_dir%\ESD_%target_slot%.txt" (
            del "%saves_active_dir%\ESD_%target_slot%.txt" >nul 2>&1
        )
        
        :: Play deletion complete SE (Cancel sound used for destruction / removal)
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
        
        :: Display completion notification for 1 second
        call :ShowNotification "データを削除しました" "92" 1
    ) else (
        :: Play cancel SE
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
    )
    
    goto :DeleterLoop

:ShowConfirmDialog
    setlocal EnableDelayedExpansion
    set "msg=%~1"
    
    :: Coordinate determination based on UI quality definitions
    set "d_row=20"
    set "d_col=92"
    if defined SDS_DIALOG_ROW set "d_row=%SDS_DIALOG_ROW%"
    if defined SDS_DIALOG_COL set "d_col=%SDS_DIALOG_COL%"
    
    set "a_row=1"
    set "a_col=1"
    if defined SDS_ANCHOR_ROW set "a_row=%SDS_ANCHOR_ROW%"
    if defined SDS_ANCHOR_COL set "a_col=%SDS_ANCHOR_COL%"
    
    set /a "dialog_row=d_row + a_row - 1"
    set /a "dialog_col=d_col + a_col - 1"
    
    :: Print confirmation message in yellow
    echo !esc![!dialog_row!;!dialog_col!H!esc![93m !msg! !esc![0m
    
    :InputLoop
    choice /n /c FQ >nul
    set "input_val=%errorlevel%"
    
    :: Clear dialog line
    echo !esc![!dialog_row!;!dialog_col!H!esc![K
    
    if "%input_val%"=="1" (
        endlocal & exit /b 1
    ) else (
        endlocal & exit /b 2
    )

:ShowNotification
    setlocal EnableDelayedExpansion
    set "msg=%~1"
    set "color_code=%~2"
    set "delay_sec=%~3"
    
    set "d_row=20"
    set "d_col=92"
    if defined SDS_DIALOG_ROW set "d_row=%SDS_DIALOG_ROW%"
    if defined SDS_DIALOG_COL set "d_col=%SDS_DIALOG_COL%"
    
    set "a_row=1"
    set "a_col=1"
    if defined SDS_ANCHOR_ROW set "a_row=%SDS_ANCHOR_ROW%"
    if defined SDS_ANCHOR_COL set "a_col=%SDS_ANCHOR_COL%"
    
    set /a "dialog_row=d_row + a_row - 1"
    set /a "dialog_col=d_col + a_col - 1"
    
    :: Print message with specified color
    echo !esc![!dialog_row!;!dialog_col!H!esc![%color_code%m !msg! !esc![0m
    timeout /t %delay_sec% >nul
    echo !esc![!dialog_row!;!dialog_col!H!esc![K
    endlocal
    exit /b 0
