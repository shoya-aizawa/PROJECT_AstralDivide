:: Initialize ANSI escape sequence
for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")

::____________________________________________
::_____get root_______________________________
set "ROOT=%~dp0"

::_____other tools(.exe etc.)_________________
set "TOOLS=%ROOT%\tools"

::_____sorce code_____________________________
set "SRC=%ROOT%\src"
   set "SRC_MAIN=%SRC%\main"
   set "SRC_SYSTEMS=%SRC%\systems"
      set "SRC_SYSTEMS_DEBUG=%SRC_SYSTEMS%\debug"
      set "SRC_SYSTEMS_SAVESYS=%SRC_SYSTEMS%\SaveSys"
      set "SRC_SYSTEMS_DISPLAY=%SRC_SYSTEMS%\Display"
   set "SRC_STORIES=%SRC%\stories"
      set "SRC_STORIES_TEXTASSETS=%SRC_STORIES%\TextAssets"
      set "SRC_STORIES_MAPS=%SRC_STORIES%\Maps"
   set "SRC_DATA=%SRC%\data"
      set "SRC_DATA_ENEMY=%SRC_DATA%\EnemyData"
      set "SRC_DATA_ITEM=%SRC_DATA%\ItemData"
      set "SRC_DATA_PLAYER=%SRC_DATA%\PlayerData"
   set "SRC_INTERNET=%SRC%\internet"

set "src=%root%\src"
  set "src_main=%src%\main"
  set "src_systems=%src%\systems"
    set "src_systems_debug=%src_systems%\Debug"
    set "src_systems_savesys=%src_systems%\SaveSys"
    set "src_systems_display=%src_systems%\Display"
    set "src_systems_input=%src_systems%\Input"
  set "src_stories=%src%\stories"
    set "src_stories_textassets=%src_stories%\TextAssets"
    set "src_stories_maps=%src_stories%\Maps"
  set "src_data=%src%\data"
    set "src_data_enemy=%src_data%\EnemyData"
    set "src_data_item=%src_data%\ItemData"
    set "src_data_player=%src_data%\PlayerData"
  set "src_internet=%src%\internet"







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

:: Initialize save execution source variables
set autosave=false
set manualsave=false
set newgame=false
set continue=false

:: Initialize GUI space variables
call "%cd_systems%\WhileSpaceVariable_Initialize.bat"

:: Initialize the game text data
:: ============================
::       Will be updated
:: ============================
call "%cd_newgame%\TextFile.bat"


