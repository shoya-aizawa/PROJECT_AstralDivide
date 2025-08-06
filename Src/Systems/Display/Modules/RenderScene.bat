@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: scene.txtの行を安全に渡す

for /f "eol=# usebackq delims=" %%L in ("scene.txt") do (
    set "line=%%L"
    call :ProcessLine "!line!"
)


echo.
echo.
echo. process terminate.
pause >nul
exit

:ProcessLine
call RenderControl_v2.3.bat "!line!"
exit /b
