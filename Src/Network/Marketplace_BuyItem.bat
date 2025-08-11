@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

if "%~1"=="" (
   echo item_idを指定してください。
   exit /b 1
)

set "ITEM_ID=%~1"
set URL=https://script.google.com/macros/s/AKfycbyD2B1fK7ly8YbRySmvUOTpNb9k0OuFwB-UmhhBezRulmiAtlVvgn4tjTOnXBjVmTHp/exec


for /f "usebackq delims=" %%A in (`powershell -Command "(Invoke-WebRequest -Uri '%URL%' -Method POST -Body @{item_id='%ITEM_ID%'} -UseBasicParsing).Content"`) do (
   set "response=%%A"
)

echo 購入結果: !response!

endlocal
pause
