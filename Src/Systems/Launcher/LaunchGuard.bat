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
    exit /b 1
)

:: [2] Launch Token Validation
if not defined GAME_LAUNCHER (
    echo !ESC![31m[ERROR]!ESC![0m Direct launch detected.
    echo Please use !ESC![92m"AstralDivide.bat"!ESC![0m to start the game.
    exit /b 2
)

:: [3] Confirm existence of Main.bat
if not exist "%PROJECT_ROOT%\Src\Main\Main.bat" (
    echo [WARN] Main.bat not found. Validating path...
    set "SRC_MAIN_DIR=%PROJECT_ROOT%\Src\Main"
    tree "%SRC_MAIN_DIR%" >nul 2>&1
    if errorlevel 1 (
        echo [CRITICAL] Path corrupted or inaccessible.
        exit /b 3
    )
    echo [ERROR] Main.bat missing. Please reinstall Astral Divide.
    exit /b 4
)

exit /b 0
