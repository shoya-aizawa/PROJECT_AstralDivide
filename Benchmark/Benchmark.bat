@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
:: ==============================================================================
:: Benchmark.bat
:: Main entry point for the AstralDivide standalone benchmark module.
:: ==============================================================================

:: Setup paths
set "BASE_DIR=%~dp0"
set "LOG_DIR=%BASE_DIR%Runtime\logs"
set "MODULES_DIR=%BASE_DIR%Modules"
set "LIB_DIR=%BASE_DIR%Lib"

:: Generate log file name based on current date and time
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "DT=%%I"
set "TIMESTAMP=%DT:~0,4%%DT:~4,2%%DT:~6,2%_%DT:~8,2%%DT:~10,2%%DT:~12,2%"
set "LOG_FILE=%LOG_DIR%\benchmark_result_%TIMESTAMP%.csv"

:: Initialize log file
echo test_name,time_ms>"%LOG_FILE%"

echo ==================================================
echo AstralDivide Benchmark Suite
echo ==================================================
echo Logging to: %LOG_FILE%
echo.

call :RunBenchmark "Arithmetic" "%MODULES_DIR%\Bench_Arithmetic.bat"
call :RunBenchmark "CALL" "%MODULES_DIR%\Bench_Call.bat"
call :RunBenchmark "IO" "%MODULES_DIR%\Bench_IO.bat"
call :RunBenchmark "PowerShell" "%MODULES_DIR%\Bench_PS.bat"

echo.
echo ==================================================
echo Benchmark Complete.
echo ==================================================
echo Results:
type "%LOG_FILE%"
echo ==================================================

pause
exit /b 0

:: ------------------------------------------------------------------------------
:: Subroutine: RunBenchmark
:: Args:
::   %1 - Test Name
::   %2 - Batch File Path
:: ------------------------------------------------------------------------------
:RunBenchmark
set "TEST_NAME=%~1"
set "TEST_FILE=%~2"

echo [Running] %TEST_NAME% benchmark...

:: Get start time
call "%LIB_DIR%\Time.bat" TIME_START

:: Execute benchmark
call "%TEST_FILE%"

:: Get end time
call "%LIB_DIR%\Time.bat" TIME_END

:: Calculate difference using PowerShell to avoid 32-bit integer overflow in batch
for /f "usebackq tokens=*" %%A in (`powershell -NoLogo -NoProfile -Command "[long]!TIME_END! - [long]!TIME_START!"`) do set "TIME_DIFF=%%A"

:: Log to CSV
echo %TEST_NAME%,%TIME_DIFF%>>"%LOG_FILE%"

echo   -^> Completed in %TIME_DIFF% ms
exit /b 0
