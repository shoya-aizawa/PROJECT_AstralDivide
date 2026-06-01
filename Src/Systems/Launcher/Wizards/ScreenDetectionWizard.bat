@echo off
::------------------------------------------------------------------------------
:: ScreenDetectionWizard.bat
::------------------------------------------------------------------------------
:: Clear screen and redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

echo !esc![4;20H!C_TEXT!Screen Resolution Probe  /  画面サイズ自動測定!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 5

echo !esc![8;10H!C_TEXT!ゲーム画面のレイアウトをあなたのモニターに最適化するため、!C_RESET!
echo !esc![9;10H!C_TEXT!ディスプレイの最大表示可能数を自動的に測定します。!C_RESET!
echo.
echo !esc![11;10H!esc![91m※測定中、一時的に画面が最大化（全画面表示）に切り替わりますが、!C_RESET!
echo !esc![12;10H!esc![91m　測定完了後に自動的に元のサイズに戻りますのでご安心ください。!C_RESET!
echo.
echo !esc![15;10H!C_TEXT!This game will temporarily switch to fullscreen mode!C_RESET!
echo !esc![16;10H!C_TEXT!to detect your monitor's maximum supported dimensions.!C_RESET!

echo !esc![19;12H!C_TEXT!Press any key to start the screen detection wizard...!C_RESET!
echo !esc![20;12H!C_TEXT!準備ができたら、どれかキーを押して測定を開始してください...!C_RESET!

echo !esc![21;38H!C_RESET!
pause >nul
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

:: Foreground screen environment detection
set "SPLASH_RUNNING="
call "%PROJECT_ROOT%\Src\Systems\Environment\ScreenEnvironmentDetection.bat" "%PROJECT_ROOT%"

:: Re-apply selected font to prevent fallback bug caused by screen detection sub-processes
if defined SELECTED_FONT (
    if not "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
        if exist "!cmdwiz_path!" (
            call "!cmdwiz_path!" setfont "%PROJECT_ROOT%\Tools\!SELECTED_FONT!.fnt" >nul 2>&1
        )
    )
)

:: Load results from screen_config.env
set "screen_cfg_file=%PROJECT_ROOT%\Config\Cache\Screen\%COMPUTERNAME%\screen_config.env"
set "PROBED_COLS="
set "PROBED_ROWS="
if exist "%screen_cfg_file%" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%screen_cfg_file%") do (
        if "%%a"=="CONSOLE_WIDTH" set "PROBED_COLS=%%b"
        if "%%a"=="CONSOLE_HEIGHT" set "PROBED_ROWS=%%b"
    )
)

:: Guard defaults
if not defined PROBED_COLS set "PROBED_COLS=90"
if not defined PROBED_ROWS set "PROBED_ROWS=35"

:: Write to user_config.env
set "_config_file=%PROJECT_ROOT%\Config\user_config.env"
if not exist "%PROJECT_ROOT%\Config" md "%PROJECT_ROOT%\Config" >nul 2>&1
echo # Astral Divide profile [auto-written by Splash Wizard]> "%_config_file%.tmp"
>> "%_config_file%.tmp" echo PROFILE_SCHEMA=1
>> "%_config_file%.tmp" echo CODEPAGE=65001
>> "%_config_file%.tmp" echo LANGUAGE=!SELECTED_LANG!
if defined SELECTED_FONT >> "%_config_file%.tmp" echo CONSOLE_FONT=!SELECTED_FONT!
>> "%_config_file%.tmp" echo SAVE_MODE=!SAVE_MODE!
>> "%_config_file%.tmp" echo SAVE_DIR=!SAVE_DIR!
>> "%_config_file%.tmp" echo CONSOLE_COLS=%PROBED_COLS%
>> "%_config_file%.tmp" echo CONSOLE_ROWS=%PROBED_ROWS%
move /y "%_config_file%.tmp" "%_config_file%" >nul

:: Restore standard console size for splash continuation
mode con cols=80 lines=25
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
exit /b
