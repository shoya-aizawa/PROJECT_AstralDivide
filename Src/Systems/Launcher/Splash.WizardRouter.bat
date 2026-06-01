@echo off
::------------------------------------------------------------------------------
:: Splash.WizardRouter.bat
::------------------------------------------------------------------------------
:: Check for interactive setup wizard request (for first-time launch / WT warning)
set "TRIGGER_SETUP="
set "TRIGGER_WT_WARN="
if exist "%TEMP%\splash_ui_req.tmp" (
    findstr /i "NEED_SETUP" "%TEMP%\splash_ui_req.tmp" >nul
    if "!errorlevel!"=="0" set "TRIGGER_SETUP=1"
    findstr /i "NEED_WT_WARN" "%TEMP%\splash_ui_req.tmp" >nul
    if "!errorlevel!"=="0" set "TRIGGER_WT_WARN=1"
)

if "%TRIGGER_WT_WARN%"=="1" call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\WTWarningWizard.bat"

if not "%TRIGGER_SETUP%"=="1" goto SkipSetupTrigger
:: Import temporary environment validation cache to the parent shell
if exist "%TEMP%\ad_boot_diag_result.env" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%TEMP%\ad_boot_diag_result.env") do (
        set "%%A=%%B"
    )
    del "%TEMP%\ad_boot_diag_result.env" >nul 2>&1
)
call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\LanguageWizard.bat"
call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\FontWizard.bat"
call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\StorageWizard.bat"
:SkipSetupTrigger

:: Delete the request file AFTER all wizards and warnings have finished executing,
:: signaling to the background initializer that it is now safe to proceed!
if exist "%TEMP%\splash_ui_req.tmp" del "%TEMP%\splash_ui_req.tmp" >nul 2>&1
exit /b
