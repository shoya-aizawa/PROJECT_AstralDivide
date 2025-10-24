@echo off
chcp 65001 >nul

setlocal

set URL=https://script.google.com/macros/s/AKfycbxdyqU2EGSjKzQUgcI5s17Fx5B7IS94xdystNTQ2phdOqASUiCQpEELiv9MhOXT_C2s/exec


echo 本来はルームIDが自動割り当てされてますが...
set /p ROOM=接続するルームIDを入力してください:

if "%ROOM%"=="" (
   echo [INFO] 空白だったため lobby に接続します...
   set ROOM=lobby
)

cls

powershell -Command "$enc=[System.Text.Encoding]::UTF8;$res=Invoke-WebRequest -Uri '%URL%?room=%ROOM%';$reader=New-Object System.IO.StreamReader($res.RawContentStream,$enc);[Console]::OutputEncoding=$enc;Write-Host $reader.ReadToEnd()"

endlocal

pause
