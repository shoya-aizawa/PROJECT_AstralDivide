@echo off
setlocal
:: ==============================================================================
:: Bench_Arithmetic.bat
:: Tests the basic arithmetic execution speed of cmd.exe.
:: ==============================================================================
set "ITERATIONS=50000"

set /a "value=0"

for /l %%i in (1,1,%ITERATIONS%) do (
    set /a "value+=1"
)

exit /b 0
