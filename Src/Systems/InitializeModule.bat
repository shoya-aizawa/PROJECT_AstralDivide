:: Initialize ANSI escape sequence
for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")



:: ______________ old code ______________

:: Set short paths relative to the root directory (%cd%)
set "cd_docs=%cd%\Docs"

set "cd_enemydata=%cd%\EnemyData"

set "cd_images=%cd%\Images"

set "cd_itemdata=%cd%\ItemData"

set "cd_newgame=%cd%\NewGame"

set "cd_playerdata=%cd%\PlayerData"

set "cd_savedata=%cd%\SaveData"

set "cd_sounds=%cd%\Sounds"

set "cd_stories=%cd%\Stories"
set "cd_stories_maps=%cd%\Stories\Maps"
set "cd_stories_textassets=%cd%\Stories\TextAssets"
set "cd_stories_textassets_prologue=%cd%\Stories\TextAssets\##Prologue"
set "cd_stories_textassets_episode1=%cd%\Stories\TextAssets\#Episode1"
set "cd_stories_textassets_episode2=%cd%\Stories\TextAssets\#Episode2"
set "cd_stories_textassets_episode3=%cd%\Stories\TextAssets\#Episode3"
:: ...
set "cd_stories_textassets_common=%cd%\Stories\TextAssets\$Common"

set "cd_stories_textassets_enemy=%cd%\Stories\TextAssets\@Enemy"
set "cd_stories_textassets_heroine=%cd%\Stories\TextAssets\@Heroine"
set "cd_stories_textassets_player=%cd%\Stories\TextAssets\@Player"


set "cd_systems=%cd%\Systems"
set "cd_systems_debug=%cd%\Systems\Debug"
set "cd_systems_display=%cd%\Systems\Display"
set "cd_systems_display_Animation=%cd%\Systems\Display\Animation"
set "cd_systems_input=%cd%\Systems\Input"
set "cd_systems_savesys=%cd%\Systems\SaveSys"

::__________________________________________________________________________

:: Initialize save execution source variables
set autosave=false
set manualsave=false
set newgame=false
set continue=false

rem Mayby old code
:: Initialize GUI space variables
:: call "%cd_systems%\WhileSpaceVariable_Initialize.bat"

:: Initialize the game text data
:: ============================
::       Will be updated
:: ============================
:: call "%cd_newgame%\TextFile.bat"


