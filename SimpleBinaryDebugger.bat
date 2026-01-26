@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:MENU
echo ------------------------------------------
echo  簡易バイナリデバッガー (Batch/PS version)
echo ------------------------------------------
echo 1: ファイルを16進数で表示 (View)
echo 2: 特定のアドレスを書き換え (Edit)
echo 3: 終了
set /p "choice=select: "

if "%choice%"=="1" goto VIEW
if "%choice%"=="2" goto EDIT
if "%choice%"=="3" exit /b

:VIEW
set /p "filepath=表示するファイル名: "

set "PS_HEXDUMP=$bytes=[IO.File]::ReadAllBytes('%filepath%');"
set "PS_HEXDUMP=%PS_HEXDUMP% for($i=0;$i -lt $bytes.Length;$i+=16){"
set "PS_HEXDUMP=%PS_HEXDUMP% $hex='';$ascii='';"
set "PS_HEXDUMP=%PS_HEXDUMP% for($j=0;$j -lt 16 -and ($i+$j) -lt $bytes.Length;$j++){"
set "PS_HEXDUMP=%PS_HEXDUMP% $b=$bytes[$i+$j];"
set "PS_HEXDUMP=%PS_HEXDUMP% $hex+=('{0:X2} ' -f $b);"
set "PS_HEXDUMP=%PS_HEXDUMP% $ascii+=if($b -ge 32 -and $b -le 126){[char]$b}else{'.'}"
set "PS_HEXDUMP=%PS_HEXDUMP% }"
set "PS_HEXDUMP=%PS_HEXDUMP% '{0:X8}: {1,-48} |{2}|' -f $i,$hex,$ascii"
set "PS_HEXDUMP=%PS_HEXDUMP% }"

powershell -NoProfile -Command "%PS_HEXDUMP%"

pause
goto MENU


:EDIT
set /p "filepath=編集するファイル名: "
set /p "offset=アドレス(10進数で指定): "
set /p "value=書き込む値(0-255の10進数): "

powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('%filepath%'); $bytes[%offset%] = [byte]%value%; [System.IO.File]::WriteAllBytes('%filepath%', $bytes)"
echo 書き換えが完了しました。
pause
goto MENU