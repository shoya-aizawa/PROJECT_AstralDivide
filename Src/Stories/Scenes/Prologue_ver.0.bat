@echo off
cls

cmdbkg "%cd_images%\0.png" /b

call "%cd_systems_input%\EnterYourName.bat"




timeout /t 1 >nul
pause

set retcode=55
exit /b 55
