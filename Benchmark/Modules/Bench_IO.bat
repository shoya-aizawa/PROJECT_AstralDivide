@echo off
setlocal
:: ==============================================================================
:: Bench_IO.bat
:: Tests the file append I/O performance which is critical for IPC/logging.
:: ==============================================================================
set "ITERATIONS=1000"
:: Use an absolute path based on the module directory to be safe regardless of cwd
set "TEMP_DIR=%~dp0..\Runtime\temp"
set "TEMP_FILE=%TEMP_DIR%\bench_io.tmp"

:: Ensure clean state
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

for /l %%i in (1,1,%ITERATIONS%) do (
    echo test>>"%TEMP_FILE%"
)

:: Clean up after benchmark
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

exit /b 0
