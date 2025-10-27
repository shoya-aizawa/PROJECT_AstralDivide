@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem =============================================================================
rem SetupStorageWizard.bat (RCS-integrated Edition)
rem Role:
rem   Determines the storage location (AppData / Project / Custom)
rem   Persists to profile.env while preserving other keys
rem -----------------------------------------------------------------------------
rem RC MAP:
rem   1-06-90-000 : OK (Normal flow)
rem   8-06-01-002 : User canceled
rem   9-06-10-012 : Directory creation/write failure
rem =============================================================================

for /l %%i in (40,1,80) do (
    mode con cols=%%i lines=15
)

call "%RCSU%" -trace INFO "%~n0" "start setup storage wizard"



rem --- UI ---------------------------------------------------------------------
echo.
echo === Save Location Wizard ===
echo  1) AppData (per-user)  … %LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves
echo  2) Project folder      … %PROJECT_ROOT%\Saves  (portable)
echo  3) Custom path         … 任意の絶対パス（^> 空Enter でキャンセル）
choice /c 123 /n /m "Select [1/2/3]: "
set "_opt=%errorlevel%"

if "%_opt%"=="1" (
    set "_sv_mode=localappdata"
    set "_sv_dir=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
) else if "%_opt%"=="2" (
    set "_sv_mode=portable"
    set "_sv_dir=%PROJECT_ROOT%\Saves"
) else (
    set "_sv_mode=custom"
    set /p "_sv_dir=Enter absolute path (blank=cancel): "
    if not defined _sv_dir (
        call "%RCSU%" -return %RCS_S_CANCEL% %RCS_D_SYS% %RCS_R_SELECT% 002 "user canceled"
        exit /b %errorlevel%
    )
)

rem --- Normalize path ---------------------------------------------------------
for %%A in ("%_sv_dir%") do set "_sv_dir=%%~fA"

rem --- Create directory + write test ------------------------------------------
if not exist "%_sv_dir%" md "%_sv_dir%" 2>nul
if not exist "%_sv_dir%" (
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "mkdir failed" "dir=%_sv_dir%"
    exit /b %errorlevel%
)
set "_t=%_sv_dir%\.__permtest__"
2>nul ( >"%_t%" echo . ) || (
    del /q "%_t%" >nul 2>&1
    call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_IO% 012 "write failed" "dir=%_sv_dir%"
    exit /b %errorlevel%
)
del /q "%_t%" >nul 2>&1

rem --- Load existing profile.env ----------------------------------------------
if exist "%_profile%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%_profile%") do (
        if defined %%A set "%%A=%%B"
    )
)
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"

rem --- Atomic writeback (preserve others) -------------------------------------
> "%_profile%.tmp" (
    echo # Astral Divide profile [auto-written by SetupStorageWizard.bat]
    echo PROFILE_SCHEMA=%PROFILE_SCHEMA%
    echo CODEPAGE=%CODEPAGE%
    echo LANGUAGE=%LANGUAGE%
    echo SAVE_MODE=%_sv_mode%
    echo SAVE_DIR=%_sv_dir%
)
move /y "%_profile%.tmp" "%_profile%" >nul

rem --- Return / Elevate vars --------------------------------------------------
endlocal & (
    set "SAVE_MODE=%_sv_mode%"
    set "SAVE_DIR=%_sv_dir%"
) & call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000 "storage wizard complete"
exit /b %errorlevel%


