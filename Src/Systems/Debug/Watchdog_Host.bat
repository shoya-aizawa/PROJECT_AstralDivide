@echo off & setlocal EnableDelayedExpansion
set "ROOT=%PROJECT_ROOT%"
set "IPC=%ROOT%\Runtime\ipc"

:loop
for /f "usebackq delims=" %%L in ("%IPC%\.mode") do set "MODE=%%L" 2>nul

rem ---- センチネル（常時）：Mainの生存/クラッシュ検出・簡易ログ ----
rem TODO: .pid 心拍確認、異常終了の記録など
%tools_dir%\cmdwiz.exe delay 10
:: Check if Main.bat is running
tasklist /fi "windowtitle eq AstralDivide[v0.1.0]" | find /i "cmd.exe" >nul
if %errorlevel%==0 (
   cls
   echo [%launch_time%]
   echo [WD] Main.bat is launched!
   echo [%time%]
   echo [WD] Main.bat is running...
   goto :loop
) else if %errorlevel%==1 (
   echo [%time%]
   echo [WD] Main.bat has exited!
)

rem ---- ホスト（INTERCEPTのみ）：RVPディスパッチ ----
if /i "%MODE%"=="INTERCEPT" (
   for %%F in ("%IPC%\events\*.rvp") do call :handle "%%~fF"
)
timeout /t 0 /nobreak >nul & goto :loop

:handle
set "F=%~1"
for /f "usebackq tokens=1,* delims==" %%A in (`type "%F%"`) do set "%%A=%%B"
for %%P in ("%~dp0Plugins\*.bat") do (
   call "%%~fP"
   if defined ACTION (
      > "%IPC%\replies\%~nF.ack" (echo ACTION=!ACTION!&echo PAYLOAD=!PAYLOAD!&echo TTL_MS=!TTL_MS!)
      set ACTION=&set PAYLOAD=&set TTL_MS=& goto :done
   )
)
:done
del "%F%" >nul 2>&1 & exit /b
