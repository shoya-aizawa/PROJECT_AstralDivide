:: ====================================================================
:: Bootstrap: load or create profile
:: This batch can also detect the first launch of the game.
:: Argument 1 (%~1) is set to %PROJECT_ROOT%
:: ====================================================================

set "CFG_DIR=%~1\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"

if exist "%CFG_FILE%" goto :HaveProfile
goto :FirstRun

:HaveProfile
echo %esc%[92m[OK]%esc%[0m Welcome back! profile.env exists
call "%~1\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || exit /b 90610011

:: --- Self-Repair defaults ---
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"
if /i not "%SAVE_MODE%"=="localappdata" if /i not "%SAVE_MODE%"=="portable" if /i not "%SAVE_MODE%"=="custom" set "SAVE_MODE=portable"
if not defined SAVE_DIR (
   if /i "%SAVE_MODE%"=="localappdata" (
      set "SAVE_DIR=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
   ) else if /i "%SAVE_MODE%"=="portable" (
      set "SAVE_DIR=%~1\Saves"
   ) else (
      call "%~1\Src\Systems\Environment\SetupStorageWizard.bat" || exit /b 90610012
      call "%~1\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || exit /b 90610011
   )
)
goto :ProfileReady

:FirstRun
echo %esc%[92m[WELCOME]%esc%[0m This is your first boot.
timeout /t 2 >nul
:: === First time: Language → Storage wizard (both persist to profile.env) ===
call "%~1\Src\Systems\Environment\SetupLanguage.bat"         || exit /b
call "%~1\Src\Systems\Environment\SetupStorageWizard.bat"    || exit /b 90610012

:: --- Re-sync from disk (the single source of truth) ---
if not exist "%CFG_DIR%" md "%CFG_DIR%" 2>nul
call "%~1\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"  || exit /b 90610011
:ProfileReady
:: --- Ensure SAVE_DIR exists; create if missing (errorlevelを見ない) ---
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
if not exist "%SAVE_DIR%" (
   echo %esc%[31m[WARN]%esc%[0m SAVE_DIR="%SAVE_DIR%" を作成できませんでした。再設定します。
   pause >nul
   call "%~1\Src\Systems\Environment\SetupStorageWizard.bat" || exit /b 90610012
   call "%~1\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || exit /b 90610011
   if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
   if not exist "%SAVE_DIR%" exit /b
)

:: --- Write-back normalization（引用付きで安全に）---
>"%CFG_FILE%" (
   echo # Astral Divide profile
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   echo set "SAVE_MODE=%SAVE_MODE%"
   echo set "SAVE_DIR=%SAVE_DIR%"
)

:Setting_Path
call "%~1\Src\Systems\Environment\SettingPath.bat"
exit /b 10690000