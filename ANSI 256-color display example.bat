@echo off
chcp 65001 >nul
rem CMDウィンドウサイズを画像に合わせる
mode con: cols=120 lines=40

call "C:\Users\shoya\Desktop\AstralDivide\Tools\cmdwiz.exe" fullscreen 1

rem ===== ANSI 256色カラー表示サンプル（Windows CMD） =====
setlocal EnableDelayedExpansion

rem --- ANSI (ESC/CSI) ---
for /F "delims=" %%E in ('echo prompt $E^| cmd') do set "ESC=%%E"
set "CSI=%ESC%["
set "RST=%CSI%0m"

rem ===== Header line (00 01 ... 0F )====
<nul set /p "=%CSI%38;5;245m   %RST%"
for /L %%c in (0,1,15) do (
  call :NibHex %%c H
  <nul set /p "=%CSI%38;5;245m !H!%RST% "
)
echo.

rem ===== Body 16 lines (00,10,...,F0 row label + value)====
for /L %%r in (0,1,15) do (
  call :NibHex %%r RH
  rem Row Labels (00,10,...,f0)
  <nul set /p "=%CSI%38;5;245m !RH!0 %RST%"
  for /L %%c in (0,1,15) do (
    set /a v=16*%%r+%%c
    call :ToHex !v! HX
    rem Let the text color be 256 color palette number v (the background remains black)
    <nul set /p "=%CSI%38;5;!v!m!HX!%RST% "
  )
  echo.
)

pause >nul
rem ======== [add] escape2-style vertical columns ========
echo.
rem -----Header line (00 01 ... 0F) -----
<nul set /p "=%CSI%38;5;245m   %RST%"
for /L %%c in (0,1,15) do (
  call :NibHex %%c H
  <nul set /p "=%CSI%38;5;245m !H!%RST% "
)
echo.

rem ----Body (row label + each cell is background color v, letters are HEX with v) -----
for /L %%r in (0,1,15) do (
  call :NibHex %%r RH
  <nul set /p "=%CSI%38;5;245m !RH!0 %RST%"
  for /L %%c in (0,1,15) do (
    set /a v=16*%%r+%%c
    call :ToHex !v! HX
    call :PickFG !v! FG
    <nul set /p "=%CSI%48;5;!v!m%CSI%38;5;!FG!m!HX!%RST% "
  )
  echo.
)

pause >nul
rem ========= RGB gradient display (escape3 equivalent) =========
echo.
echo %CSI%38;5;245mRGB Gradient Demo:%RST%
for /L %%i in (0,1,15) do (
  for /L %%j in (0,1,31) do (
    set /a r=%%i*16
    set /a g=%%j*8
    set /a b=255
    call :RGBPrint !r! !g! !b! X
  )
  echo.
)
call :ResetStyle

pause >nul
rem ========= RGB background gradient display (escape4 equivalent) =========
echo.
echo %CSI%38;5;245mBackground RGB Gradient Demo:%RST%
for /L %%i in (0,1,15) do (
  for /L %%j in (0,1,31) do (
    set /a r=%%i*16
    set /a g=%%j*8
    set /a b=255
    call :RGBBgPrint !r! !g! !b! " "
  )
  echo.
)
call :ResetStyle



pause >nul
endlocal
exit /b 0










rem ---1 digit (0-15) to HEX character (0-9A-F) ---
:NibHex
setlocal EnableDelayedExpansion
set "MAP=0123456789ABCDEF"
set "n=%~1"
for %%# in (!n!) do set "ch=!MAP:~%%#,1!"
endlocal & set "%~2=%ch%" & exit /b 0

rem ---0-255 → 2-digit HEX (e.g. 255 → FF) ---
:ToHex
setlocal EnableDelayedExpansion
set "MAP=0123456789ABCDEF"
set /a q=%~1/16, r=%~1%%16
set "h1=!MAP:~%q%,1!"
set "h2=!MAP:~%r%,1!"
endlocal & set "%~2=%h1%%h2%" & exit /b 0

rem ---Returns easy-to-read foreground color (0=black, 15=white) for background color v(0-255) ---
:PickFG
setlocal EnableDelayedExpansion
set "v=%~1"
set "fg=15"

rem 0–15 (standard color): Bright (8 15) is black, otherwise white
if %v% lss 16 (
  if %v% geq 8 (set "fg=0") else (set "fg=15")
  endlocal & set "%~2=%fg%" & exit /b 0
)

rem 16–231 (6x6x6 color cube): Simple threshold with r+g+b sum
if !v! leq 231 (
  set /a t=v-16
  set /a r=t/36
  set /a rem=t - r*36
  set /a g=rem/6
  set /a b=rem - g*6
  set /a sum=r+g+b
  if !sum! geq 9 (set "fg=0") else (set "fg=15")
  endlocal & set "%~2=%fg%" & exit /b 0
)

rem 232–255 (grayscale): anything lighter than mid-range is black, anything darker is white
if %v% geq 244 (set "fg=0") else (set "fg=15")
endlocal & set "%~2=%fg%" & exit /b 0

:RGBPrint
setlocal
set "r=%~1"
set "g=%~2"
set "b=%~3"
set "char=%~4"
<nul set /p "=%CSI%38;2;%r%;%g%;%b%m%char%%RST%"
endlocal & exit /b 0

:ResetStyle
<nul set /p "=%CSI%0m"
exit /b 0

:RGBBgPrint
setlocal
set "r=%~1"
set "g=%~2"
set "b=%~3"
set "char=%~4"
<nul set /p "=%CSI%48;2;%r%;%g%;%b%m%char%%RST%"
endlocal & exit /b 0
