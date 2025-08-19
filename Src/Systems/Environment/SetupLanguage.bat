@echo off
setlocal EnableExtensions
rem -----------------------------------------------------------------------------
rem SetupLanguage.bat (RCU/RC integrated version)
rem Role:
rem Language selection (ja-JP / en-US) - Persisted to profile.env (maintains other keys)
rem Arguments: None (Autonomous even if PROJECT_ROOT/CFG_DIR is undefined)
rem RC:
rem FLOW/SYS/OTHER/000 - 1-06-90-000: OK
rem CANCEL/SYS/SELECTION/002 - 8-06-01-002: User canceled
rem ERR/SYS/PARSE/011 - 9-06-11-011: Failed to read or parse profile.env
rem ERR/SYS/I/O/012 - 9-06-10-012: Write-back failure, etc. I/O
rem -----------------------------------------------------------------------------

rem === PROJECT_ROOT / CFG_DIR 解決（直叩きでも自律） ========================
if not defined PROJECT_ROOT for %%I in ("%~dp0\..\..\..") do set "PROJECT_ROOT=%%~fI"
if defined CFG_DIR ( set "_cfg=%CFG_DIR%" ) else ( set "_cfg=%PROJECT_ROOT%\Config" )
set "_profile=%_cfg%\profile.env"
if not exist "%_cfg%" md "%_cfg%" 2>nul

rem === RCU/RECS bootstrap ======================================================
if not defined RCU set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" 2>nul
if not defined rc_s_flow    set rc_s_flow=1
if not defined rc_s_cancel  set rc_s_cancel=8
if not defined rc_s_err     set rc_s_err=9
if not defined rc_d_sys     set rc_d_sys=06
if not defined rc_r_select  set rc_r_select=01
if not defined rc_r_parse   set rc_r_parse=11
if not defined rc_r_io      set rc_r_io=10
if not defined rc_r_other   set rc_r_other=90

set "LOG_PREFIX=lang"
call "%RCU%" -trace INFO SetupLanguage "start cfg=%_cfg%"

rem === ANSI ESC / UTF-8（見栄え用、無くてもOK） ============================
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"
chcp 65001 >nul

:Select_Language
rem cls
echo.
echo === Language Setup ===
echo Select language / 言語を選択してください:
echo   [1] 日本語 (ja-JP)
echo   [2] English (en-US)
echo   [0] Cancel / キャンセル
set /p "_pick=> "
if "%_pick%"=="2" (
   set "LANGUAGE=en-US"
) else if "%_pick%"=="1" (
   set "LANGUAGE=ja-JP"
) else if "%_pick%"=="0" (
   call "%RCU%" -return %rc_s_cancel% %rc_d_sys% %rc_r_select% 002
) else (
   echo Invalid selection. / 無効な選択です。
   timeout /t 1 >nul
   goto :Select_Language
)

echo %esc%[92m[OK]%esc%[0m LANGUAGE=%LANGUAGE%
timeout /t 1 >nul

rem --- 既存のprofile.envを読み込み（他キーを保持） --------------------------
if exist "%_profile%" call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%_profile%" || (
   call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "LoadEnv failed" "file=%_profile%"
)
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"

rem --- 原子的に書き戻し（tmp→move） ----------------------------------------
> "%_profile%.tmp" (
   echo # Astral Divide profile [auto written by SetupLanguage.bat]
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   if defined SAVE_MODE echo set "SAVE_MODE=%SAVE_MODE%"
   if defined SAVE_DIR  echo set "SAVE_DIR=%SAVE_DIR%"
)
move /y "%_profile%.tmp" "%_profile%" >nul || (
   del /q "%_profile%.tmp" >nul 2>&1
   call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io% 012 "profile write failed" "file=%_profile%"
)

rem --- 親にも返す（LANGUAGEを昇格） ----------------------------------------
endlocal & (
   set "LANGUAGE=%LANGUAGE%"
) & call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
