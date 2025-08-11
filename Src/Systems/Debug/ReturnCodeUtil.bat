@echo on
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: rcutil.bat - RECS v1 command-line helper
:: Hyphen flags: -build / -decode / -return / -throw / -pretty / -trace
:: Legacy aliases kept: _BUILD/_DECODE/_RETURN/_THROW/_PRETTY/_TRACE

if "%~1"=="" (call :usage & exit /b 1)

set "cmd=%~1"
set "cmd=!cmd:/=-!" & rem /build も -build として扱う
if /i "!cmd!"=="-h"       (call :usage & exit /b 0)
if /i "!cmd!"=="--help"   (call :usage & exit /b 0)

shift /1
if /i "%cmd%"=="-build"  goto :build
if /i "%cmd%"=="-decode" goto :decode
if /i "%cmd%"=="-return" goto :return
if /i "%cmd%"=="-throw"  goto :throw
if /i "%cmd%"=="-pretty" goto :pretty
if /i "%cmd%"=="-trace"  goto :trace

>&2 echo [RECS] Unknown command: %cmd%
call :usage
exit /b 2

:build
rem Args: S DD RR CCC  または  "S-DD-RR-CCC"
if "%~2"=="" (
  set "spec=%~1"
  set "spec=%spec:"=%"
  for /f "tokens=1-4 delims=-" %%a in ("%spec%") do (set "S=%%a"&set "DD=%%b"&set "RR=%%c"&set "CCC=%%d"&goto :_build_go)
  >&2 echo [RECS] -build needs S-DD-RR-CCC or 4 tokens
  exit /b 3
) else (
  set "S=%~1"&set "DD=%~2"&set "RR=%~3"&set "CCC=%~4"
)
:_build_go
call :padnum %S%  1 S  || exit /b 3
call :padnum %DD% 2 DD || exit /b 3
call :padnum %RR% 2 RR || exit /b 3
call :padnum %CCC% 3 CCC || exit /b 3
set "CODE=%S%%DD%%RR%%CCC%"
echo %CODE%
exit /b 0

:decode
rem Arg: 8-digit code or "S-DD-RR-CCC"
set "CODE=%~1"
call :normalize_code "%CODE%" CODE || (>&2 echo [RECS] invalid code & exit /b 3)
set "S=%CODE:~0,1%"
set "DD=%CODE:~1,2%"
set "RR=%CODE:~3,2%"
set "CCC=%CODE:~5,3%"
echo S=%S% DD=%DD% RR=%RR% CCC=%CCC%
exit /b 0

:return
rem Args: S DD RR CCC [ctx...]
call :build %1 %2 %3 %4 >nul || exit /b 3
set "CODE=%S%%DD%%RR%%CCC%"
rem ここで必要なら :trace を噛ませてもよい
exit /b %CODE%

:throw
rem Args: S DD RR CCC [ctx...]
call :build %1 %2 %3 %4 >nul || exit /b 3
set "CODE=%S%%DD%%RR%%CCC%"
>&2 echo [RECS] THROW %CODE% %*
exit /b %CODE%

:pretty
rem Arg: 8-digit code or "S-DD-RR-CCC"
set "CODE=%~1"
call :normalize_code "%CODE%" CODE || (>&2 echo [RECS] invalid code & exit /b 3)
set "S=%CODE:~0,1%"&set "DD=%CODE:~1,2%"&set "RR=%CODE:~3,2%"&set "CCC=%CODE:~5,3%"
call :map_domain %DD% DOMAIN
call :map_reason %RR% REASON
for /f %%e in ('cmd /k prompt $e^<nul') do set "ESC=%%e"
set "STAT=STATUS%S%"&set "COLOR=36"
if "%S%"=="1" (set "STAT=OK"&set "COLOR=32")
if "%S%"=="8" (set "STAT=INTERRUPT"&set "COLOR=33")
if "%S%"=="9" (set "STAT=ERROR"&set "COLOR=31")
echo %ESC%[%COLOR%m%STAT%%ESC%[0m %CODE% [%DOMAIN% / %REASON%]
exit /b 0

:trace
rem Args: LEVEL TAG MSG...
set "LEVEL=%~1" & set "TAG=%~2"
shift /1 & shift /1
set "MSG=%*"
if not defined LOGFILE call :init_log
>>"%LOGFILE%" echo [%DATE% %TIME%] %LEVEL% %TAG% %MSG%
exit /b 0

:padnum
rem %1=value %2=width(1|2|3) %3=outvar
set "val=%~1" & set "w=%~2" & set "ov=%~3"
if "%val%"=="" exit /b 1
for /f "delims=0123456789" %%x in ("%val%") do exit /b 1
if "%w%"=="1" (set "tmp=0%val%"   & set "%ov%=%tmp:~-1%" & exit /b 0)
if "%w%"=="2" (set "tmp=00%val%"  & set "%ov%=%tmp:~-2%" & exit /b 0)
if "%w%"=="3" (set "tmp=000%val%" & set "%ov%=%tmp:~-3%" & exit /b 0)
exit /b 1

:normalize_code
rem 入力: %1(8桁 or S-DD-RR-CCC), 出力変数名: %2
set "nc=%~1"
set "nc=%nc:-=%"
for /f "delims=0123456789" %%x in ("%nc%") do exit /b 1
if "%nc:~7,1%"=="" exit /b 1
if not "%nc:~8%"=="" exit /b 1
set "%~2=%nc%"
exit /b 0

:map_domain
set "c=%~1" & set "ov=%~2"
setlocal
set "name="
if "%c%"=="01" set "name=MainMenu"
if "%c%"=="02" set "name=SaveData"
if "%c%"=="03" set "name=Display"
if "%c%"=="04" set "name=Environment"
if "%c%"=="05" set "name=Audio"
if "%c%"=="06" set "name=Systems"
if "%c%"=="07" set "name=Network"
if "%c%"=="08" set "name=Story"
if "%c%"=="09" set "name=Debug/Intercept"
endlocal & set "%ov%=%name%"
exit /b 0

:map_reason
set "c=%~1" & set "ov=%~2"
setlocal
set "name="
if "%c%"=="01" set "name=Selection"
if "%c%"=="10" set "name=I/O"
if "%c%"=="11" set "name=Parse"
if "%c%"=="12" set "name=Encode"
if "%c%"=="20" set "name=Network"
if "%c%"=="30" set "name=Validation"
if "%c%"=="50" set "name=Compat"
if "%c%"=="90" set "name=Other"
endlocal & set "%ov%=%name%"
exit /b 0

:init_log
set "LOGDIR=%~dp0..\..\..\Logs"
if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1
set "LOGFILE=%LOGDIR%\ad_%DATE:/=-%_%TIME::=-%.log"
exit /b 0

:usage
echo.
echo rcutil.bat  -  RECS v1 helper (hyphen CLI)
echo   -build  S DD RR CCC ^| "S-DD-RR-CCC"   ^> 8-digit code (stdout)
echo   -decode CODE                           ^> S= DD= RR= CCC=
echo   -return S DD RR CCC                    ^> exit /b CODE
echo   -throw  S DD RR CCC [ctx...]           ^> ^&2 log + exit /b CODE
echo   -pretty CODE                           ^> colorized summary
echo   -trace  LEVEL TAG MSG...               ^> append to Logs\*.log
echo.
exit /b 0
