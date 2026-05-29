chcp 65001 >nul

rem セーブデータ検出システム
rem File_SaveDataConfig.txtからファイル名を読み込む

set save_exist_count=0
for /f "delims=" %%b in (%saves_active_dir%\SaveDataConfig.txt) do (
    call :Label_SaveDataBooleanValue %%b
)
rem セーブデータ選択画面のUIにかかわる変数の初期化
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