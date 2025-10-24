@echo off
:: EnterYourName.bat
:: This script prompts the user to enter their name and displays it with some styling.
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
   start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Move.wav"
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
      start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Cancel.wav"
      endlocal
      goto :loop
   )
)

:: Display the entered name
start "" /b %tools_dir%\cmdwiz.exe playsound "%assets_sounds_fx_dir%\Enter4.wav"
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