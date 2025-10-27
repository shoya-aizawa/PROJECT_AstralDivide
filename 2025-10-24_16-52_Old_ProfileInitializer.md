@echo off
setlocal EnableDelayedExpansion
rem ==========================================================
rem  ProfileInitializer.bat
rem  PROJECT_AstralDivide / HedgeHogSoft
rem ----------------------------------------------------------
rem  Role:
rem    - Detect and load or create user profile (first run detection)
rem    - Initialize environment configuration (language, storage, schema)
rem    - Guarantee existence of SAVE_DIR and write normalized profile.env
rem
rem  Dependency:
rem    - RCS_Util.bat / RCS_Const.bat preloaded by Run.bat
rem    - SetupLanguage.bat / SetupStorageWizard.bat / ProfileLoader.bat
rem
rem  Return Code (RCS Format):
rem    1-06-90-000 : OK
rem    9-06-11-011 : profile parse failed (LoadEnv)
rem    9-06-10-012 : storage I/O error
rem    9-06-90-013 : language setup failed
rem ==========================================================

call "%RCSU%" -trace INFO "ProfileInitializer" "begin initialization"

:: ----------------------------------------------------------
:: Configuration path setup
:: ----------------------------------------------------------
set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"

:: ----------------------------------------------------------
:: Main routine: Detect or create profile
:: ----------------------------------------------------------
if exist "%CFG_FILE%" (
    call "%RCSU%" -trace INFO "ProfileInitializer" "profile detected: %CFG_FILE%"
    call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileLoader.bat" "%CFG_FILE%"
    if errorlevel 1 (
        call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "failed to parse profile" "file=%CFG_FILE%"
    )
    goto :ProfileReady
)

:: --- first boot sequence ---
call "%RCSU%" -trace INFO "ProfileInitializer" "first boot detected"
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat"
if errorlevel 1 (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_OTHER% 013 "language setup failed"
)

call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"
if errorlevel 1 (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "storage wizard failed"
)

if not exist "%CFG_DIR%" md "%CFG_DIR%" >nul 2>&1
call "%PROJECT_ROOT%\Src\Systems\Environment\ProfileLoader.bat" "%CFG_FILE%"
if errorlevel 1 (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_PARSE% 011 "profile reload failed"
)

:ProfileReady
:: ----------------------------------------------------------
:: Ensure SAVE_DIR exists and valid
:: ----------------------------------------------------------
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" >nul 2>&1
if not exist "%SAVE_DIR%" (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "failed to create SAVE_DIR" "dir=%SAVE_DIR%"
)

:: ----------------------------------------------------------
:: Write-back normalization
:: ----------------------------------------------------------
>"%CFG_FILE%" (
   echo # Astral Divide user profile
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   echo set "SAVE_MODE=%SAVE_MODE%"
   echo set "SAVE_DIR=%SAVE_DIR%"
)

call "%RCSU%" -trace INFO "ProfileInitializer" "profile ready: %CFG_FILE%"
call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000
exit /b %errorlevel%
