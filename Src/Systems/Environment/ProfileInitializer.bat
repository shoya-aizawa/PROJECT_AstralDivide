@echo off
setlocal EnableDelayedExpansion
:: ==========================================================
::  ProfileInitializer.bat (RCS Integrated)
::  by HedgeHogSoft / PROJECT_AstralDivide
:: ----------------------------------------------------------
::  Role:
::  - load or create user profile (first launch detection)
::  Dependency:
::  - RCS_Util.bat / RCS_Const.bat preloaded by Run.bat
:: ==========================================================

call "%RCSU%" -trace INFO "ProfileInitializer" "init start"

set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"

if not exist "%CFG_DIR%" (
    md "%CFG_DIR%" 2>nul
    call "%RCSU%" -trace INFO "ProfileInitializer" "created config dir at {%CFG_DIR%}"
) else (
    call "%RCSU%" -trace INFO "ProfileInitializer" "config dir exists at {%CFG_DIR%}"
)

:: ===================== Main Flow =====================
if exist "%CFG_FILE%" (
    call "%RCSU%" -trace INFO "ProfileInitializer" "profile found in {%CFG_FILE%}"
    call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
    if %errorlevel%==1 (
        call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "faild to parse profile"
        exit /b %errorlevel%
    )
    goto :ProfileReady
)

:: First boot sequence
call "%RCSU%" -trace INFO "ProfileInitializer" "first launch detected"
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat"
echo %errorlevel%
echo %rcs_code%
if %errorlevel%==1 (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_OTHER% 013 "language setup failed"
    exit /b %errorlevel%
)

echo smoke test passed SetupLanguage.bat
pause