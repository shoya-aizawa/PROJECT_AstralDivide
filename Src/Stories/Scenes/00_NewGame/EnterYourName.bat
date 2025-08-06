@echo off
:: EnterYourName.bat
:: This script prompts the user to enter their name and displays it with some styling.

:loop


call :display

call :scene Scene00



set "player_name="

:: Prompt for player name
cmdwiz setcursorpos 100 30
echo 名前を入力:
cmdwiz setcursorpos 95 32
set /p player_name="> "


:: Input check (detect if player_name is empty)
setlocal EnableDelayedExpansion
if "%player_name%"=="" (
   cmdwiz setcursorpos 90 30
   echo %ESC%[90m※defaultのままでよろしいですか？%ESC%[0m
   cmdwiz delay 800
   cmdwiz setcursorpos 101 32
   echo %ESC%[90m"シオン"%ESC%[0m
   cmdwiz setcursorpos 91 36
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

call :scene Scene01

:: 終了処理
set "player_name=!player_name!"
endlocal
exit /b 0







:display
cls
for /f "usebackq delims= eol=#" %%a in ("%cd_systems_display%\EYNDisplay.txt") do (echo %%a)
exit /b 0


:scene
rem setlocal enabledelayedexpansion
for /f "eol=# usebackq delims=" %%L in ("%cd_stories_textassets_prologue%\%1_EnterYourName.txt") do (
    set "line=%%L"
    call :ProcessLine "%line%"
)

:ProcessLine
call "%cd_stories%\RenderControl_v2.3.bat" "%line%"
exit /b














:: Typewriter Effect for Prologue Text
setlocal enabledelayedexpansion
set /a line=0
for /f "usebackq delims=" %%L in ("%cd_stories_textassets_prologue%\%3_EnterYourName.txt") do (
   set /a line+=1
   call set "line_!line!=%%L"
)
set "line_total=!line!"

set /a y_base=%1

:: Output all lines using TypeWriter.bat
for /l %%i in (1,1,!line_total!) do (
   set /a y=%%i + y_base - 1
   call "%cd_stories%/TypeWriter.bat" "!line_%%i!" !y! %2
   timeout /t 1 >nul
)
endlocal
exit /b 0