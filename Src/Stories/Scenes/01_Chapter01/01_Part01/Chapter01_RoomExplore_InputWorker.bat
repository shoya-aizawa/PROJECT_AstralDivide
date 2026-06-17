@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "STATE_FILE=%~1"
set "STOP_FILE=%~2"
if "%STATE_FILE%"=="" exit /b 1
if "%STOP_FILE%"=="" exit /b 1

set /a seq=0

:WORKER_LOOP
if exist "%STOP_FILE%" exit /b 0
set "INPUT="
set /p "INPUT=" || exit /b 0
if not defined INPUT goto :WORKER_LOOP
set /a seq+=1
set "TMP_FILE=%STATE_FILE%.tmp"
(
    echo SEQ=!seq!
    echo EVENT=!INPUT!
) > "%TMP_FILE%"
move /y "%TMP_FILE%" "%STATE_FILE%" >nul 2>&1
goto :WORKER_LOOP
