@echo off
chcp 65001 >nul
setlocal

set URL=https://script.google.com/macros/s/AKfycbxdyqU2EGSjKzQUgcI5s17Fx5B7IS94xdystNTQ2phdOqASUiCQpEELiv9MhOXT_C2s/exec

echo 日本語対応済み


set /p ROOM=本来ここは現在居るルームIDが自動割り当て:
set /p NAME=Enter your name:
set /p MESSAGE=Enter your message:

set ROOM=%ROOM%
set NAME=%NAME%
set MESSAGE=%MESSAGE%


powershell -Command "$utf8=[System.Text.Encoding]::UTF8;$body='name=%NAME%&room=%ROOM%&message=' + [uri]::EscapeDataString('%MESSAGE%');Invoke-WebRequest -Uri '%URL%' -Method POST -Body ($utf8.GetBytes($body)) -ContentType 'application/x-www-form-urlencoded; charset=utf-8';Write-Host '[OK]'"

endlocal

pause




:: https://script.google.com/macros/s/AKfycbxdyqU2EGSjKzQUgcI5s17Fx5B7IS94xdystNTQ2phdOqASUiCQpEELiv9MhOXT_C2s/exec