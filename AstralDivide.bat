@echo off
chcp 65001 >nul
pushd "%~dp0" >nul || (
	echo [E1001] Failed to enter project directory.
	pause >nul
	exit /b 1001
	rem TODO : The error code is tentative
)& rem ? below code has Normalized to no trailing backslash
for %%A in (.) do set "PROJECT_ROOT=%%~fA"

:: --- VT activation is just once go (continue even if it fails)---
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: --- "Launch token" for direct launch prevention (verified on Run.bat side) ---
set "GAME_LAUNCHER=1"

:: --- Call the game itself (maintains the route, passes arguments directly) ---
call "%PROJECT_ROOT%\Src\Main\Run.bat" %~1 %~2




rem TODO LISTS:
rem - Implement signature verification in Src/Systems/Security/VerifySignatures.bat and call it from Run.bat
rem - Implement cleanup of temporary files in the IPC directory in Run.bat

rem - COnsider exception handling for registry write failures in VT activation
rem - Finalize error codes used in AstralDivide.bat and Run.bat

rem - tentative error code used in directory change failure: 1001