@echo off
::------------------------------------------------------------------------------
:: LanguageWizard.bat
::------------------------------------------------------------------------------
:: Clear screen and redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Render setup screen text
echo !esc![5;22H!C_TEXT!Language Selection  /  言語設定!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 6

echo !esc![9;25H!C_TEXT![1] 日本語 (ja-JP) - 既定!C_RESET!
echo !esc![11;25H!C_TEXT![2] English (en-US)!C_RESET!

echo !esc![15;15H!C_TEXT!Please select your language (Press 1 or 2):!C_RESET!
echo !esc![16;15H!C_TEXT!使用する言語を選択してください (1 または 2 を押す):!C_RESET!

<nul set /p ="!esc![18;38H!C_RESET!"
choice /c 12 /n /m "> "
set "_lang_choice=%errorlevel%"
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

if "%_lang_choice%"=="1" (
    set "SELECTED_LANG=ja-JP"
) else (
    set "SELECTED_LANG=en-US"
)
if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Selected language is !SELECTED_LANG!"
exit /b
