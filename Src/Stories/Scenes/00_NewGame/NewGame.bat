@echo off
cls

%tools_dir%\cmdbkg.exe "%assets_images_dir%\AD_StarrySky.png" /b

call "%src_audio_dir%\Play_BGM.bat" "%assets_sounds_revelation_dir%\RevelationOfGod.wav" repeat 15

call "%~dp0EnterYourName.bat"




timeout /t 1 >nul
pause

set retcode=55
call "%src_audio_dir%\Play_BGM.bat" "" stop
exit /b 55
