@echo off
chcp 65001 >nul

setlocal
set SCENE=001
set CHOICE=HELP

powershell -Command "Invoke-WebRequest -Uri 'https://script.google.com/macros/s/AKfycbxxGXTVDi1Z92L63LHkSCHEujS_04lezetng5PKF_TUOWRa6ylvaKA658iAKOSeSeybgg/exec' -Method POST -Body 'scene=%SCENE%&choice=%CHOICE%' -ContentType 'application/x-www-form-urlencoded'"

endlocal

pause



:: https://script.google.com/macros/s/AKfycbxxGXTVDi1Z92L63LHkSCHEujS_04lezetng5PKF_TUOWRa6ylvaKA658iAKOSeSeybgg/exec
