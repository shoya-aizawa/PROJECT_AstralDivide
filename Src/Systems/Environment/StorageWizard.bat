@echo off
setlocal

rem root_dir estimation (3 up from...\Src\Systems\Environment\)
for %%I in ("%~dp0\..\..\..") do set "root_dir=%%~fI"

set "env_dir=%~dp0"
set "storage_cfg=%env_dir%storage.env"

echo.
echo === Save Location Wizard ===
echo  1) AppData (per-user)  … %LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves
echo  2) Project folder      … %root_dir%\Saves   (portable; doesn't pollute C:)
echo  3) Custom path         … Any absolute path
echo.

choice /c 123 /n /m "Select [1/2/3]: "
set "opt=%errorlevel%"

if "%opt%"=="1" (
  set "target=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
  set "mode=APPDATA"
) else if "%opt%"=="2" (
  set "target=%root_dir%\Saves"
  set "mode=PORTABLE"
) else (
  set /p "target=Enter absolute path: "
  set "mode=CUSTOM"
)

rem Write test
set "testfile=%target%\.__write_test__"
2>nul ( >"%testfile%" echo test ) || (
  echo [ERROR] Cannot write to: "%target%"
  exit /b 1
)
del /q "%testfile%" >nul 2>&1

rem save
if not exist "%target%" md "%target%"
(
  echo ; Storage configuration (do not edit unless you know what you're doing)
  echo SAVE_MODE=%mode%
  echo SAVE_BASE=%target%
) > "%storage_cfg%"

echo Saved: %storage_cfg%
endlocal & exit /b 0
