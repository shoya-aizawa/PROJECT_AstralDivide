@echo off
::------------------------------------------------------------------------------
:: Play_SE.bat
:: Plays a WAV sound effect in the background asynchronously using cmdwiz.exe.
::
:: Arguments:
::   %1 - Path to the WAV sound effect file.
::------------------------------------------------------------------------------
setlocal
set "SE_FILE=%~1"

if "%SE_FILE%"=="" exit /b 1
if not exist "%SE_FILE%" exit /b 2

:: Detect cmdwiz path
if defined PROJECT_ROOT (
    set "CMDWIZ_PATH=%PROJECT_ROOT%\Tools\cmdwiz.exe"
) else (
    set "CMDWIZ_PATH=%~dp0..\..\..\Tools\cmdwiz.exe"
)

:: Ensure absolute path or resolve relative path
if not exist "%CMDWIZ_PATH%" (
    :: Fallback search
    if exist "%~dp0cmdwiz.exe" (
        set "CMDWIZ_PATH=%~dp0cmdwiz.exe"
    )
)

:: Launch cmdwiz playsound in the background asynchronously
if exist "%CMDWIZ_PATH%" (
    start "" /b "%CMDWIZ_PATH%" playsound "%SE_FILE%"
)

endlocal
exit /b 0
