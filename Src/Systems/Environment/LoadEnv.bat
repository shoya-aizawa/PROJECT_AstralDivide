@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem -----------------------------------------------------------------------------
rem LoadEnv.bat  (RCU/RC 統合版)
rem Usage : call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "C:\path\to\profile.env"
rem Format: lines like set "KEY=VALUE"
rem Comment lines must start with '#'
rem RC:
rem   FLOW/SYS/OTHER/000 → 1-06-90-000 : OK
rem   ERR /SYS/I/O   /012 → 9-06-10-012 : arg missing / file not found / SAVE_DIR I/O etc.
rem   ERR /SYS/PARSE /011 → 9-06-11-011 : invalid line format
rem -----------------------------------------------------------------------------

rem === Args & file existence ===
set "ENV_FILE=%~1"
if "%ENV_FILE%"==""              call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io%    012 "arg missing"
if not exist "%ENV_FILE%"        call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io%    012 "not found: %ENV_FILE%"

rem === 読み込み: # から始まる行はコメントとして無視 ===
rem ※ 値中の ! 展開を避けるため、読み込み中は delayed expansion を OFF
setlocal DisableDelayedExpansion
for /f "usebackq eol=# tokens=1,* delims= " %%A in ("%ENV_FILE%") do (
    if /i "%%A"=="set" (
        rem 例: 行が  set "KEY=VALUE" なら B= "KEY=VALUE"
        call set %%B
    ) else (
        endlocal & call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "bad line: %%A %%B"
    )
)
endlocal

rem === 完了 ===
if defined esc (
  echo %esc%[92m[OK]%esc%[0m profile.env file has been loaded
) else (
  echo [OK] profile.env file has been loaded
)
call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
