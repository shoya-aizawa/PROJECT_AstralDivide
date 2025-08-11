@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 日本語入力対応で出品アイテム情報を取得

set /p "ITEM_NAME=出品するアイテム名（日本語可）: "
set /p "ITEM_PRICE=価格（数字）: "

:: GAS Web App URL

set URL=https://script.google.com/macros/s/AKfycbyD2B1fK7ly8YbRySmvUOTpNb9k0OuFwB-UmhhBezRulmiAtlVvgn4tjTOnXBjVmTHp/exec

:: PowerShell経由でPOST送信（UTF-8 + エンコード）

powershell -Command "$utf8=[System.Text.Encoding]::UTF8;$encoded=[uri]::EscapeDataString('%ITEM_NAME%');$body='name=' + $encoded + '&price=%ITEM_PRICE%';Invoke-WebRequest -Uri '%URL%' -Method POST -Body ($utf8.GetBytes($body)) -ContentType 'application/x-www-form-urlencoded; charset=utf-8';Write-Host '[OK]'"


echo.
echo 出品処理が完了しました！
pause
endlocal
