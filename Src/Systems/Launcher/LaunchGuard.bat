@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem -----------------------------------------------------------------------------
rem LaunchGuard.bat  (RCU/RC 対応版)
rem Role:
rem   - Startup protection (direct launch prohibited)
rem   - PROJECT_ROOT validation
rem RC:
rem   ERR/SYS/VALID/001 → 9-06-30-001 : direct launch prohibited
rem   ERR/SYS/VALID/002 → 9-06-30-002 : PROJECT_ROOT invalid
rem   FLOW/SYS/OTHER/000 → 1-06-90-000 : OK
rem -----------------------------------------------------------------------------

rem === Resolve PROJECT_ROOT（引数/小文字/相対パスの保険）===
if not defined PROJECT_ROOT if not "%~1"=="" set "PROJECT_ROOT=%~1"
if not defined PROJECT_ROOT if defined project_root set "PROJECT_ROOT=%project_root%"
if not defined PROJECT_ROOT (
   set "PROJECT_ROOT=%~dp0..\..\.."
   for %%# in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~f#"
)

rem === 定数 & RCU 読み込み（直叩きでも自律する最小保険付き）===
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" 2>nul
if not defined rc_s_flow  set rc_s_flow=1
if not defined rc_s_err   set rc_s_err=9
if not defined rc_d_sys   set rc_d_sys=06
if not defined rc_r_valid set rc_r_valid=30
if not defined rc_r_other set rc_r_other=90

if not defined RCU set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
if not exist "%RCU%" (
   echo [LaunchGuard] RCU not found: "%RCU%"
   exit /b 1
)

rem === 8桁RCをあらかじめ生成（等価判定に使うなら便利）===
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_err%  %rc_d_sys% %rc_r_valid% 001') do set "RC_ERR_DIRECT=%%R"
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_err%  %rc_d_sys% %rc_r_valid% 002') do set "RC_ERR_PROOT=%%R"
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_flow% %rc_d_sys% %rc_r_other% 000') do set "RC_OK=%%R"

rem === ログ：このモジュール名で残す（必要に応じて外してOK）===
set "LOG_PREFIX=guard"
call "%RCU%" -trace INFO LaunchGuard "start PROJECT_ROOT=%PROJECT_ROOT%"

rem === Guard #1: 直叩き禁止（親ランチャが GAME_LAUNCHER を渡す想定）===
if not defined GAME_LAUNCHER (
   rem ユーザー直叩き時だけ案内と一時停止（Run.bat 経由では非表示）
   if not defined SUPPRESS_LAUNCHGUARD_UI (
      for /f %%e in ('cmd /k prompt $e^<nul') do set "ESC=%%e"
      echo %ESC%[31m[E1200]%ESC%[0m Do not run this directly. Use %ESC%[92m"AstralDivide.bat"%ESC%[0m
      if not defined NO_PAUSE pause >nul
   )
   call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_valid% 001 "direct launch prohibited" "entry=LaunchGuard"
)

rem === Guard #2: PROJECT_ROOT の妥当性（Main.bat があるか）===
if not exist "%PROJECT_ROOT%\Src\Main\Main.bat" (
   if not defined SUPPRESS_LAUNCHGUARD_UI (
      for /f %%e in ('cmd /k prompt $e^<nul') do set "ESC=%%e"
      echo %ESC%[31m[E1201]%ESC%[0m Invalid PROJECT_ROOT: "%PROJECT_ROOT%"
      if not defined NO_PAUSE pause >nul
   )
   call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_valid% 002 "PROJECT_ROOT=%PROJECT_ROOT%" "missing=Src\Main\Main.bat"
)

rem === OK（規格RCを返す）===
call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
