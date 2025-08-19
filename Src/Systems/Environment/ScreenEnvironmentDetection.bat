@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem -----------------------------------------------------------------------------
rem ScreenEnvironmentDetection.bat  (RCU/RC 統合版)
rem Role:
rem   - 画面解像度/コンソールサイズ検出、推定フォントサイズ算出
rem   - 結果を Config\Cache\Screen\<COMPUTERNAME>\screen_config.env に保存
rem RC:
rem   FLOW/SYS/OTHER/000      → 1-06-90-000 : OK
rem   ERR /SYS/COMPAT/021     → 9-06-50-021 : PowerShell unavailable / exec failed
rem   ERR /SYS/COMPAT/022     → 9-06-50-022 : cmdwiz.exe unavailable (warn and continue)
rem   ERR /SYS/PARSE /011     → 9-06-11-011 : numeric parse failed / zero division risk
rem   ERR /SYS/I/O   /012     → 9-06-10-012 : config write failed
rem -----------------------------------------------------------------------------

rem === PROJECT_ROOT / CFG_DIR の自己解決 =======================================
if not defined PROJECT_ROOT for %%I in ("%~dp0\..\..\..") do set "PROJECT_ROOT=%%~fI"
if defined CFG_DIR (set "_cfg=%CFG_DIR%") else set "_cfg=%PROJECT_ROOT%\Config"

rem ★ ここから追加（健全性チェック＆絶対パス化）
if not defined _cfg (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_other% 013 "_cfg undefined"
)
for %%A in ("%_cfg%") do set "_cfg=%%~fA"

set "_screen_dir=%_cfg%\Cache\Screen\%COMPUTERNAME%"
set "_screen_file=%_screen_dir%\screen_config.env"

rem ディレクトリ作成（標準出力/標準エラーともに抑制）
if not exist "%_screen_dir%" md "%_screen_dir%" >nul 2>&1

rem トレースで中身を確認
call "%RCU%" -trace INFO ScreenEnv "paths cfg=[%_cfg%] dir=[%_screen_dir%] file=[%_screen_file%]"



rem === RCU/RECS bootstrap =======================================================
if not defined RCU set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" 2>nul
if not defined rc_s_flow   set rc_s_flow=1
if not defined rc_s_err    set rc_s_err=9
if not defined rc_d_sys    set rc_d_sys=06
if not defined rc_r_compat set rc_r_compat=50
if not defined rc_r_parse  set rc_r_parse=11
if not defined rc_r_io     set rc_r_io=10
if not defined rc_r_other  set rc_r_other=90
for /f "delims=" %%R in ('call "%RCU%" -build %rc_s_flow% %rc_d_sys% %rc_r_other% 000') do set "RC_OK=%%R"

rem === ログ & ESC ==============================================================
set "LOG_PREFIX=env"
call "%RCU%" -trace INFO ScreenEnv "start cfg=%_cfg%"
for /f %%a in ('cmd /k prompt $e^<nul') do set "esc=%%a"
mode 80,25

rem === Tools / PowerShell 可用性チェック =======================================
if not defined tools_dir set "tools_dir=%PROJECT_ROOT%\Tools"
set "HAS_CMDWIZ=0"
if exist "%tools_dir%\cmdwiz.exe" set "HAS_CMDWIZ=1"
if "%HAS_CMDWIZ%"=="0" call "%RCU%" -trace WARN ScreenEnv "cmdwiz.exe not found at %tools_dir% (will degrade)"

rem PowerShell 確認（簡易）
powershell -NoProfile -Command "$PSVersionTable.PSVersion" >nul 2>&1
if errorlevel 1 (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_compat% 021 "PowerShell unavailable"
)

