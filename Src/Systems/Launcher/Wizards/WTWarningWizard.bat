@echo off
::------------------------------------------------------------------------------
:: WTWarningWizard.bat
::------------------------------------------------------------------------------
:: Clear screen and redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Render Windows Terminal warning text
echo !esc![4;18H!esc![91m[WARNING] Windows Terminal {wt.exe} Detected!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 5

echo !esc![8;10H!C_TEXT!This game is designed and optimized for standard console (conhost.exe).!C_RESET!
echo !esc![10;10H!C_TEXT!Running under Windows Terminal may cause:!C_RESET!
echo !esc![12;12H!C_TEXT!1. Window size adjustments being ignored.!C_RESET!
echo !esc![13;12H!C_TEXT!2. Text UI and layout rendering misalignments.!C_RESET!
echo !esc![14;12H!C_TEXT!3. Misbehavior in external console utility tools.!C_RESET!

call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 17

echo !esc![19;12H!esc![92m[Recommendation] Close this window and relaunch via conhost.exe.!C_RESET!
echo !esc![20;12H!C_TEXT!To force launch anyway, press any key to continue...!C_RESET!

echo !esc![21;38H!C_RESET!
pause >nul
if defined RCSU call "%RCSU%" -trace WARN Splash "Windows Terminal warning acknowledged by user. Forcing boot."

:: Clean up screen and redraw final frame border to return to main sequence
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
exit /b
