@echo off
setlocal
rem 引数: %1=ファイル名, %2=play/repeat/stop, %3=音量
powershell -ExecutionPolicy Bypass -NoLogo -NoProfile ^
   -Command "Import-Module '%~dp0BGMPlayer.psm1'; Invoke-BGM -Path '%~1' -Mode '%~2' -Volume %~3"
endlocal
