@echo off
rem setlocal EnableExtensions EnableDelayedExpansion
rem -----------------------------------------------------------------------------
rem LoadEnv.bat  (RCSU/RC 統合版)
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
if "%ENV_FILE%"==""              call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO%    012 "arg missing"
if not exist "%ENV_FILE%"        call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO%    012 "not found: %ENV_FILE%"


if exist "%ENV_FILE%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        set "%%A=%%B"
        call "%RCSU%" -trace INFO "%~n0" "loaded {%%A}={%%B}"
    )
)

rem === 完了 ===
if defined esc (
  echo %esc%[92m[OK]%esc%[0m user_config.env file has been loaded
  echo PROFILE_SCHEMA=%PROFILE_SCHEMA%
  echo CODEPAGE=%CODEPAGE%
  echo LANGUAGE=%LANGUAGE%
  echo SAVE_MODE=%SAVE_MODE%
  echo SAVE_DIR=%SAVE_DIR%
) else (
  echo [OK] user_config.env file has been loaded
)
call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000
