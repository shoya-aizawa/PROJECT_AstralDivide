:: ========================================================================
::  Astral Divide Launch Guard (v0.1a)
::  by HedgeHogSoft / PROJECT_AstralDivide
:: ------------------------------------------------------------------------
::  Purpose:
::    Prevent direct launching of the game executable/batch file.
::    Ensure necessary environment variables and files are present.
::    If damage is detected,even though the game has started up normally,
::    inform the user and halt execution to prevent further issues.
:: ------------------------------------------------------------------------
:: ========================================================================

@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
for /f %%e in ('cmd /k prompt $e^<nul') do set "ESC=%%e"

:: [1] PROJECT_ROOT inspection + self-repair
if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
if not exist "%PROJECT_ROOT%" (
    echo [ERROR] PROJECT_ROOT invalid or unrecoverable.
    pause >nul
    endlocal & exit /b 1
)


:: [2] Launch Token Validation
if not defined GAME_LAUNCHER (
    mode 80,25
    set "esc=!ESC!"
    set "C_BORDER=!ESC![38;5;239m"
    set "C_TEXT=!ESC![38;5;250m"
    set "C_WARN=!ESC![91m"
    set "C_GREEN=!ESC![92m"
    set "C_RESET=!ESC![0m"
    
    echo !esc![2J
    call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
    
    echo !esc![4;24H!C_WARN![CRITICAL SECURITY GUARD]!C_RESET!
    call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 5
    
    echo !esc![8;10H!C_TEXT!Direct execution of game files has been blocked.!C_RESET!
    echo !esc![9;10H!C_TEXT!This mechanism prevents unauthorized manipulation and!C_RESET!
    echo !esc![10;10H!C_TEXT!ensures proper system environment configuration.!C_RESET!
    
    echo !esc![13;10H!C_WARN![WARNING] 直叩き（直接起動）が検出されました。!C_RESET!
    echo !esc![15;10H!C_TEXT!ゲームを安全に開始し、整合性チェックを行うには、!C_RESET!
    echo !esc![16;10H!C_TEXT!必ずルートディレクトリにある !C_GREEN!"AstralDivide.bat"!C_TEXT! から!C_RESET!
    echo !esc![17;10H!C_TEXT!起動してください。!C_RESET!
    
    call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 19
    
    echo !esc![21;24H!C_TEXT!Press any key to exit security guard...!C_RESET!
    echo !esc![22;60H!C_RESET!
    
    pause >nul
    endlocal & exit /b 2
)

:: [3] Confirm existence of Main.bat
if not exist "%PROJECT_ROOT%\Src\Main\Main.bat" (
    echo [WARN] Main.bat not found. Validating path...
    timeout /t 1 >nul 2>&1
    set "SRC_MAIN_DIR=%PROJECT_ROOT%\Src\Main"
    tree "%SRC_MAIN_DIR%" >nul 2>&1
    if errorlevel 1 (
        echo [CRITICAL] Path corrupted or inaccessible.
        pause >nul
        endlocal & exit /b 3
    )
    echo [ERROR] Main.bat missing. Please reinstall Astral Divide.
    pause >nul
    endlocal & exit /b 4
)
endlocal & exit /b 0
