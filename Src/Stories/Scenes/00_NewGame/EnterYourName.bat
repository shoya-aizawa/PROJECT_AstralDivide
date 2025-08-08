@echo off
:: EnterYourName.bat
:: This script prompts the user to enter their name and displays it with some styling.
echo ここまでこれた？
pause

:loop


call :display

call :scene Scene01



set "player_name="

:: Prompt for player name
%tools_dir%\cmdwiz.exe setcursorpos 100 30
echo 名前を入力:
%tools_dir%\cmdwiz.exe setcursorpos 95 32
set /p player_name="> "


:: Input check (detect if player_name is empty)
setlocal EnableDelayedExpansion
if "%player_name%"=="" (
   %tools_dir%\cmdwiz.exe setcursorpos 90 30
   echo %ESC%[90m※defaultのままでよろしいですか？%ESC%[0m
   %tools_dir%\cmdwiz.exe delay 800
   %tools_dir%\cmdwiz.exe setcursorpos 101 32
   echo %ESC%[90m"シオン"%ESC%[0m
   %tools_dir%\cmdwiz.exe setcursorpos 91 36
   echo %ESC%[90m「はい」^(Y^) / 「いいえ」^(N^)%ESC%[0m
   choice /c yn >nul
   if !errorlevel!==1 (
      endlocal
      set "player_name=シオン"
   ) else (
      endlocal
      goto :loop
   )
)

:: Display the entered name
call :display

call :scene Scene02

:: 終了処理
set "player_name=!player_name!"
endlocal
exit /b 0







:display
cls
for /f "usebackq delims= eol=#" %%a in ("%src_display_tpl_dir%\EYNDisplay.txt") do (echo %%a)
exit /b 0


:scene
rem setlocal enabledelayedexpansion
for /f "eol=# usebackq delims=" %%L in ("%src_text_newgame_dir%\%1_EnterYourName.txt") do (
   set "line=%%L"
   call :ProcessLine "%line%"
)

:ProcessLine
call "%src_display_mod_dir%\RenderControl_v2.3.bat" "%line%"
exit /b














:: Typewriter Effect for Prologue Text
setlocal enabledelayedexpansion
set /a line=0
for /f "usebackq delims=" %%L in ("%src_text_newgame_dir%\%3_EnterYourName.txt") do (
   set /a line+=1
   call set "line_!line!=%%L"
)
set "line_total=!line!"

set /a y_base=%1

:: Output all lines using TypeWriter.bat
for /l %%i in (1,1,!line_total!) do (
   set /a y=%%i + y_base - 1
   call "%src_display_mod_dir%/TypeWriter_v2.3.bat" "!line_%%i!" !y! %2
   timeout /t 1 >nul
)
endlocal
exit /b 0