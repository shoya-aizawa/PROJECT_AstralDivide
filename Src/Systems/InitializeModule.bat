chcp 65001 >nul
:: Initialize ANSI escape sequence
for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")

:: Initialize save execution source variables
set autosave=false
set manualsave=false
set newgame=false
set continue=false

:: Load UI profile settings and coordinates
call "%src_display_tpl_dir%\StaticUIProfileSelector.bat"

exit /b %RC_OK%

rem Mayby old code
:: Initialize GUI space variables
:: call "%cd_systems%\WhileSpaceVariable_Initialize.bat"

:: Initialize the game text data
:: ============================
::       Will be updated
:: ============================
:: call "%cd_newgame%\TextFile.bat"


