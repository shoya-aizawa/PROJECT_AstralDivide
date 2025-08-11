@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem -----------------------------------------------------------------------------
rem LaunchGuard.bat  (RC v1)
rem Role:
rem   - Startup protection (direct launch prohibited) / 起動保護 (直叩き禁止)
rem   - PROJECT_ROOT validation                       / PROJECT_ROOT の妥当性確認
rem Returns (RC v1):
rem   ERR/SYS/VALID/001 → 9-06-30-001     : direct launch prohibited
rem   ERR/SYS/VALID/002 → 9-06-30-002     : PROJECT_ROOT invalid
rem   FLOW/SYS/OTHER/000 → 1-06-90-000    : OK
rem -----------------------------------------------------------------------------

set "project_root=%~1"
set "const_bat=%project_root%\Src\Systems\Debug\ReturnCodeConst.bat"
set "util_bat=%project_root%\Src\Systems\Debug\ReturnCodeUtil.bat"

rem Load constants/utilities (if not already loaded) / 定数/ユーティリティを(未ロードなら)ロード
if not defined rc_s_flow if exist "%const_bat%" call "%const_bat%"
if not exist "%util_bat%" (
  rem Fallback (fails in legacy code when utility is absent) / フォールバック(ユーティリティ不在時はレガシーコードで失敗)
  exit /b 90690001
)

rem Prevent direct launch (assuming the parent launcher sets and passes GAME_LAUNCHER)
if not defined GAME_LAUNCHER (
   echo %esc%[31m[E1200]%esc%[0m Do not run this directly. Use %esc%[92m"AstralDivide.bat"%esc%[0m
   pause >nul
   call "%util_bat%" _throw %rc_s_err% %rc_d_sys% %rc_r_valid% 001 "Direct invocation is prohibited" "hint=use AstralDivide.bat"
)

rem Validity of PROJECT_ROOT (checks existence of Main.bat)
if not exist "%project_root%\Src\Main\Main.bat" (
   echo %esc%[31m[E1201]%esc%[0m Invalid PROJECT_ROOT: "%project_root%"
   pause >nul
   call "%util_bat%" _throw %rc_s_err% %rc_d_sys% %rc_r_valid% 002 "Invalid PROJECT_ROOT" "arg=%project_root%"
)

rem OK
call "%util_bat%" _return %rc_s_flow% %rc_d_sys% %rc_r_other% 000 "LaunchGuard OK"
