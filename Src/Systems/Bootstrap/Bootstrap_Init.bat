@echo off
setlocal EnableExtensions EnableDelayedExpansion
:: ====================================================================
:: Bootstrap_Init.bat  (RCU/RC 統合・等価判定版)
:: Role:
::   - load or create profile (first launch detection included)
:: Arg1: %~1 == %PROJECT_ROOT%
:: RC:
::   FLOW/SYS/OTHER/000 → 1-06-90-000 : OK
::   ERR /SYS/PARSE /011 → 9-06-11-011 : profile.env parse failed (LoadEnv)
::   ERR /SYS/I/O   /012 → 9-06-10-012 : storage wizard / save-dir I/O
::   ERR /SYS/OTHER /013 → 9-06-90-013 : setup language failed (unexpected)
:: ====================================================================

:: --- derive PROJECT_ROOT / CFG paths ---
if not defined PROJECT_ROOT set "PROJECT_ROOT=%~1"
set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"

:: --- RECS/RCU bootstrap（直叩きでも自律） ---
if not defined RCU set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" 2>nul

:: 最低限のフェイルセーフ定数（直叩き保険）
if not defined rc_s_flow  set rc_s_flow=1
if not defined rc_s_cancel set rc_s_cancel=8
if not defined rc_s_err   set rc_s_err=9
if not defined rc_d_sys   set rc_d_sys=06
if not defined rc_r_io    set rc_r_io=10
if not defined rc_r_parse set rc_r_parse=11
if not defined rc_r_other set rc_r_other=90
if not defined rc_r_select set rc_r_select=01

:: 代表RC（OK/Cancel）を事前生成
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_flow%   %rc_d_sys% %rc_r_other% 000') do set "RC_OK=%%R"
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_cancel% %rc_d_sys% %rc_r_select% 002') do set "RC_CANCEL=%%R"

:: --- logging（任意） ---
set "LOG_PREFIX=boot"
call "%RCU%" -trace INFO Bootstrap "start project_root=%PROJECT_ROOT%"

:: --- UI用 ESC（未定義なら取得） ---
if not defined esc for /f %%e in ('cmd /k prompt $e^<nul') do set "esc=%%e"

:: ===================== Main Flow =====================

if exist "%CFG_FILE%" goto :HaveProfile
goto :FirstRun

:HaveProfile
echo %esc%[92m[OK]%esc%[0m Welcome back! profile.env exists

call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
set "RC=%errorlevel%"
if not "%RC%"=="%RC_OK%" (
    call "%RCU%" -pretty %RC%
    exit /b %RC%
)

:: --- Self-Repair defaults ---
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"
if /i not "%SAVE_MODE%"=="localappdata" if /i not "%SAVE_MODE%"=="portable" if /i not "%SAVE_MODE%"=="custom" set "SAVE_MODE=portable"

if not defined SAVE_DIR (
   if /i "%SAVE_MODE%"=="localappdata" (
      set "SAVE_DIR=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
   ) else if /i "%SAVE_MODE%"=="portable" (
      set "SAVE_DIR=%PROJECT_ROOT%\Saves"
   ) else (
      call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"
      set "RC=%errorlevel%"
      if not "%RC%"=="%RC_OK%" (
          call "%RCU%" -pretty %RC%
          exit /b %RC%
      )
      call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
      set "RC=%errorlevel%"
      if not "%RC%"=="%RC_OK%" (
          call "%RCU%" -pretty %RC%
          exit /b %RC%
      )
   )
)
goto :ProfileReady

:FirstRun
echo %esc%[92m[WELCOME]%esc%[0m This is your first boot.
timeout /t 2 >nul
:: === First time: Language → Storage wizard (both persist to profile.env) ===
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat"
set "RC=%errorlevel%"
if not "%RC%"=="%RC_OK%" (
    call "%RCU%" -pretty %RC%
    exit /b %RC%
)

call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"
set "RC=%errorlevel%"
if not "%RC%"=="%RC_OK%" (
    call "%RCU%" -pretty %RC%
    exit /b %RC%
)

:: --- Re-sync from disk (the single source of truth) ---
if not exist "%CFG_DIR%" md "%CFG_DIR%" 2>nul
call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
set "RC=%errorlevel%"
if not "%RC%"=="%RC_OK%" (
    call "%RCU%" -pretty %RC%
    exit /b %RC%
)

:ProfileReady
:: --- Ensure SAVE_DIR exists; create if missing（作成失敗はエラー返却） ---
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
if not exist "%SAVE_DIR%" (
   echo %esc%[31m[WARN]%esc%[0m SAVE_DIR="%SAVE_DIR%" を作成できませんでした。再設定します。

   call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"
   set "RC=%errorlevel%"
   if not "%RC%"=="%RC_OK%" (
       call "%RCU%" -pretty %RC%
       exit /b %RC%
   )

   call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
   set "RC=%errorlevel%"
   if not "%RC%"=="%RC_OK%" (
       call "%RCU%" -pretty %RC%
       exit /b %RC%
   )

   if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
   if not exist "%SAVE_DIR%" (
       rem 最終的に作れない場合は I/O として終了
       call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io% 012 "SAVE_DIR create failed" "dir=%SAVE_DIR%"
   )
)

:: --- Write-back normalization（引用付きで安全に）---
>"%CFG_FILE%" (
   echo # Astral Divide profile
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   echo set "SAVE_MODE=%SAVE_MODE%"
   echo set "SAVE_DIR=%SAVE_DIR%"
)

rem ここで軽くログ
call "%RCU%" -trace INFO Bootstrap "profile ready"

rem これだけ返せば十分（SetingPathはRun側で呼ぶ）
call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
exit /b %errorlevel%