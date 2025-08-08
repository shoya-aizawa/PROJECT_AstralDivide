@echo off
setlocal

rem --- PROJECT_ROOT / CFG_DIR を解決（親から来ていれば最優先） ---
if not defined PROJECT_ROOT for %%I in ("%~dp0\..\..\..") do set "PROJECT_ROOT=%%~fI"
if defined CFG_DIR ( set "_cfg=%CFG_DIR%" ) else ( set "_cfg=%PROJECT_ROOT%\Config" )
set "_profile=%_cfg%\profile.env"

if not exist "%_cfg%" md "%_cfg%" 2>nul

rem --- ANSI ESC / UTF-8 に上げて入力の文字化け回避 ---
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"
chcp 65001 >nul

:Select_Language
cls
echo.
echo === language setup ===
echo Select language / 言語を選択してください:
echo   [1] 日本語 (ja-JP)
echo   [2] English (en-US)
set /p "_pick=> "
if "%_pick%"=="2" (
   set "LANGUAGE=en-US"
) else if "%_pick%"=="1" (
   set "LANGUAGE=ja-JP"
) else (
   echo Invalid selection. / 無効な選択です。
   timeout /t 1 >nul
   goto :Select_Language
)

echo %esc%[92m[OK]%esc%[0m LANGUAGE=%LANGUAGE%
timeout /t 1 >nul

rem --- 既存のprofile.envを読み込み（他キーを保持） ---
if exist "%_profile%" call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%_profile%"
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"

rem --- 原子的に書き戻し（tmp→move） ---
> "%_profile%.tmp" (
   echo # Astral Divide profile [auto written by SetupLanguage.bat]
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   if defined SAVE_MODE echo set "SAVE_MODE=%SAVE_MODE%"
   if defined SAVE_DIR  echo set "SAVE_DIR=%SAVE_DIR%"
)
move /y "%_profile%.tmp" "%_profile%" >nul

rem --- 親にも返す ---
endlocal & (
   set "LANGUAGE=%LANGUAGE%"
) & exit /b 0
