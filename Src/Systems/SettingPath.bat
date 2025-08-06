:: ─── If PROJECT_ROOT exists, use it. If not, complete it yourself. ──
if defined PROJECT_ROOT (
   set "root_dir=%PROJECT_ROOT%"
) else (
   rem %~dp0 = location of this script (…\Src\Main\)
   rem Expand two levels up to get the "Project Root"
   for %%I in ("%~dp0\..\..") do set "root_dir=%%~fI\"
)

::_____Under Assets___________________________
set "assets_dir=%root_dir%Assets"
set "assets_docs_dir=%assets_dir%\Docs"
set "assets_images_dir=%assets_dir%\Images"
set "assets_sounds_dir=%assets_dir%\Sounds"
   set "assets_sounds_revelation_dir=%assets_sounds_dir%\RevelationOfGod"
   set "assets_sounds_starfall_dir=%assets_sounds_dir%\StarFallHill"
   set "assets_sounds_fx_dir=%assets_sounds_dir%\_SoundEffect"

::_____Under Src______________________________
set "src_dir=%root_dir%Src"
set "src_data_dir=%src_dir%\Data"
set "src_internet_dir=%src_dir%\Internet"
set "src_main_dir=%src_dir%\Main"
set "src_stories_dir=%src_dir%\Stories"
   set "src_scenes_dir=%src_stories_dir%\Scenes"
      set "src_scene_newgame_dir=%src_scenes_dir%\00_NewGame"
      set "src_scene_prologue_dir=%src_scenes_dir%\01_Prologue"
      rem (Other scenes are dynamically referenced by %src_scenes_dir%\{ID_Name})
   set "src_textassets_dir=%src_stories_dir%\TextAssets"
      set "src_text_newgame_dir=%src_textassets_dir%\00_NewGame"
      set "src_text_prologue_dir=%src_textassets_dir%\01_Prologue"
      rem (Also dynamically accessible)

set "src_systems_dir=%src_dir%\Systems"
   set "src_audio_dir=%src_systems_dir%\Audio"
   set "src_debug_dir=%src_systems_dir%\Debug"
   set "src_display_dir=%src_systems_dir%\Display"
      set "src_display_mod_dir=%src_display_dir%\Modules"
      set "src_display_tpl_dir=%src_display_dir%\Templates"
   set "src_savesys_dir=%src_systems_dir%\SaveSys"

::_____Test/Tools/[DEV]_______________________
set "test_dir=%root_dir%Test"
set "tools_dir=%root_dir%Tools"
set "dev_dir=%root_dir%[DEV]"

rem //::_____Verification output (for debug)________
rem //echo root_dir               = %root_dir%
rem //echo assets_images_dir      = %assets_images_dir%
rem //echo assets_sounds_starfall_dir = %assets_sounds_starfall_dir%
rem //echo src_main_dir           = %src_main_dir%
rem //echo src_scene_prologue_dir = %src_scene_prologue_dir%
rem //echo src_display_tpl_dir    = %src_display_tpl_dir%
rem //echo tools_dir              = %tools_dir%
rem //timeout /t 1

::_____Notice_________________________________
:: This configuration is resilient to structural changes:
::  if the "Assets" folder is renamed to "Resource", updating only the assets_dir assignment will automatically update all related paths.


for /f "usebackq delims=" %%L in (`tree /f /a`) do (
   echo %%L
   %root_dir%Tools\cmdwiz.exe delay 1
)
echo [OK] Path variable setting completed successfully.
timeout /t 1