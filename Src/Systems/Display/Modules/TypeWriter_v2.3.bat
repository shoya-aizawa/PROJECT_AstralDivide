@echo off

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

setlocal EnableDelayedExpansion

:: ESC定義（明示的に取得）

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

:: 引数1: テキスト / 引数2: 速度（ms）

set "line=%~1"
set "speed=%~2"
if not defined speed set "speed=100"
set /a i=0

:main_loop
set "prefix=!line:~%i%,2!"


:: ANSIシーケンス開始判定

if "!prefix!"=="!ESC![" (
    set "seq="
    :read_seq
    set "next=!line:~%i%,1!"
    if not defined next goto :done
    set "seq=!seq!!next!"
    set /a i+=1
    echo !next! | findstr /r "[A-Za-z]" >nul && (
        <nul set /p="!seq!"
        goto :main_loop
    )
    goto :read_seq
)

:: 通常文字出力

set "char=!line:~%i%,1!"
if not defined char goto :done
<nul set /p="!char!"
set /a i+=1
cmdwiz delay !speed!
goto :main_loop

:done
endlocal
exit /b
