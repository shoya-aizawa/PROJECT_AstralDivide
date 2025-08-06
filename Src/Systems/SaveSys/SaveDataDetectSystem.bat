rem セーブデータ検出システム
rem File_SaveDataConfig.txtからファイル名を読み込む

set save_exist_count=0
for /f "delims=" %%b in (%cd_savedata%\SaveDataConfig.txt) do (
    call :Label_SaveDataBooleanValue %%b
)
rem セーブデータ選択画面のUIにかかわる変数の初期化
call "%cd_systems_savesys%\SelectSaveData_Initialize.bat"


:: Back to Main.bat
:: ==========
exit /b 0
:: ==========


:Label_SaveDataBooleanValue
if exist "%cd_savedata%\%1.txt" (
    set saveexists_%1=true
    set save_exist_count+=1
) else (
    set saveexists_%1=false
)
exit /b 0