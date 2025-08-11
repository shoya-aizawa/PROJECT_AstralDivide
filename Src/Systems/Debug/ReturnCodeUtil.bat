@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: ReturnCodeUtil.bat(RCU)  -  RECS v1 helper
:: Hyphen flags: -build / -decode / -return / -throw / -pretty / -trace

if "%~1"=="" (call :usage & exit /b 1)

set "cmd=%~1"
set "cmd=!cmd:/=-!" & rem /build も -build として扱う
if /i "!cmd!"=="-help"  (call :usage & exit /b 0)
if /i "!cmd!"=="/help"  (call :usage & exit /b 0)

:: 提案: （dispatcherでは shift しない）
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
rem Args: [-build] S DD RR CCC  または  "S-DD-RR-CCC"
if /i "%~1"=="-build" shift
setlocal
if "%~2"=="" (
  set "spec=%~1"
  set "spec=%spec:"=%"
  for /f "tokens=1-4 delims=-" %%a in ("%spec%") do (
    set "RC_S=%%a" & set "RC_DD=%%b" & set "RC_RR=%%c" & set "RC_CCC=%%d"
  )
) else (
  set "RC_S=%~1" & set "RC_DD=%~2" & set "RC_RR=%~3" & set "RC_CCC=%~4"
)
call :padnum %RC_S%  1 RC_S  || (endlocal & exit /b 3)
call :padnum %RC_DD% 2 RC_DD || (endlocal & exit /b 3)
call :padnum %RC_RR% 2 RC_RR || (endlocal & exit /b 3)
call :padnum %RC_CCC% 3 RC_CCC || (endlocal & exit /b 3)
set "CODE=%RC_S%%RC_DD%%RC_RR%%RC_CCC%"
echo %CODE%
endlocal & set "CODE=%CODE%"
echo %CODE%
exit /b 0

:decode
rem Arg: [-decode] 8-digit code or "S-DD-RR-CCC"
if /i "%~1"=="-decode" shift
set "CODE=%~1"
call :normalize_code "%CODE%" CODE || (>&2 echo [RECS] invalid code & exit /b 3)
set "S=%CODE:~0,1%"
set "DD=%CODE:~1,2%"
set "RR=%CODE:~3,2%"
set "CCC=%CODE:~5,3%"
echo S=%S% DD=%DD% RR=%RR% CCC=%CCC%
exit /b 0

:return
rem Args: [-return] S DD RR CCC [ctx...]
if /i "%~1"=="-return" shift
setlocal
call :build %1 %2 %3 %4 >nul || (endlocal & exit /b 3)
set "RC_CODE=%CODE%"
endlocal & exit /b %RC_CODE%

:throw
rem Args: [-throw] S DD RR CCC [ctx...]
if /i "%~1"=="-throw" shift
setlocal
call :build %1 %2 %3 %4 >nul || (endlocal & exit /b 3)
set "RC_CODE=%CODE%"
>&2 echo [RECS] THROW %RC_CODE% %*
endlocal & exit /b %RC_CODE%

:pretty
rem Arg: [-pretty] 8-digit code or "S-DD-RR-CCC"
if /i "%~1"=="-pretty" shift
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
rem Args: [-trace] LEVEL TAG MSG...
if /i "%~1"=="-trace" shift

rem 1) LEVEL / TAG を確定
set "LEVEL=%~1"
set "TAG=%~2"

rem 2) 残りを安全に収集（%*は使わない）
set "MSG="
:__trace_collect
shift /1
if "%~1"=="" goto :__trace_emit
if defined MSG (set "MSG=%MSG% %~1") else set "MSG=%~1"
goto :__trace_collect

:__trace_emit
if not defined LOGFILE call :init_log
>>"%LOGFILE%" echo [%DATE% %TIME%] %LEVEL% %TAG% %MSG%
exit /b 0



:padnum
rem %1=value %2=width(1|2|3) %3=outvar
set "val=%~1" & set "w=%~2" & set "ov=%~3"
if "%val%"=="" exit /b 1
for /f "delims=0123456789" %%x in ("%val%") do exit /b 1

if "%w%"=="1" goto :pad1
if "%w%"=="2" goto :pad2
if "%w%"=="3" goto :pad3
exit /b 1

:pad1
set "_pad=0%val%"
set "%ov%=%_pad:~-1%"
exit /b 0

:pad2
set "_pad=00%val%"
set "%ov%=%_pad:~-2%"
exit /b 0

:pad3
set "_pad=000%val%"
set "%ov%=%_pad:~-3%"
exit /b 0


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
md "%LOGDIR%" >nul 2>&1

rem --- mode: daily | session | single (default: daily)
if not defined LOG_MODE set "LOG_MODE=daily"

rem --- tags (ロケール依存の記号を安全化)
set "DATE_TAG=%DATE:/=-%"
set "TIME_TAG=%TIME::=-%"
set "TIME_TAG=%TIME_TAG:.=-%"
set "TIME_TAG=%TIME_TAG: =0%"

rem --- prefix も任意で変えられるように（未指定なら ad）
if not defined LOG_PREFIX set "LOG_PREFIX=ad"

if /i "%LOG_MODE%"=="session" (
  set "LOGFILE=%LOGDIR%\%LOG_PREFIX%_%DATE_TAG%_%TIME_TAG%.log"
) else if /i "%LOG_MODE%"=="single" (
  set "LOGFILE=%LOGDIR%\%LOG_PREFIX%.log"
) else (
  rem daily
  set "LOGFILE=%LOGDIR%\%LOG_PREFIX%_%DATE_TAG%.log"
)

rem --- 単一ファイルモードの簡易ローテーション（5MB超えたら退避）
if /i "%LOG_MODE%"=="single" if exist "%LOGFILE%" (
  for %%A in ("%LOGFILE%") do set "SZ=%%~zA"
  if defined SZ if %SZ% GEQ 5242880 (
     move /y "%LOGFILE%" "%LOGDIR%\%LOG_PREFIX%_%DATE_TAG%_%TIME_TAG%.log" >nul
  )
)
exit /b 0


:usage
echo.
echo ReturnCodeUtil.bat(RCU)  -  RECS v1 helper (hyphen CLI)
echo   -build  S DD RR CCC ^| "S-DD-RR-CCC"    ^> 8-digit code (stdout)
echo   -decode CODE                           ^> S= DD= RR= CCC=
echo   -return S DD RR CCC                    ^> exit /b CODE
echo   -throw  S DD RR CCC [ctx...]           ^> ^&2 log + exit /b CODE
echo   -pretty CODE                           ^> colorized summary
echo   -trace  LEVEL TAG MSG...               ^> append to Logs\*.log
echo.
exit /b 0
