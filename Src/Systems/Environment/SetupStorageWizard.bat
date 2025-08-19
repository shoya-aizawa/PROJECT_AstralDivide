@echo off
setlocal EnableExtensions
rem -----------------------------------------------------------------------------
rem SetupStorageWizard.bat (RCU/RC Integrated Edition)
rem Role:
rem Determines the storage location (AppData / Project / Custom)
rem Persists to profile.env (maintains other keys)
rem Arguments:
rem None (Autonomous even if PROJECT_ROOT/CFG_DIR is undefined)
rem RC:
rem FLOW/SYS/OTHER/000 → 1-06-90-000: OK
rem CANCEL/SYS/SELECTION/002 → 8-06-01-002: User canceled
rem ERR/SYS/I/O/012 → 9-06-10-012: Directory creation/write failure, etc.
rem -----------------------------------------------------------------------------

rem === PROJECT_ROOT / CFG_DIR 解決（直叩きでも自律） ========================
if not defined PROJECT_ROOT for %%I in ("%~dp0\..\..\..") do set "PROJECT_ROOT=%%~fI"
if defined CFG_DIR ( set "_cfg=%CFG_DIR%" ) else ( set "_cfg=%PROJECT_ROOT%\Config" )
set "_profile=%_cfg%\profile.env"

if not exist "%_cfg%" md "%_cfg%" 2>nul

rem === RCU/RECS bootstrap ======================================================
if not defined RCU set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" 2>nul
if not defined rc_s_flow  set rc_s_flow=1
if not defined rc_s_cancel set rc_s_cancel=8
if not defined rc_s_err   set rc_s_err=9
if not defined rc_d_sys   set rc_d_sys=06
if not defined rc_r_io    set rc_r_io=10
if not defined rc_r_select set rc_r_select=01
if not defined rc_r_other set rc_r_other=90

rem ログは任意
set "LOG_PREFIX=wizard"
call "%RCU%" -trace INFO StorageWizard "start cfg=%_cfg%"

rem === UI ======================================================================
echo.
echo === Save Location Wizard ===
echo  1) AppData (per-user)  … %LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves
echo  2) Project folder      … %PROJECT_ROOT%\Saves  (portable)
echo  3) Custom path         … 任意の絶対パス（^> 空Enter でキャンセル）
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
  set /p "SAVE_DIR=Enter absolute path (blank=cancel): "
  if not defined SAVE_DIR call "%RCU%" -return %rc_s_cancel% %rc_d_sys% %rc_r_select% 002
)

rem ---- 正規化（..解決/末尾スラなし） ----
for %%A in ("%SAVE_DIR%") do set "SAVE_DIR=%%~fA"

rem ---- 作成 → 書き込みテスト ----
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
if not exist "%SAVE_DIR%" (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io% 012 "mkdir failed" "dir=%SAVE_DIR%"
)

set "_t=%SAVE_DIR%\.__permtest__"
2>nul ( >"%_t%" echo . ) || (
  del /q "%_t%" >nul 2>&1
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io% 012 "write failed" "dir=%SAVE_DIR%"
)
del /q "%_t%" >nul 2>&1

rem --- 既存 profile を読み込んで他キー維持 ---
if exist "%_profile%" call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%_profile%"
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"

rem --- 原子的に書き戻し（tmp→move） ---
> "%_profile%.tmp" (
  echo # Astral Divide profile [auto written by SetupStorageWizard.bat]
  echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
  echo set "CODEPAGE=%CODEPAGE%"
  echo set "LANGUAGE=%LANGUAGE%"
  echo set "SAVE_MODE=%SAVE_MODE%"
  echo set "SAVE_DIR=%SAVE_DIR%"
)
move /y "%_profile%.tmp" "%_profile%" >nul

rem --- 親にも返す（callerスコープへ昇格） ---
endlocal & (
  set "SAVE_MODE=%SAVE_MODE%"
  set "SAVE_DIR=%SAVE_DIR%"
) & call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
