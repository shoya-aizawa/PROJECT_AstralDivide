@echo off
setlocal
powershell -ExecutionPolicy Bypass -NoLogo -NoProfile ^
   -Command "Import-Module '%~dp0BGMPlayer.psm1'; Invoke-BGM -Path '%~1' -Mode '%~2' -Volume %~3"
endlocal
