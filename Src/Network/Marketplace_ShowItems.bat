@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set URL=https://script.google.com/macros/s/AKfycbyD2B1fK7ly8YbRySmvUOTpNb9k0OuFwB-UmhhBezRulmiAtlVvgn4tjTOnXBjVmTHp/exec

powershell -Command "(Invoke-WebRequest -Uri '%URL%' -UseBasicParsing).Content | ConvertFrom-Json | ConvertTo-Json -Depth 3"

endlocal
pause