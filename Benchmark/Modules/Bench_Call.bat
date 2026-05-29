@echo off
setlocal
:: ==============================================================================
:: Bench_Call.bat
:: Tests the overhead of calling a label within a batch file.
:: ==============================================================================
set "ITERATIONS=10000"

for /l %%i in (1,1,%ITERATIONS%) do (
    call :noop
)

exit /b 0

:noop
exit /b 0
