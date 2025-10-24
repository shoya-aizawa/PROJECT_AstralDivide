rem ==============================================================
rem  RCS_Util.bat v0.4  -  Return Code System Utility (Integrated)
rem --------------------------------------------------------------
rem  by HedgeHogSoft / PROJECT_AstralDivide
rem --------------------------------------------------------------
rem  Usage:
rem    call RCS_Util.bat -build  S DD RR CCC
rem    call RCS_Util.bat -decode CODE
rem    call RCS_Util.bat -return S DD RR CCC "Message"
rem    call RCS_Util.bat -throw  S DD RR CCC "Message"
rem    call RCS_Util.bat -pretty CODE
rem    call RCS_Util.bat -trace  LEVEL "MODULE" "Message"
rem --------------------------------------------------------------
rem  Structure: SDDRRCCC
rem  S = State (1=FLOW / 8=CANCEL / 9=ERROR)
rem  DD = Domain
rem  RR = Reason
rem  CCC = Case
rem --------------------------------------------------------------
rem  [v0.4 New Feature]
rem   - Introduced global variable `rcs_code`
rem     → Automatically updated before exit, allowing access from caller scope.
rem   - Enhanced Help section:
rem       [External Commands]  -trace, -throw, -return
rem       [Internal Mechanics] -build, -decode
rem       [Debug/Confirm]      -pretty
rem ==============================================================
@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
set "SELF=%~f0"

if "%~1"=="" goto :help
set "cmd=%~1"
shift

if /i "%cmd%"=="-build"  goto :build
if /i "%cmd%"=="-decode" goto :decode
if /i "%cmd%"=="-return" goto :return
if /i "%cmd%"=="-throw"  goto :throw
if /i "%cmd%"=="-pretty" goto :pretty
if /i "%cmd%"=="-trace"  goto :trace
goto :help

rem ==============================================================
:build
rem Args: S DD RR CCC
set "s=%~1" & set "dd=%~2" & set "rr=%~3" & set "ccc=%~4"
for %%x in (%s% %dd% %rr% %ccc%) do (
	for /f "delims=0123456789" %%z in ("%%x") do exit /b 900001
)
set /a code=s*10000000 + dd*100000 + rr*1000 + ccc
endlocal & (
    set "rcs_code=%code%"
    exit /b %code%
)

rem ==============================================================
:decode
set "c=%~1"
set /a rcs_s=c/10000000
set /a rcs_dd=(c/100000) %% 100
set /a rcs_rr=(c/1000) %% 100
set /a rcs_ccc=c %% 1000
endlocal & (
	set "rcs_s=%rcs_s%"
	set "rcs_dd=%rcs_dd%"
	set "rcs_rr=%rcs_rr%"
	set "rcs_ccc=%rcs_ccc%"
)
exit /b 0

rem ==============================================================
:pretty
set "code=%~1"
call "%SELF%" -decode %code%

set "stype=FLOW"
if "%rcs_s%"=="8" set "stype=CANCEL"
if "%rcs_s%"=="9" set "stype=ERROR"

call :map_domain %rcs_dd% domain
call :map_reason %rcs_rr% reason

echo [%stype%] %domain% / %reason% / case=%rcs_ccc% (code=%code%)
exit /b 0

rem ==============================================================
:return
set "s=%~1" & set "dd=%~2" & set "rr=%~3" & set "ccc=%~4" & set "msg=%~5"
call "%SELF%" -build %s% %dd% %rr% %ccc%
set "code=%errorlevel%"
set "rcs_code=%code%"
call "%SELF%" -trace OK "Return" "rc=%code% %msg%"
endlocal & (
    set "rcs_code=%code%"
    exit /b %code%
)

rem ==============================================================
:throw
set "s=%~1" & set "dd=%~2" & set "rr=%~3" & set "ccc=%~4" & set "msg=%~5"
call "%SELF%" -build %s% %dd% %rr% %ccc%
set "code=%errorlevel%"
set "rcs_code=%code%"
call "%SELF%" -trace ERR "Throw" "rc=%code% %msg%"
endlocal & (
    set "rcs_code=%code%"
    exit /b %code%
)

rem ==============================================================
:trace
set "lvl=%~1"
set "mod=%~2"
set "msg=%~3"
if not defined RCS_LOG_FILE call :log_init

for /f %%t in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set "ts=%%t"
set "line=[%ts%] [%lvl%] [%mod%] %msg%"
>>"%RCS_LOG_FILE%" echo %line%
if /i "%lvl%"=="ERR" (
  >>"%RCS_LOG_DIR%\AstralDivide_Error_%date_tag%.log" echo %line%
)
exit /b 0

rem ==============================================================
:log_init
if not defined RCS_LOG_DIR set "RCS_LOG_DIR=%PROJECT_ROOT%\Config\Logs"
if not exist "%RCS_LOG_DIR%" md "%RCS_LOG_DIR%" >nul 2>&1

for /f %%d in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd')"') do set "date_tag=%%d"
set "RCS_LOG_FILE=%RCS_LOG_DIR%\AstralDivide_Session_%date_tag%.log"
exit /b 0

rem ==============================================================
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
if "%c%"=="09" set "name=Debug"
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

rem ==============================================================
:help
echo.
echo  RCS_Util.bat v0.4 - Integrated Logging Edition
echo --------------------------------------------------------------
echo  USAGE:
echo    call RCS_Util.bat -return S DD RR CCC "Message"
echo    call RCS_Util.bat -throw  S DD RR CCC "Message"
echo    call RCS_Util.bat -trace  LEVEL "MODULE" "Message"
echo    call RCS_Util.bat -pretty CODE
echo --------------------------------------------------------------
echo  [External Commands]
echo    -return : Normal return (writes log, exit /b)
echo    -throw  : Exception throw (writes log, no stderr)
echo    -trace  : Log any event with timestamp
echo --------------------------------------------------------------
echo  [Internal Mechanics]
echo    -build  : Construct numeric code from S/DD/RR/CCC
echo    -decode : Split code to parts (rcs_s, rcs_dd, etc.)
echo --------------------------------------------------------------
echo  [Debug/Confirmation]
echo    -pretty : Human-readable format output
echo --------------------------------------------------------------
echo  New in v0.4:
echo    Global var [rcs_code] now holds the last built/returned code.
echo --------------------------------------------------------------
exit /b 0
