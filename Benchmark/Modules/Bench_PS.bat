@echo off
setlocal
:: ==============================================================================
:: Bench_PS.bat
:: Tests the spawn cost of the PowerShell runtime.
:: ==============================================================================
set "ITERATIONS=10"

for /l %%i in (1,1,%ITERATIONS%) do (
    powershell -NoLogo -NoProfile -Command "exit"
)

exit /b 0
