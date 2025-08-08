@echo off
setlocal EnableExtensions

rem --- PROJECT_ROOT / CFG_DIR を解決 ---
if not defined PROJECT_ROOT for %%I in ("%~dp0\..\..\..") do set "PROJECT_ROOT=%%~fI"
if defined CFG_DIR ( set "_cfg=%CFG_DIR%" ) else ( set "_cfg=%PROJECT_ROOT%\Config" )
set "_profile=%_cfg%\profile.env"

if not exist "%_cfg%" md "%_cfg%" 2>nul

echo.
echo === Save Location Wizard ===
echo  1) AppData (per-user)  … %LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves
echo  2) Project folder      … %PROJECT_ROOT%\Saves  (portable)
echo  3) Custom path         … Any absolute path
choice /c 123 /n /m "Select [1/2/3]: "
set "_opt=%errorlevel%"

if "%_opt%"=="1" (
  set "SAVE_MODE=localappdata"
  set "SAVE_DIR=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
) else if "%_opt%"=="2" (
  set "SAVE_MODE=portable"
  set "SAVE_DIR=%PROJECT_ROOT%\Saves"
) else (
  set "SAVE_MODE=custom"
  :InputCustom
  set /p "SAVE_DIR=Enter absolute path: "
  if not defined SAVE_DIR goto InputCustom
)

rem ---- 正規化（..解決/末尾スラなし） ----
for %%A in ("%SAVE_DIR%") do set "SAVE_DIR=%%~fA"

rem ---- 作成 → 書き込みテスト ----
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
if errorlevel 1 (
  echo [ERROR] Cannot create: "%SAVE_DIR%"
  endlocal & exit /b 1
)
set "_t=%SAVE_DIR%\.__permtest__"
2>nul ( >"%_t%" echo . ) || (
  echo [ERROR] Cannot write: "%SAVE_DIR%"
  del /q "%_t%" >nul 2>&1
  endlocal & exit /b 1
)
del /q "%_t%" >nul 2>&1

rem --- 既存profileを読み込んで他キー維持 ---
if exist "%_profile%" call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%_profile%"
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"

rem --- 原子的に書き戻し ---
> "%_profile%.tmp" (
  echo # Astral Divide profile [auto written by SetupStorageWizard.bat]
  echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
  echo set "CODEPAGE=%CODEPAGE%"
  echo set "LANGUAGE=%LANGUAGE%"
  echo set "SAVE_MODE=%SAVE_MODE%"
  echo set "SAVE_DIR=%SAVE_DIR%"
)
move /y "%_profile%.tmp" "%_profile%" >nul

rem --- 親にも返す ---
endlocal & (
  set "SAVE_MODE=%SAVE_MODE%"
  set "SAVE_DIR=%SAVE_DIR%"
) & exit /b 0
