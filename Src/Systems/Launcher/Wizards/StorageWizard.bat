@echo off
::------------------------------------------------------------------------------
:: StorageWizard.bat
::------------------------------------------------------------------------------
:: Allow conhost to settle down after font application to prevent fallback bug
if exist "!cmdwiz_path!" "!cmdwiz_path!" delay 100

:: Clear screen and redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Render storage setup text
echo !esc![4;20H!C_TEXT!Save Data Location Wizard  /  セーブ先設定!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 5

echo !esc![8;10H!C_TEXT![1] Project folder (推奨 / ポータブル / portable)!C_RESET!
call echo !esc![9;14H!esc![38;5;244m➔ %%PROJECT_ROOT%%\Saves!C_RESET!

echo !esc![12;10H!C_TEXT![2] AppData (ローカル / per-user)!C_RESET!
echo !esc![13;14H!esc![38;5;244m➔ !LOCALAPPDATA!\HedgeHogSoft\AstralDivide\Saves!C_RESET!

echo !esc![16;10H!C_TEXT![3] Custom path (独自の絶対パスを指定する)!C_RESET!

echo !esc![19;12H!C_TEXT!Select Save Data Location (Press 1, 2 or 3):!C_RESET!
echo !esc![20;12H!C_TEXT!セーブデータの保存先を選択してください (1, 2, 3):!C_RESET!

<nul set /p ="!esc![21;38H!C_RESET!"
choice /c 123 /n /m "> "
set "_store_choice=%errorlevel%"
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

if "%_store_choice%"=="1" (
    set "SAVE_MODE=portable"
    set "SAVE_DIR=%PROJECT_ROOT%\Saves"
) else if "%_store_choice%"=="2" (
    set "SAVE_MODE=localappdata"
    set "SAVE_DIR=!LOCALAPPDATA!\HedgeHogSoft\AstralDivide\Saves"
) else (
    :: Prompt for custom path within the same GUI framework
    <nul set /p ="!esc![22;12H!esc![K!C_TEXT!Enter absolute path: !C_RESET!"
    set /p "CUSTOM_DIR="
    if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"
    
    if "!CUSTOM_DIR!"=="" (
        set "SAVE_MODE=portable"
        set "SAVE_DIR=%PROJECT_ROOT%\Saves"
    ) else (
        set "SAVE_MODE=custom"
        set "SAVE_DIR=!CUSTOM_DIR!"
    )
)

:: Resolve path
for %%A in ("!SAVE_DIR!") do set "SAVE_DIR=%%~fA"

:: Create the save directory
if not exist "!SAVE_DIR!" md "!SAVE_DIR!" >nul 2>&1

if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Save mode is !SAVE_MODE! - Path: !SAVE_DIR!"

:: Proceed to Screen Resolution Probe Wizard!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\ScreenDetectionWizard.bat"
exit /b
