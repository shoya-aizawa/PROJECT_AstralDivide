@echo off
::------------------------------------------------------------------------------
:: FontWizard.bat
::------------------------------------------------------------------------------
:: If external tools are blocked, skip font selection wizard safely
if "%EXTERNAL_TOOLS_BLOCKED%"=="1" (
    if defined RCSU call "%RCSU%" -trace WARN Splash "Wizard - External tools blocked. Skipping Font Selection."
    exit /b
)
if not exist "!cmdwiz_path!" (
    if defined RCSU call "%RCSU%" -trace WARN Splash "Wizard - cmdwiz.exe not found at !cmdwiz_path!. Skipping Font Selection."
    exit /b
)

:: Ensure UTF-8 active and set flag to prevent duplicate execution in child processes
if not "%CODEPAGE_SET%"=="1" (
    chcp 65001 >nul
    set "CODEPAGE_SET=1"
)

:: Save current font as default so we can restore it if user presses N
call "!cmdwiz_path!" savefont "%PROJECT_ROOT%\Tools\Default.fnt" >nul 2>&1

:FontSelectionLoop
:: Clear screen and redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Render font selection title
echo !esc![4;24H!C_TEXT!Font Configuration / フォント設定!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 5

echo !esc![8;10H!C_TEXT![1] SimSun   (推奨 / Recommended - Beautiful backslash \)!C_RESET!
echo !esc![10;10H!C_TEXT![2] Consolas (等幅フォント / Elegant monospaced - Good for code)!C_RESET!
echo !esc![12;10H!C_TEXT![3] MSGothic (標準フォント / Standard Japanese Gothic font)!C_RESET!

echo !esc![15;10H!C_TEXT!Please select a font (Press 1, 2, or 3):!C_RESET!
echo !esc![16;10H!C_TEXT!フォントを選択してください (1, 2, 3):!C_RESET!

<nul set /p ="!esc![18;38H!C_RESET!"
choice /c 123 /n /m "> "
set "_font_choice=%errorlevel%"
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

set "TEMP_FONT="
if "%_font_choice%"=="1" set "TEMP_FONT=SimSun"
if "%_font_choice%"=="2" set "TEMP_FONT=Consolas"
if "%_font_choice%"=="3" set "TEMP_FONT=MSGothic"

if not defined TEMP_FONT goto FontSelectionLoop

:: Apply selected font temporarily via cmdwiz.exe to let the user preview it immediately!
call "!cmdwiz_path!" setfont "%PROJECT_ROOT%\Tools\!TEMP_FONT!.fnt" >nul 2>&1

:: Display premium preview frame to show characters clearly
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

echo !esc![4;22H!C_TEXT!Font Selection Preview  /  プレビュー!C_RESET!
:: SimSun uses double-width (East Asian Width=Ambiguous) for box-drawing chars -- fall back to ASCII
if /i "!TEMP_FONT!"=="SimSun" (
    echo !esc![5;8H!C_BORDER!----------------------------------------------------------------!C_RESET!
    echo !esc![7;10H!C_TEXT!Selected Font: !C_LOAD!!TEMP_FONT!!C_RESET!
    echo !esc![9;10H!C_BORDER!+--------------------------------------------------------------+!C_RESET!
    echo !esc![10;10H!C_BORDER!^| !C_TEXT!Preview Text:                                                !C_BORDER!^|!C_RESET!
    echo !esc![11;10H!C_BORDER!^| !C_TEXT!Path / パス:  C:\Users\shoya\Desktop\AstralDivide            !C_BORDER!^|!C_RESET!
    echo !esc![12;10H!C_BORDER!^| !C_TEXT!Slash / 円記号: \  ^(Should display as a backslash, not ¥^)    !C_BORDER!^|!C_RESET!
    echo !esc![13;10H!C_BORDER!^| !C_TEXT!Symbols / 記号: [ ] { } ^( ^) ^< ^> * # ^@ ^& ^| ? + - = _ /        !C_BORDER!^|!C_RESET!
    echo !esc![14;10H!C_BORDER!+--------------------------------------------------------------+!C_RESET!
) else (
    echo !esc![5;8H!C_BORDER!────────────────────────────────────────────────────────────────!C_RESET!
    echo !esc![7;10H!C_TEXT!Selected Font: !C_LOAD!!TEMP_FONT!!C_RESET!
    echo !esc![9;10H!C_BORDER!┌──────────────────────────────────────────────────────────────┐!C_RESET!
    echo !esc![10;10H!C_BORDER!│ !C_TEXT!Preview Text:                                                !C_BORDER!│!C_RESET!
    echo !esc![11;10H!C_BORDER!│ !C_TEXT!Path / パス:  C:\Users\shoya\Desktop\AstralDivide            !C_BORDER!│!C_RESET!
    echo !esc![12;10H!C_BORDER!│ !C_TEXT!Slash / 円記号: \  ^(Should display as a backslash, not ¥^)    !C_BORDER!│!C_RESET!
    echo !esc![13;10H!C_BORDER!│ !C_TEXT!Symbols / 記号: [ ] { } ^( ^) ^< ^> * # @ ^& ^| ? + - = _ /        !C_BORDER!│!C_RESET!
    echo !esc![14;10H!C_BORDER!└──────────────────────────────────────────────────────────────┘!C_RESET!
)

if "!TEMP_FONT!"=="Consolas" goto RenderConsolasWarning

:: Normal warning layout
echo !esc![16;10H!C_TEXT!Apply this font? / このフォントを設定しますか？ (Y/N):!C_RESET!
echo !esc![18;10H!C_TEXT!Y: Confirm ^& Proceed / 決定して次へ!C_RESET!
echo !esc![19;10H!C_TEXT!N: Try another font / 選び直す!C_RESET!
<nul set /p ="!esc![16;63H!C_RESET!"
goto RenderWarningEnd

:RenderConsolasWarning
echo !esc![15;10H!esc![93m[WARNING] 日本/アジア圏のOS環境で Consolas を使用する場合、!C_RESET!
echo !esc![16;10H!esc![93m          フォント整合性維持のためシステム処理が一部複雑化し、!C_RESET!
echo !esc![17;10H!esc![93m          システムのパフォーマンスに影響が出る可能性があります。!C_RESET!
echo !esc![19;10H!C_TEXT!Apply this font? / それでも設定しますか？ (Y/N):!C_RESET!
echo !esc![21;10H!C_TEXT!Y: Confirm ^& Proceed / 決定して次へ!C_RESET!
echo !esc![22;10H!C_TEXT!N: Try another font / 選び直す!C_RESET!
<nul set /p ="!esc![19;58H!C_RESET!"

:RenderWarningEnd
choice /c yn /n /m "> "
set "_confirm_choice=%errorlevel%"

if "%_confirm_choice%"=="2" (
    if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_CANCEL%"
    :: Restore original font before showing the selection screen again
    if exist "%PROJECT_ROOT%\Tools\Default.fnt" (
        call "!cmdwiz_path!" setfont "%PROJECT_ROOT%\Tools\Default.fnt" >nul 2>&1
    )
    goto FontSelectionLoop
)

if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER3%"

set "SELECTED_FONT=!TEMP_FONT!"
if defined RCSU call "%RCSU%" -trace INFO Splash "Wizard - Selected font is !SELECTED_FONT!"
exit /b
