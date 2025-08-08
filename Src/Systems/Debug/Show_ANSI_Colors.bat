@echo off
rem mode con: cols=150 lines=50
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ANSIエスケープ取得

for /f %%e in ('cmd /k prompt $e^<nul') do set "ESC=%%e"

cls
echo Colors (Format: [前景;背景]):
echo.

:: 列見出し（背景色）

%tools_dir%\cmdwiz.exe print "      "
for %%b in (40 41 42 43 44 45 46 47 100 101 102 103 104 105 106 107) do (
   set "code=%%b  "
   set "code=!code:~0,4!"
   <nul set /p="!code!"
)
echo.

:: 本体（前景×背景の組み合わせ）

for %%f in (30 31 32 33 34 35 36 37 90 91 92 93 94 95 96 97) do (
   <nul set /p ="%%f -> "
   for %%b in (40 41 42 43 44 45 46 47 100 101 102 103 104 105 106 107) do (
      set "STYLE=!ESC![%%f;%%b;1m"
      set "RESET=!ESC![0m"
      <nul set /p ="!STYLE!%%f;%%b!RESET!  "
   )
   echo.
)
endlocal

echo %ESC%[32m[OK]%ESC%[0m ANSI Colors Displayed

%tools_dir%\cmdwiz.exe delay 900

exit /b 0