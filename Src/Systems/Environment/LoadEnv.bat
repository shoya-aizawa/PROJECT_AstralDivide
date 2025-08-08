@echo off
rem LoadEnv.bat
rem Usage : call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "C:\path\to\profile.env"
rem Format: lines like - set "KEY=VALUE"
rem Comment lines must start with '#'

set "ENV_FILE=%~1"
if not defined ENV_FILE exit /b 2
if not exist "%ENV_FILE%" exit /b 2

for /f "usebackq eol=# tokens=* delims=" %%L in ("%ENV_FILE%") do (
   %%L
)
echo %esc%[92m[OK]%esc%[0m profile.env file has been loaded
exit /b
