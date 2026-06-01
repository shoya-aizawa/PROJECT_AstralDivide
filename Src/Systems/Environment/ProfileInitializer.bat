@echo off
::: ==========================================================
:::  ProfileInitializer.bat (RCS Integrated)
:::  by HedgeHogSoft / PROJECT_AstralDivide
::: ----------------------------------------------------------
:::  Role:
:::  - load finalized user profile written by the splash wizard
:::  Dependency:
:::  - RCS_Util.bat / RCS_Const.bat preloaded by Run.bat
::: ==========================================================

set "PROJECT_ROOT=%~1"
if "%PROJECT_ROOT%"=="" (
    for %%A in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fA"
)
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"

call "%RCSU%" -trace INFO "%~n0" "init start"

set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\user_config.env"
if not exist "%CFG_DIR%" (
    md "%CFG_DIR%" 2>nul
    call "%RCSU%" -trace INFO "%~n0" "created config dir at {%CFG_DIR%}"
) else (
    call "%RCSU%" -trace INFO "%~n0" "config dir exists at {%CFG_DIR%}"
)

::: ===================== Main Flow =====================

if not exist "%CFG_FILE%" (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "profile missing after splash bootstrap"
    exit /b %errorlevel%
)

call "%RCSU%" -trace INFO "%~n0" "profile found in {%CFG_FILE%}"
call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
if not "%errorlevel%"=="%RC_OK%" (
    call "%RCSU%" -trace ERR "%~n0" "profile load failed rc=%errorlevel%"
    exit /b %errorlevel%
)

call "%RCSU%" -trace INFO "%~n0" "profile loaded successfully"
set "FIRST_LAUNCH=0"
exit /b %RC_OK%
