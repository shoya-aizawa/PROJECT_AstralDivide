@echo off
chcp 65001 >nul
pushd "%~dp0" >nul || (
    echo [ERROR] Failed to set execution directory.
    pause
    exit /b 1
)

echo ===================================================
echo  AstralDivide Line Ending Refresher (LF -^> CRLF)
echo ===================================================
echo.
echo Refreshing all *.bat files in the project...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RefreshLineEndingToCRLF.ps1"

echo.
echo Refresh completed successfully.
echo ===================================================