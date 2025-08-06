@echo off
setlocal enabledelayedexpansion

:: RenderMarkup_v2.3.bat

:: 引数1: タグ付き文字列

:: 引数2: 出力変数名

set "line=%~1"
set "output="

:: ANSIエスケープ取得

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"
set "ESC_ESC=%ESC%"

:: ===== スタイル・色タグのラベル置換（マップを明示呼び出し） =====

call :ReplaceTag "bold"         "1"
call :ReplaceTag "underline"    "4"
call :ReplaceTag "reverse"      "7"
call :ReplaceTag "reset"        "0"

call :ReplaceTag "black"        "30"
call :ReplaceTag "red"          "31"
call :ReplaceTag "green"        "32"
call :ReplaceTag "yellow"       "33"
call :ReplaceTag "blue"         "34"
call :ReplaceTag "magenta"      "35"
call :ReplaceTag "cyan"         "36"
call :ReplaceTag "white"        "37"

call :ReplaceTag "bg_black"     "40"
call :ReplaceTag "bg_red"       "41"
call :ReplaceTag "bg_green"     "42"
call :ReplaceTag "bg_yellow"    "43"
call :ReplaceTag "bg_blue"      "44"
call :ReplaceTag "bg_magenta"   "45"
call :ReplaceTag "bg_cyan"      "46"
call :ReplaceTag "bg_white"     "47"

call :ReplaceTag "hi_black"     "90"
call :ReplaceTag "hi_red"       "91"
call :ReplaceTag "hi_green"     "92"
call :ReplaceTag "hi_yellow"    "93"
call :ReplaceTag "hi_blue"      "94"
call :ReplaceTag "hi_magenta"   "95"
call :ReplaceTag "hi_cyan"      "96"
call :ReplaceTag "hi_white"     "97"

call :ReplaceTag "bg_hi_black"     "100"
call :ReplaceTag "bg_hi_red"       "101"
call :ReplaceTag "bg_hi_green"     "102"
call :ReplaceTag "bg_hi_yellow"    "103"
call :ReplaceTag "bg_hi_blue"      "104"
call :ReplaceTag "bg_hi_magenta"   "105"
call :ReplaceTag "bg_hi_cyan"      "106"
call :ReplaceTag "bg_hi_white"     "107"

:: ===== mix:fg:bg タグ展開 =====

for /f "tokens=2,3 delims=:{}" %%f in ("!line!") do (
   set "fg=%%f"
   set "bg=%%g"
   call :get_fg_code !fg! fg_code
   call :get_bg_code !bg! bg_code
   call set "line=%%line:{mix:!fg!:!bg!}=%ESC_ESC%[!fg_code!;!bg_code!m%%"
   call set "line=%%line:{/mix}=%ESC_ESC%[0m%%"
)

:: ===== 変数展開 =====

set "output="
:expand_loop
set "found="
set "working=!line!"
for /f "tokens=1* delims={" %%A in ("!working!") do (
    set "prefix=%%A"
    set "rest=%%B"
    set "output=!output!!prefix!"
    if defined rest (
        for /f "tokens=1 delims=}" %%X in ("!rest!") do (
            set "tag=%%X"
            set "tagname=!tag:*var:=!"
            call call set "value=%%%%!tagname!%%%%"
            set "output=!output!!value!"
            set "line=!rest:*}=!"
            set "found=1"
        )
    )
)
if defined found goto expand_loop

endlocal & set "%~2=%output%"
exit /b 0

:ReplaceTag
:: 引数1: タグ名 / 引数2: ANSI番号

setlocal
set "tag=%~1"
set "code=%~2"
endlocal & (
    call set "line=%%line:{%tag%}=%ESC_ESC%[%code%m%%"
    call set "line=%%line:{/%tag%}=%ESC_ESC%[0m%%"
)
exit /b 0

:get_fg_code
if /i "%~1"=="black"    (set "%~2=30") & exit /b
if /i "%~1"=="red"      (set "%~2=31") & exit /b
if /i "%~1"=="green"    (set "%~2=32") & exit /b
if /i "%~1"=="yellow"   (set "%~2=33") & exit /b
if /i "%~1"=="blue"     (set "%~2=34") & exit /b
if /i "%~1"=="magenta"  (set "%~2=35") & exit /b
if /i "%~1"=="cyan"     (set "%~2=36") & exit /b
if /i "%~1"=="white"    (set "%~2=37") & exit /b
exit /b

:get_bg_code
if /i "%~1"=="black"    (set "%~2=40") & exit /b
if /i "%~1"=="red"      (set "%~2=41") & exit /b
if /i "%~1"=="green"    (set "%~2=42") & exit /b
if /i "%~1"=="yellow"   (set "%~2=43") & exit /b
if /i "%~1"=="blue"     (set "%~2=44") & exit /b
if /i "%~1"=="magenta"  (set "%~2=45") & exit /b
if /i "%~1"=="cyan"     (set "%~2=46") & exit /b
if /i "%~1"=="white"    (set "%~2=47") & exit /b
exit /b