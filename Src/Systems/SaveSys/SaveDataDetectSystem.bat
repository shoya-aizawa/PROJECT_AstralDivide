chcp 65001 >nul

rem Save data detection system
rem Read filename from File_SaveDataConfig.txt

set save_exist_count=0
for /f "delims=" %%b in (%saves_active_dir%\SaveDataConfig.txt) do (
    call :Label_SaveDataBooleanValue %%b
)
rem Initialize variables related to save data selection UI
call "%src_savesys_dir%\SelectSaveData_Initialize.bat"


:: Back to Main.bat
:: ==========
exit /b %RC_OK%
:: ==========


:Label_SaveDataBooleanValue
if exist "%saves_active_dir%\%1.txt" (
    set saveexists_%1=true
    set save_exist_count+=1
) else (
    set saveexists_%1=false
)
exit /b 0