rem === 画面描画: ヘッダ ========================================================
echo %esc%[2J%esc%[1;1H
echo %esc%[93m   ===========================================   %esc%[0m
echo %esc%[93m    Screen Environment Detection System ver.1    %esc%[0m
echo %esc%[93m   ===========================================   %esc%[0m
echo.

if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 0. Full-screen（あればON→最後にOFF）
if "%HAS_CMDWIZ%"=="1" (
  echo %esc%[96m  [0] Enabling fullscreen mode...%esc%[0m
  "%tools_dir%\cmdwiz.exe" fullscreen 1
  call "%RCU%" -trace INFO ScreenEnv "fullscreen=on rc=%errorlevel%"
  echo %esc%[92m   [OK] Fullscreen mode enabled%esc%[0m
  if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10
)

rem 1. Screen resolution（PowerShell）
echo %esc%[96m  [1] Detecting screen resolution...%esc%[0m
set "screen_width=" & set "screen_height="
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $s=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; Write-Output $($s.Width); Write-Output $($s.Height)"`) do (
  if not defined screen_width (set "screen_width=%%a") else set "screen_height=%%a"
)
rem 数値チェック
set "BAD="
for /f "delims=0123456789" %%x in ("%screen_width%%screen_height%") do set BAD=1
if "%screen_width%"=="" set BAD=1
if "%screen_height%"=="" set BAD=1
if defined BAD (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "screen size parse failed" "W=%screen_width% H=%screen_height%"
)
echo %esc%[92m   [OK] Screen resolution: %screen_width% x %screen_height%%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 2. Console window size（PowerShell）
echo %esc%[96m  [2] Detecting console window size...%esc%[0m
set "console_width=" & set "console_height="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$host.UI.RawUI.WindowSize.Width"') do set console_width=%%a
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$host.UI.RawUI.WindowSize.Height"') do set console_height=%%a
set "BAD="
for /f "delims=0123456789" %%x in ("%console_width%%console_height%") do set BAD=1
if "%console_width%"=="" set BAD=1
if "%console_height%"=="" set BAD=1
if defined BAD (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "console size parse failed" "W=%console_width% H=%console_height%"
)
echo %esc%[92m   [OK] Console Size: %console_width% x %console_height%%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 3. Font Size Estimation（除算ゼロガード）
echo %esc%[96m  [3] Estimating text size...%esc%[0m
if "%console_width%"=="0"  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "div0 console_width"
if "%console_height%"=="0" call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_parse% 011 "div0 console_height"
set /a char_width_est=screen_width/console_width
set /a char_height_est=screen_height/console_height
echo %esc%[92m   [OK] Estimated text size: %char_width_est% x %char_height_est% ピクセル%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 4. Generate the environment file
echo %esc%[96m  [4] Generating configuration files...%esc%[0m
call :Generate_Environment_Config || (
  call "%RCU%" -throw %rc_s_err% %rc_d_sys% %rc_r_io% 012 "write screen_config.env failed" "file=%_screen_file%"
)
echo %esc%[92m   [OK] Environment setting file generation completed%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 5. Compatibility Testing（cmdwiz無ければ簡略化）
echo %esc%[96m  [5] Running a display compatibility test%esc%[0m
call :Run_Compatibility_Test
echo %esc%[19;1H%esc%[92m   [OK] Compatibility test completed%esc%[0m
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10

rem 6. Complete（フルスクリーン解除）
if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" fullscreen 0
echo %esc%[2J%esc%[1;1H
echo.
echo %esc%[93m   ===========================================   %esc%[0m
echo %esc%[93m               Detection complete.               %esc%[0m
echo %esc%[93m   ===========================================   %esc%[0m
echo.
timeout /t 1 >nul

call "%RCU%" -trace INFO ScreenEnv "ok W=%screen_width% H=%screen_height% CW=%console_width% CH=%console_height%"
call "%RCU%" -return %rc_s_flow% %rc_d_sys% %rc_r_other% 000
exit /b %errorlevel%

rem ============================== Subroutines ===============================

:Generate_Environment_Config
  rem ディレクトリ確保（安全側）
  if not exist "%_screen_dir%" md "%_screen_dir%" >nul 2>&1

  set "_tmp=%_screen_file%.tmp"
  if exist "%_tmp%" del /q "%_tmp%" >nul 2>&1

  rem 一時ファイルに書き出し（失敗なら 1 を返す）
  > "%_tmp%" (
    echo rem auto-generated by ScreenEnvironmentDetection.bat
    echo rem date: %date% %time%
    echo.
    echo rem Screen resolution [px]
    echo set SCREEN_WIDTH=%screen_width%
    echo set SCREEN_HEIGHT=%screen_height%
    echo.
    echo rem Console size [chars]
    echo set CONSOLE_WIDTH=%console_width%
    echo set CONSOLE_HEIGHT=%console_height%
    echo.
    echo rem Estimated font size [px per char]
    echo set CHAR_WIDTH_EST=%char_width_est%
    echo set CHAR_HEIGHT_EST=%char_height_est%
    echo.
    echo rem Classification
    if %screen_width% LEQ 1366 (
      echo set SCREEN_CLASS=SMALL
      echo set UI_SCALE=0.8
    ) else if %screen_width% LEQ 1920 (
      echo set SCREEN_CLASS=MEDIUM
      echo set UI_SCALE=1.0
    ) else (
      echo set SCREEN_CLASS=LARGE
      echo set UI_SCALE=1.2
    )
    echo.
    echo rem Hints
    echo set COMPUTER=%COMPUTERNAME%
    echo set PROBED_AT=%date% %time%
  ) || exit /b 1

  rem 読取専用解除（あれば）
  if exist "%_screen_file%" attrib -R "%_screen_file%" >nul 2>&1

  rem 置き換え（失敗なら 1）
  move /y "%_tmp%" "%_screen_file%" >nul 2>&1 || exit /b 1

  exit /b 0



:Run_Compatibility_Test
  rem cmdwiz が無くても最低限の描画は実施
  set /a w=console_width-1
  set /a h=console_height-1
  set /a inner_w=w-2

  set "horiz="
  for /L %%i in (1,1,!inner_w!) do set "horiz=!horiz!─"

  echo !esc![93m   === Display Compatibility Test (Optimized: !w!×!h!) === !esc![0m
  echo !esc![93m    Check that the entire frame is displayed correctly!esc![0m
  echo.

  echo !esc![1;1H!esc![93m┌!horiz!┐!esc![0m
  for /L %%r in (2,1,!h!-1) do (
    echo !esc![%%r;1H!esc![93m│!esc![%%r;!w!H│!esc![0m
    if "%HAS_CMDWIZ%"=="1" "%tools_dir%\cmdwiz.exe" delay 10
  )
  echo !esc![!h!;1H!esc![93m└!horiz!┘!esc![0m

  timeout /t 1 >nul
  exit /b 0
