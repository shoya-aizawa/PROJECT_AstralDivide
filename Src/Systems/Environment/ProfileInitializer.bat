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

call "%RCSU%" -trace INFO "%~n0" "init start"

set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"
if not exist "%CFG_DIR%" (
    md "%CFG_DIR%" 2>nul
    call "%RCSU%" -trace INFO "%~n0" "created config dir at {%CFG_DIR%}"
) else (
    call "%RCSU%" -trace INFO "%~n0" "config dir exists at {%CFG_DIR%}"
)

:: ===================== Main Flow =====================

:: Detect first launch by checking profile existence
if exist "%CFG_FILE%" (
    call "%RCSU%" -trace INFO "%~n0" "profile found in {%CFG_FILE%}"
    call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
    if %errorlevel%==1 (
        call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "faild to parse profile"
        exit /b %errorlevel%
    )
    goto :ProfileReady
)

:: First Launch Detected
:: Step [1] Setup Language
call "%RCSU%" -trace INFO "%~n0" "first launch detected"
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat"
set "rc=%errorlevel%"

:: Case1: Normal (FLOW)
if "%rc%"=="%RCS_S_FLOW%%RCS_D_SYS%%RCS_R_SELECT%000" (
    call "%RCSU%" -trace OK "%~n0" "language setup completed successfully"
)

:: Case2: User canceled (CANCEL)
if "%rc%"=="%RCS_S_CANCEL%%RCS_D_SYS%%RCS_R_SELECT%002" (
    call "%RCSU%" -trace INFO "%~n0" "language setup canceled by user"
)

:: Case3: Known error (invalid /lang etc.)
if "%rc%"=="9%RCS_D_SYS%%RCS_R_VALID%013" (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_VALID% 013 "language setup failed (invalid arg)"
)

:: Case4: Other / unknown error
if not "%rc%"=="0" (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_VALID% 999 "Unexpected return code from SetupLanguage [%rc%]"
    exit %errorlevel%
)



:: Step [2] Setup Storage (Save Location)
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"



pause



