@echo off
setlocal EnableExtensions
cls

%tools_dir%\cmdbkg.exe "%assets_images_dir%\AD_StarrySky.png" /b
call "%src_audio_dir%\Play_BGM.bat" "%assets_sounds_dir%\静かな夜に.mp3" repeat %BGM_VOLUME%

call "%~dp0EnterYourName.bat"
set "scene_rc=%errorlevel%"

call "%src_audio_dir%\Play_BGM.bat" "" stop

endlocal & (
    if defined player_name set "player_name=%player_name%"
    exit /b %scene_rc%
)
