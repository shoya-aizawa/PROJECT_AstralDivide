@echo off & setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cls

rem ===== 引数: 1=IPC_DIR(任意) 2=TITLE(任意) =====
if "%~1"=="" (
  if defined runtime_ipc_dir (set "IPC_DIR=%runtime_ipc_dir%") else set "IPC_DIR=%PROJECT_ROOT%\Runtime\IPC"
) else (
  set "IPC_DIR=%~1"
)
for %%A in ("%IPC_DIR%") do set "IPC_DIR=%%~fA"

set "TITLE=%~2"
if not defined TITLE set "TITLE=AstralDivide[v0.1.0]"

rem 監視ディレクトリだけ確保
if not exist "%IPC_DIR%" md "%IPC_DIR%" >nul 2>&1

echo [WD] start  ipc=%IPC_DIR%
echo [WD] target title="%TITLE%"
echo [WD] press Ctrl+C to exit

:loop
rem タイトル照合（リテラル検索 /L を明示）
tasklist /v /fi "IMAGENAME eq cmd.exe" | findstr /I /L /C:"%TITLE%" >nul
if errorlevel 1 (
  echo [!time!] miss
) else (
  echo [!time!] alive
)

if exist "%IPC_DIR%\.stop" goto :stop
timeout /t 1 >nul
goto :loop

:stop
echo [WD] stop
exit /b 0
