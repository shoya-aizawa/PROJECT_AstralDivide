@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: -----------------------------------------------------------------------------
:: SettingsMenu.bat
:: Role: Options screen for Astral Divide.
::       Configures display, language, audio, and applies on return.
:: -----------------------------------------------------------------------------

if not defined PROJECT_ROOT (
    for %%A in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fA"
)
for %%A in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fA"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

if not defined RCSU if defined PROJECT_ROOT set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"

set "src_audio_dir=%PROJECT_ROOT%\Src\Systems\Audio"
set "src_display_tpl_dir=%PROJECT_ROOT%\Src\Systems\Display\Templates"
if not defined assets_sounds_fx_dir set "assets_sounds_fx_dir=%PROJECT_ROOT%\Assets\Sounds\FX"
set "cmdwiz_path=%PROJECT_ROOT%\Tools\cmdwiz.exe"
if not exist "%cmdwiz_path%" set "cmdwiz_path="

if exist "%src_display_tpl_dir%\StaticUIProfileSelector.bat" (
    set "SUPPRESS_STATIC_UI_TRACE=1"
    call "%src_display_tpl_dir%\StaticUIProfileSelector.bat"
    set "SUPPRESS_STATIC_UI_TRACE="
)

if exist "%RCSU%" call "%RCSU%" -trace INFO SettingsMenu "entered settings quality=%RENDER_QUALITY%"

set "UI_ACTION="
set "UI_PARAM="

if not defined LANGUAGE set "LANGUAGE=ja-JP"
if not defined SOUND_FX_ENABLED set "SOUND_FX_ENABLED=ON"
if not defined SE_VOLUME set "SE_VOLUME=80"
if not defined BGM_VOLUME set "BGM_VOLUME=30"
if not defined BGM_SOUNDTRACK set "BGM_SOUNDTRACK=STARFALL"
if not defined TUTORIAL set "TUTORIAL=ON"
if not defined AUTO_SAVE set "AUTO_SAVE=ON"
if not defined PREFERRED_RENDER_QUALITY set "PREFERRED_RENDER_QUALITY=auto"

set "SESSION_LANGUAGE=%LANGUAGE%"
set "SESSION_SOUND_FX_ENABLED=%SOUND_FX_ENABLED%"
set "SESSION_SE_VOLUME=%SE_VOLUME%"
set "SESSION_BGM_VOLUME=%BGM_VOLUME%"
set "SESSION_BGM_SOUNDTRACK=%BGM_SOUNDTRACK%"
set "SESSION_TUTORIAL=%TUTORIAL%"
set "SESSION_AUTO_SAVE=%AUTO_SAVE%"
set "SESSION_PREFERRED_RENDER_QUALITY=%PREFERRED_RENDER_QUALITY%"
set "ORIGINAL_BGM_VOLUME=%BGM_VOLUME%"
set "ORIGINAL_BGM_SOUNDTRACK=%BGM_SOUNDTRACK%"

for /f "delims=" %%a in ('echo prompt $E^| cmd /d') do set "esc=%%a"

set "OPT_COUNT=13"

set "OPT_KEY_1=LANGUAGE"
set "OPT_LABEL_1=Language"
set "OPT_VAL_1=%SESSION_LANGUAGE%"
set "OPT_ALLOWED_1=ja-JP en-US"
set "OPT_DESC_1=Switch standard game interface and narration text language."
set "OPT_TYPE_1=setting"
set "OPT_KIND_1=choice"
set "OPT_VISIBLE_1=1"

set "OPT_KEY_2=SOUND_FX_ENABLED"
set "OPT_LABEL_2=Sound Effects"
set "OPT_VAL_2=%SESSION_SOUND_FX_ENABLED%"
set "OPT_ALLOWED_2=ON OFF"
set "OPT_DESC_2=Toggle interface cursor navigation sound effects globally."
set "OPT_TYPE_2=setting"
set "OPT_KIND_2=toggle"
set "OPT_VISIBLE_2=1"

set "OPT_KEY_3=SE_VOLUME"
set "OPT_LABEL_3=SE Volume"
set "OPT_VAL_3=%SESSION_SE_VOLUME%"
set "OPT_DESC_3=Adjust interface and cursor sound effect intensity in 10%% steps."
set "OPT_TYPE_3=setting"
set "OPT_KIND_3=range"
set "OPT_MIN_3=0"
set "OPT_MAX_3=100"
set "OPT_STEP_3=10"
set "OPT_VISIBLE_3=1"

set "OPT_KEY_4=BGM_VOLUME"
set "OPT_LABEL_4=BGM Volume"
set "OPT_VAL_4=%SESSION_BGM_VOLUME%"
set "OPT_DESC_4=Adjust background music playback volume in 10%% steps."
set "OPT_TYPE_4=setting"
set "OPT_KIND_4=range"
set "OPT_MIN_4=0"
set "OPT_MAX_4=100"
set "OPT_STEP_4=10"
set "OPT_VISIBLE_4=1"

set "OPT_KEY_5=TUTORIAL"
set "OPT_LABEL_5=Tutorial"
set "OPT_VAL_5=%SESSION_TUTORIAL%"
set "OPT_ALLOWED_5=ON OFF"
set "OPT_DESC_5=Enable or disable tutorial prompts during guided play."
set "OPT_TYPE_5=setting"
set "OPT_KIND_5=toggle"
set "OPT_VISIBLE_5=1"

set "OPT_KEY_6=AUTO_SAVE"
set "OPT_LABEL_6=Auto Save"
set "OPT_VAL_6=%SESSION_AUTO_SAVE%"
set "OPT_ALLOWED_6=ON OFF"
set "OPT_DESC_6=Automatically preserve progress at supported checkpoints."
set "OPT_TYPE_6=setting"
set "OPT_KIND_6=toggle"
set "OPT_VISIBLE_6=1"

set "OPT_KEY_7=PREFERRED_RENDER_QUALITY"
set "OPT_LABEL_7=Render Quality"
set "OPT_VAL_7=%SESSION_PREFERRED_RENDER_QUALITY%"
set "OPT_ALLOWED_7=auto high middle low"
set "OPT_DESC_7=Set preferred visual density and layout profile."
set "OPT_TYPE_7=setting"
set "OPT_KIND_7=choice"
set "OPT_VISIBLE_7=1"

set "OPT_KEY_8=BGM_SOUNDTRACK"
set "OPT_LABEL_8=BGM Soundtrack"
set "OPT_VAL_8=%SESSION_BGM_SOUNDTRACK%"
set "OPT_ALLOWED_8=STARFALL ETERNAL REVELATION BATTLE"
set "OPT_DESC_8=Choose the currently used menu soundtrack and preview it instantly."
set "OPT_TYPE_8=setting"
set "OPT_KIND_8=choice"
set "OPT_VISIBLE_8=1"

set "OPT_LABEL_9=[ Version ]"
set "OPT_DESC_9=View current build version and settings module milestone."
set "OPT_TYPE_9=action"
set "OPT_ACTION_9=version"
set "OPT_VISIBLE_9=1"

set "OPT_LABEL_10=[ Credits ]"
set "OPT_DESC_10=View music, project, and development credits."
set "OPT_TYPE_10=action"
set "OPT_ACTION_10=credits"
set "OPT_VISIBLE_10=1"

set "OPT_LABEL_11=[ Initialize Game System ]"
set "OPT_DESC_11=Reset configuration, caches, and logs to first-launch state."
set "OPT_TYPE_11=action"
set "OPT_ACTION_11=initialize"
set "OPT_VISIBLE_11=1"

set "OPT_LABEL_12=[ Confirm & Save ]"
set "OPT_DESC_12=Save modified session changes safely to user_config.env."
set "OPT_TYPE_12=action"
set "OPT_ACTION_12=save"
set "OPT_VISIBLE_12=1"

set "OPT_LABEL_13=[ Cancel & Back ]"
set "OPT_DESC_13=Discard setting edits and return to the Main Menu."
set "OPT_TYPE_13=action"
set "OPT_ACTION_13=back"
set "OPT_VISIBLE_13=1"

set "current_selected=1"
set "last_selected="
set "last_help_idx="
set "idle_tick=0"
set "marquee_tick=0"
set "marquee_offset=0"
set "POLLING_ENABLED=0"
if defined cmdwiz_path set "POLLING_ENABLED=1"

if /i "%RENDER_QUALITY%"=="LOW" (
    set "color_selected=30;47"
    set "color_label=7"
    set "color_normal=0"
    set "color_border=90"
) else if /i "%RENDER_QUALITY%"=="MIDDLE" (
    set "color_selected=30;47"
    set "color_label=36"
    set "color_normal=0"
    set "color_border=90"
) else (
    set "color_selected=30;46"
    set "color_label=96"
    set "color_normal=0"
    set "color_border=90"
)

call :Initialize_Help_Metadata
call :Reflow_Settings_Layout
if "%POLLING_ENABLED%"=="1" call "%cmdwiz_path%" flushkeys >nul 2>&1

:SettingsLoop
    call :Display_SettingsMenu
:SettingsInputLoop
    call :GetChoice
    if "%choice%"=="0" (
        call :Handle_Idle_Tick
    ) else (
        call :HandleKey %choice%
        if not defined UI_ACTION call :Quick_Update_Display
    )
    if defined UI_ACTION (
        if exist "%RCSU%" call "%RCSU%" -trace INFO SettingsMenu "exit settings UI_ACTION=%UI_ACTION%"
        endlocal & (
            set "UI_ACTION=%UI_ACTION%"
            set "LANGUAGE=%LANGUAGE%"
            set "SOUND_FX_ENABLED=%SOUND_FX_ENABLED%"
            set "SE_VOLUME=%SE_VOLUME%"
            set "BGM_VOLUME=%BGM_VOLUME%"
            set "BGM_SOUNDTRACK=%BGM_SOUNDTRACK%"
            set "TUTORIAL=%TUTORIAL%"
            set "AUTO_SAVE=%AUTO_SAVE%"
            set "PREFERRED_RENDER_QUALITY=%PREFERRED_RENDER_QUALITY%"
        )
        exit /b 0
    )
    goto :SettingsInputLoop


:Display_SettingsMenu
    cls
    set "OPT_TITLE_TEXT=SETTINGS & CONFIGURATION"
    set "OPT_SUBTITLE_TEXT=~ Options Customizer Shell ~"
    set "OPT_FOOTER_RIGHT_TEXT_1=Developed by HedgeHogSoft"
    set "OPT_FOOTER_RIGHT_TEXT_2=(c) 2024-2026 RPGGAME."

    call :Draw_Box %OPT_FRAME_LEFT% %OPT_FRAME_TOP% %OPT_FRAME_RIGHT% %OPT_FRAME_BOTTOM%
    call :Print_Centered %OPT_TITLE_ROW% "!OPT_TITLE_TEXT!"
    if "%OPT_SHOW_SUBTITLE%"=="1" call :Print_Centered %OPT_SUBTITLE_ROW% "!OPT_SUBTITLE_TEXT!"
    call :Draw_Box %OPT_HELP_BOX_LEFT% %OPT_HELP_BOX_TOP% %OPT_HELP_BOX_RIGHT% %OPT_HELP_BOX_BOTTOM%

    if "%OPT_SHOW_FOOTER%"=="1" (
        echo !esc![%OPT_FOOTER_ROW_1%;%OPT_FOOTER_LEFT_COL%H%app_title%
        echo !esc![%OPT_FOOTER_ROW_2%;%OPT_FOOTER_LEFT_COL%HVersion: %app_version_display%
        call :Print_Right %OPT_FOOTER_ROW_1% %OPT_FRAME_RIGHT% "!OPT_FOOTER_RIGHT_TEXT_1!"
        call :Print_Right %OPT_FOOTER_ROW_2% %OPT_FRAME_RIGHT% "!OPT_FOOTER_RIGHT_TEXT_2!"
    )

    for /l %%i in (1,1,%OPT_COUNT%) do (
        if "!OPT_VISIBLE_%%i!"=="1" (
            set "sel=0"
            if "%%i"=="%current_selected%" set "sel=1"
            call :Render_Item %%i !sel!
        )
    )

    call :Render_Help_Text %current_selected%
    set "last_selected=%current_selected%"
    set "last_help_idx=%current_selected%"
    exit /b 0


:Quick_Update_Display
    setlocal EnableDelayedExpansion
    if not defined last_selected set "last_selected=%current_selected%"
    if "%last_selected%"=="%current_selected%" (
        call :Render_Item %current_selected% 1
    ) else (
        call :Render_Item %last_selected% 0
        call :Render_Item %current_selected% 1
    )
    if not defined last_help_idx set "last_help_idx=%current_selected%"
    if not "%last_help_idx%"=="%current_selected%" (
        call :Render_Help_Text %current_selected%
    )
    endlocal & (
        set "last_selected=%current_selected%"
        set "last_help_idx=%current_selected%"
    )
    exit /b 0


:GetChoice
    if "%POLLING_ENABLED%"=="1" (
        call :PollChoice
    ) else (
        choice /n /c WSADFQ >nul
        set "choice=%errorlevel%"
    )
    exit /b 0


:Handle_Idle_Tick
    set /a "idle_tick+=1"
    set /a "marquee_tick+=1"
    if %marquee_tick% geq 3 (
        set "marquee_tick=0"
        call :Advance_Help_Marquee
    )
    exit /b 0


:PollChoice
    set "choice=0"
    "%cmdwiz_path%" getch noWait >nul 2>&1
    set "scan_code=%errorlevel%"
    if "%scan_code%"=="0" (
        "%cmdwiz_path%" delay 10 >nul 2>&1
        exit /b 0
    )
    if "%scan_code%"=="87" set "choice=1"
    if "%scan_code%"=="83" set "choice=2"
    if "%scan_code%"=="65" set "choice=3"
    if "%scan_code%"=="68" set "choice=4"
    if "%scan_code%"=="70" set "choice=5"
    if "%scan_code%"=="81" set "choice=6"
    if "%scan_code%"=="119" set "choice=1"
    if "%scan_code%"=="115" set "choice=2"
    if "%scan_code%"=="97" set "choice=3"
    if "%scan_code%"=="100" set "choice=4"
    if "%scan_code%"=="102" set "choice=5"
    if "%scan_code%"=="113" set "choice=6"
    if "%scan_code%"=="17" set "choice=1"
    if "%scan_code%"=="31" set "choice=2"
    if "%scan_code%"=="30" set "choice=3"
    if "%scan_code%"=="32" set "choice=4"
    if "%scan_code%"=="33" set "choice=5"
    if "%scan_code%"=="16" set "choice=6"
    if "%scan_code%"=="72" set "choice=1"
    if "%scan_code%"=="80" set "choice=2"
    if "%scan_code%"=="75" set "choice=3"
    if "%scan_code%"=="77" set "choice=4"
    if "%scan_code%"=="28" set "choice=5"
    if "%scan_code%"=="1" set "choice=6"
    exit /b 0


:HandleKey
    set "key=%1"
    set "idle_tick=0"
    set "marquee_tick=0"
    if "%key%"=="1" call :Move_Up
    if "%key%"=="2" call :Move_Down
    if "%key%"=="3" call :Cycle_Value -1
    if "%key%"=="4" call :Cycle_Value 1
    if "%key%"=="5" call :Handle_Select
    if "%key%"=="6" (
        call :Show_Confirm_Dialog "Discard configuration changes?"
        if "!DIALOG_RES!"=="1" (
            if defined ORIGINAL_BGM_VOLUME (
                set "BGM_VOLUME=%ORIGINAL_BGM_VOLUME%"
                call "%src_audio_dir%\BgmPlayer.bat" VOLUME %ORIGINAL_BGM_VOLUME% 120 >nul 2>&1
            )
            if defined ORIGINAL_BGM_SOUNDTRACK (
                set "BGM_SOUNDTRACK=%ORIGINAL_BGM_SOUNDTRACK%"
                call :Preview_Bgm_Soundtrack
            )
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
            set "UI_ACTION=MAINMENU"
        ) else (
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
            call :Display_SettingsMenu
        )
    )
    exit /b 0


:Move_Up
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav" >nul 2>&1
    set "marquee_offset=0"
    :MoveUpLoop
    set /a "current_selected-=1"
    if %current_selected% lss 1 set "current_selected=%OPT_COUNT%"
    if "!OPT_VISIBLE_%current_selected%!"=="0" goto :MoveUpLoop
    exit /b 0


:Move_Down
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav" >nul 2>&1
    set "marquee_offset=0"
    :MoveDownLoop
    set /a "current_selected+=1"
    if %current_selected% gtr %OPT_COUNT% set "current_selected=1"
    if "!OPT_VISIBLE_%current_selected%!"=="0" goto :MoveDownLoop
    exit /b 0


:Cycle_Value
    set "dir=%1"
    set "type=!OPT_TYPE_%current_selected%!"
    if not "!type!"=="setting" exit /b 0

    set "kind=!OPT_KIND_%current_selected%!"
    if "!kind!"=="range" (
        call :Cycle_Range_Value %current_selected% %dir%
    ) else (
        call :Cycle_Choice_Value %current_selected% %dir%
    )

    call :Sync_Se_Audio_State %current_selected%
    call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Move.wav" >nul 2>&1
    call :Preview_Runtime_Option %current_selected%
    exit /b 0


:Handle_Select
    set "type=!OPT_TYPE_%current_selected%!"
    if "!type!"=="setting" exit /b 0

    set "action=!OPT_ACTION_%current_selected%!"
    if "%action%"=="save" (
        call :Show_Confirm_Dialog "Save configuration?"
        if "!DIALOG_RES!"=="1" (
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav" >nul 2>&1
            call :Persist_Settings
            if not errorlevel 1 (
                call "%src_audio_dir%\BgmPlayer.bat" VOLUME %BGM_VOLUME% 180 >nul 2>&1
                set "UI_ACTION=MAINMENU"
            ) else (
                call :Display_SettingsMenu
                call :Print_Centered %OPT_HELP_TEXT_ROW% "Failed to save configuration."
            )
        ) else (
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
            call :Display_SettingsMenu
        )
    ) else if "%action%"=="back" (
        call :Handle_Back_Action
    ) else if "%action%"=="version" (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav" >nul 2>&1
        call :Show_Info_Dialog "VERSION INFORMATION" "%app_title% %app_version%" "Render Module: %render_module_version%" "Build Profile: %app_build_label%"
        call :Display_SettingsMenu
    ) else if "%action%"=="credits" (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav" >nul 2>&1
        call :Show_Info_Dialog "CREDITS" "Developed by HedgeHogSoft" "Music sources: zippy / PeriTune" "(c) 2024-2026 RPGGAME."
        call :Display_SettingsMenu
    ) else if "%action%"=="initialize" (
        call :Handle_Initialize_Action
    )
    exit /b 0


:Handle_Back_Action
    call :Show_Confirm_Dialog "Discard configuration changes?"
    if "!DIALOG_RES!"=="1" (
        if defined ORIGINAL_BGM_VOLUME (
            set "BGM_VOLUME=%ORIGINAL_BGM_VOLUME%"
            call "%src_audio_dir%\BgmPlayer.bat" VOLUME %ORIGINAL_BGM_VOLUME% 120 >nul 2>&1
        )
        if defined ORIGINAL_BGM_SOUNDTRACK (
            set "BGM_SOUNDTRACK=%ORIGINAL_BGM_SOUNDTRACK%"
            call :Preview_Bgm_Soundtrack
        )
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
        set "UI_ACTION=MAINMENU"
    ) else (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
        call :Display_SettingsMenu
    )
    exit /b 0


:Handle_Initialize_Action
    call :Show_Confirm_DialogEx "DANGER: Factory reset" "Reset to first-launch state?" WARN
    if "!DIALOG_RES!"=="1" (
        call :Show_Confirm_DialogEx "Launcher will reboot." "Clear user state and continue?" WARN
        if "!DIALOG_RES!"=="1" (
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Enter.wav" >nul 2>&1
            set "UI_ACTION=SYSTEM_INIT_RESET"
        ) else (
            call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
            call :Display_SettingsMenu
        )
    ) else (
        call "%src_audio_dir%\Play_SE.bat" "%assets_sounds_fx_dir%\Cancel.wav" >nul 2>&1
        call :Display_SettingsMenu
    )
    exit /b 0


:Render_Item
    setlocal EnableDelayedExpansion
    set "target_idx=%~1"
    set "is_selected=%~2"
    set /a "current_row=OPT_LIST_TOP + ((target_idx - 1) * OPT_LIST_ROW_PITCH)"
    set "label=!OPT_LABEL_%target_idx%!"
    set "type=!OPT_TYPE_%target_idx%!"
    set "kind=!OPT_KIND_%target_idx%!"
    set "item_text="

    if "!type!"=="setting" (
        if "!kind!"=="range" (
            call :Format_Range_Item !target_idx! item_text
        ) else (
            set "val=!OPT_VAL_%target_idx%!"
            if "!OPT_KEY_%target_idx%!"=="BGM_SOUNDTRACK" call :Format_Soundtrack_Name "!val!" val
            set "padded_label=!label!                                        "
            set "item_text=!padded_label:~0,24! : [ !val! ]"
        )
    ) else (
        set "item_text=!label!                                              "
        set "item_text=!item_text:~0,42!"
    )

    set "item_text=!item_text!                                                            "
    set "item_text=!item_text:~0,%OPT_LIST_WIDTH%!"
    if "!is_selected!"=="1" (
        echo !esc![!current_row!;!OPT_LIST_LEFT!H!esc![%color_selected%m!item_text!!esc![0m
    ) else (
        echo !esc![!current_row!;!OPT_LIST_LEFT!H!esc![%color_label%m!item_text!!esc![0m
    )
    endlocal
    exit /b 0


:Render_Help_Text
    setlocal EnableDelayedExpansion
    set "help_idx=%~1"
    set "desc=!OPT_DESC_%help_idx%!"
    set "scroll_text=!OPT_DESC_SCROLL_%help_idx%!"
    call set /a "desc_len=%%OPT_DESC_LEN_%help_idx%%%"
    set /a "inner_width=%OPT_HELP_BOX_WIDTH% - 2"
    set /a "inner_col=%OPT_HELP_BOX_LEFT% + 1"
    if !desc_len! leq !inner_width! (
        set "line=!desc!"
        set "line=!line!                                                                                                                        "
        set "line=!line:~0,%inner_width%!"
    ) else (
        set "scroll_text=!desc!   "
        set "scroll_text=!scroll_text!!desc!   "
        set "line=!scroll_text:~%marquee_offset%,%inner_width%!"
        set "line=!line!                                                                                                                        "
        set "line=!line:~0,%inner_width%!"
    )
    echo !esc![%OPT_HELP_TEXT_ROW%;!inner_col!H!line!
    endlocal
    exit /b 0


:Advance_Help_Marquee
    setlocal EnableDelayedExpansion
    set /a "inner_width=%OPT_HELP_BOX_WIDTH% - 2"
    call set /a "desc_len=%%OPT_DESC_LEN_%current_selected%%%"
    if !desc_len! gtr !inner_width! (
        set /a "max_offset=desc_len + 3"
        set /a "marquee_offset+=1"
        if !marquee_offset! geq !max_offset! set "marquee_offset=0"
        call :Render_Help_Text %current_selected%
    ) else (
        if not "%marquee_offset%"=="0" (
            endlocal & (
                set "marquee_offset=0"
            )
            call :Render_Help_Text %current_selected%
            exit /b 0
        )
    )
    for %%# in (!marquee_offset!) do endlocal & set "marquee_offset=%%#"
    exit /b 0


:Initialize_Help_Metadata
    for /l %%i in (1,1,%OPT_COUNT%) do (
        call set "meta_desc=%%OPT_DESC_%%i%%"
        call :StrLen meta_desc meta_len
        set "OPT_DESC_LEN_%%i=!meta_len!"
        call set "OPT_DESC_SCROLL_%%i=%%meta_desc%%   %%meta_desc%%   "
    )
    exit /b 0


:Cycle_Choice_Value
    set "target_idx=%~1"
    set "dir=%~2"
    call set "allowed=%%OPT_ALLOWED_%target_idx%%%"
    call set "cur_val=%%OPT_VAL_%target_idx%%%"

    set "found_idx="
    set "count=0"
    for %%a in (%allowed%) do (
        set /a "count+=1"
        if /i "%%a"=="%cur_val%" set "found_idx=!count!"
    )

    set "total_allowed=%count%"
    if not defined found_idx set "found_idx=1"

    set /a "next_idx=found_idx + dir"
    if %next_idx% gtr %total_allowed% set "next_idx=1"
    if %next_idx% lss 1 set "next_idx=%total_allowed%"

    set "new_val="
    set "count=0"
    for %%a in (%allowed%) do (
        set /a "count+=1"
        if "!count!"=="%next_idx%" set "new_val=%%a"
    )

    set "OPT_VAL_%target_idx%=%new_val%"
    exit /b 0


:Cycle_Range_Value
    set "target_idx=%~1"
    set "dir=%~2"
    call set /a "cur_val=%%OPT_VAL_%target_idx%%%"
    call set /a "min_val=%%OPT_MIN_%target_idx%%%"
    call set /a "max_val=%%OPT_MAX_%target_idx%%%"
    call set /a "step_val=%%OPT_STEP_%target_idx%%%"
    set /a "next_val=cur_val + (dir * step_val)"
    if %next_val% lss %min_val% set /a "next_val=min_val"
    if %next_val% gtr %max_val% set /a "next_val=max_val"
    set "OPT_VAL_%target_idx%=%next_val%"
    exit /b 0


:Sync_Se_Audio_State
    set "target_idx=%~1"
    call set "target_key=%%OPT_KEY_%target_idx%%%"
    if /i "%target_key%"=="SE_VOLUME" (
        call set "se_value=%%OPT_VAL_%target_idx%%%"
        if "%se_value%"=="0" (
            set "OPT_VAL_2=OFF"
        ) else (
            set "OPT_VAL_2=ON"
        )
    )
    exit /b 0


:Format_Range_Item
    setlocal EnableDelayedExpansion
    set "target_idx=%~1"
    call set /a "range_value=%%OPT_VAL_%target_idx%%%"
    call :Build_Volume_Bar !range_value! 10 bar_text
    call set "label_text=%%OPT_LABEL_%target_idx%%%"
    set "padded_label=!label_text!                    "
    set "line=!padded_label:~0,16! : [!bar_text!] !range_value!%%"
    endlocal & set "%~2=%line%"
    exit /b 0


:Build_Volume_Bar
    setlocal EnableDelayedExpansion
    set /a "range_value=%~1"
    set /a "slot_count=%~2"
    set /a "filled_slots=(range_value + 5) / 10"
    if !filled_slots! lss 0 set /a "filled_slots=0"
    if !filled_slots! gtr !slot_count! set /a "filled_slots=slot_count"
    set "bar="
    for /l %%i in (1,1,!slot_count!) do (
        if %%i LEQ !filled_slots! (
            set "bar=!bar!#"
        ) else (
            set "bar=!bar!."
        )
    )
    endlocal & set "%~3=%bar%"
    exit /b 0


:Persist_Settings
    set "LANGUAGE=!OPT_VAL_1!"
    set "SOUND_FX_ENABLED=!OPT_VAL_2!"
    set "SE_VOLUME=!OPT_VAL_3!"
    set "BGM_VOLUME=!OPT_VAL_4!"
    set "BGM_SOUNDTRACK=!OPT_VAL_8!"
    set "TUTORIAL=!OPT_VAL_5!"
    set "AUTO_SAVE=!OPT_VAL_6!"
    set "PREFERRED_RENDER_QUALITY=!OPT_VAL_7!"

    set "USER_CONFIG=%PROJECT_ROOT%\Config\user_config.env"

    if not defined CFG_PROFILE_SCHEMA set "CFG_PROFILE_SCHEMA=1"
    if not defined CFG_CODEPAGE set "CFG_CODEPAGE=65001"
    if not defined CFG_LANGUAGE set "CFG_LANGUAGE=%LANGUAGE%"
    if not defined CFG_CONSOLE_FONT set "CFG_CONSOLE_FONT=%CONSOLE_FONT%"
    if not defined CFG_SAVE_MODE set "CFG_SAVE_MODE=%SAVE_MODE%"
    if not defined CFG_SAVE_DIR set "CFG_SAVE_DIR=%SAVE_DIR%"
    if not defined CFG_CONSOLE_COLS set "CFG_CONSOLE_COLS=%CONSOLE_COLS%"
    if not defined CFG_CONSOLE_ROWS set "CFG_CONSOLE_ROWS=%CONSOLE_ROWS%"
    if not defined CFG_SOUND_FX_ENABLED set "CFG_SOUND_FX_ENABLED=%SOUND_FX_ENABLED%"
    if not defined CFG_SE_VOLUME set "CFG_SE_VOLUME=%SE_VOLUME%"
    if not defined CFG_BGM_VOLUME set "CFG_BGM_VOLUME=%BGM_VOLUME%"
    if not defined CFG_BGM_SOUNDTRACK set "CFG_BGM_SOUNDTRACK=%BGM_SOUNDTRACK%"
    if not defined CFG_TUTORIAL set "CFG_TUTORIAL=%TUTORIAL%"
    if not defined CFG_AUTO_SAVE set "CFG_AUTO_SAVE=%AUTO_SAVE%"
    if not defined CFG_PREFERRED_RENDER_QUALITY set "CFG_PREFERRED_RENDER_QUALITY=%PREFERRED_RENDER_QUALITY%"
    if exist "%USER_CONFIG%" (
        for /f "usebackq delims== tokens=1,* eol=#" %%A in ("%USER_CONFIG%") do (
            set "CFG_%%A=%%B"
        )
    )

    set "CFG_LANGUAGE=%LANGUAGE%"
    set "CFG_SOUND_FX_ENABLED=%SOUND_FX_ENABLED%"
    set "CFG_SE_VOLUME=%SE_VOLUME%"
    set "CFG_BGM_VOLUME=%BGM_VOLUME%"
    set "CFG_BGM_SOUNDTRACK=%BGM_SOUNDTRACK%"
    set "CFG_TUTORIAL=%TUTORIAL%"
    set "CFG_AUTO_SAVE=%AUTO_SAVE%"
    set "CFG_PREFERRED_RENDER_QUALITY=%PREFERRED_RENDER_QUALITY%"

    set "TMP_CONFIG=%USER_CONFIG%.tmp"
    set "FOUND_LANGUAGE=0"
    set "FOUND_SOUND=0"
    set "FOUND_SE_VOLUME=0"
    set "FOUND_BGM_VOLUME=0"
    set "FOUND_BGM_SOUNDTRACK=0"
    set "FOUND_TUTORIAL=0"
    set "FOUND_AUTO_SAVE=0"
    set "FOUND_PREF=0"

    > "%TMP_CONFIG%" (
        if exist "%USER_CONFIG%" (
            for /f "usebackq delims=" %%L in ("%USER_CONFIG%") do (
                set "line=%%L"
                set "handled=0"
                for /f "tokens=1* delims==" %%K in ("!line!") do (
                    if /i "%%K"=="LANGUAGE" (
                        echo LANGUAGE=!CFG_LANGUAGE!
                        set "FOUND_LANGUAGE=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="SOUND_FX_ENABLED" (
                        echo SOUND_FX_ENABLED=!CFG_SOUND_FX_ENABLED!
                        set "FOUND_SOUND=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="SE_VOLUME" (
                        echo SE_VOLUME=!CFG_SE_VOLUME!
                        set "FOUND_SE_VOLUME=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="BGM_VOLUME" (
                        echo BGM_VOLUME=!CFG_BGM_VOLUME!
                        set "FOUND_BGM_VOLUME=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="BGM_SOUNDTRACK" (
                        echo BGM_SOUNDTRACK=!CFG_BGM_SOUNDTRACK!
                        set "FOUND_BGM_SOUNDTRACK=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="TUTORIAL" (
                        echo TUTORIAL=!CFG_TUTORIAL!
                        set "FOUND_TUTORIAL=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="AUTO_SAVE" (
                        echo AUTO_SAVE=!CFG_AUTO_SAVE!
                        set "FOUND_AUTO_SAVE=1"
                        set "handled=1"
                    )
                    if /i "%%K"=="PREFERRED_RENDER_QUALITY" (
                        echo PREFERRED_RENDER_QUALITY=!CFG_PREFERRED_RENDER_QUALITY!
                        set "FOUND_PREF=1"
                        set "handled=1"
                    )
                )
                if "!handled!"=="0" echo(!line!
            )
        ) else (
            echo # Astral Divide profile [updated by SettingsMenu.bat]
            echo PROFILE_SCHEMA=!CFG_PROFILE_SCHEMA!
            echo CODEPAGE=!CFG_CODEPAGE!
            echo CONSOLE_FONT=!CFG_CONSOLE_FONT!
            echo SAVE_MODE=!CFG_SAVE_MODE!
            echo SAVE_DIR=!CFG_SAVE_DIR!
            echo CONSOLE_COLS=!CFG_CONSOLE_COLS!
            echo CONSOLE_ROWS=!CFG_CONSOLE_ROWS!
        )
        if "!FOUND_LANGUAGE!"=="0" echo LANGUAGE=!CFG_LANGUAGE!
        if "!FOUND_SOUND!"=="0" echo SOUND_FX_ENABLED=!CFG_SOUND_FX_ENABLED!
        if "!FOUND_SE_VOLUME!"=="0" echo SE_VOLUME=!CFG_SE_VOLUME!
        if "!FOUND_BGM_VOLUME!"=="0" echo BGM_VOLUME=!CFG_BGM_VOLUME!
        if "!FOUND_BGM_SOUNDTRACK!"=="0" echo BGM_SOUNDTRACK=!CFG_BGM_SOUNDTRACK!
        if "!FOUND_TUTORIAL!"=="0" echo TUTORIAL=!CFG_TUTORIAL!
        if "!FOUND_AUTO_SAVE!"=="0" echo AUTO_SAVE=!CFG_AUTO_SAVE!
        if "!FOUND_PREF!"=="0" echo PREFERRED_RENDER_QUALITY=!CFG_PREFERRED_RENDER_QUALITY!
    )

    move /y "%TMP_CONFIG%" "%USER_CONFIG%" >nul
    if errorlevel 1 (
        if exist "%RCSU%" call "%RCSU%" -trace ERROR SettingsMenu "failed to save user configs"
        exit /b 1
    )
    if exist "%RCSU%" call "%RCSU%" -trace INFO SettingsMenu "successfully saved user configs"
    exit /b 0


:Preview_Runtime_Option
    set "target_idx=%~1"
    call set "target_key=%%OPT_KEY_%target_idx%%%"
    if /i "%target_key%"=="BGM_VOLUME" (
        set "BGM_VOLUME=!OPT_VAL_%target_idx%!"
        call "%src_audio_dir%\BgmPlayer.bat" VOLUME !BGM_VOLUME! 120 >nul 2>&1
    ) else if /i "%target_key%"=="BGM_SOUNDTRACK" (
        set "BGM_SOUNDTRACK=!OPT_VAL_%target_idx%!"
        call :Preview_Bgm_Soundtrack
    )
    exit /b 0


:Preview_Bgm_Soundtrack
    call :Resolve_Bgm_Soundtrack_Path "%BGM_SOUNDTRACK%" PREVIEW_BGM_PATH
    if defined PREVIEW_BGM_PATH (
        call "%src_audio_dir%\Play_BGM.bat" "" stop
        call "%src_audio_dir%\Play_BGM.bat" "%PREVIEW_BGM_PATH%" repeat %BGM_VOLUME%
    )
    exit /b 0


:Resolve_Bgm_Soundtrack_Path
    set "%~2="
    if /i "%~1"=="STARFALL" set "%~2=%PROJECT_ROOT%\Assets\Sounds\StarFallHill\StarFallHill.wav"
    if /i "%~1"=="ETERNAL" set "%~2=%PROJECT_ROOT%\Assets\Sounds\EternalGround\EternalGround.wav"
    if /i "%~1"=="REVELATION" set "%~2=%PROJECT_ROOT%\Assets\Sounds\RevelationOfGod\RevelationOfGod.wav"
    if /i "%~1"=="BATTLE" set "%~2=%PROJECT_ROOT%\Assets\Sounds\BattleMusic.wav"
    exit /b 0


:Format_Soundtrack_Name
    set "soundtrack_label=%~1"
    if /i "%~1"=="STARFALL" set "soundtrack_label=StarFallHill"
    if /i "%~1"=="ETERNAL" set "soundtrack_label=EternalGround"
    if /i "%~1"=="REVELATION" set "soundtrack_label=RevelationOfGod"
    if /i "%~1"=="BATTLE" set "soundtrack_label=BattleMusic"
    set "%~2=%soundtrack_label%"
    exit /b 0


:Show_Info_Dialog
    setlocal EnableDelayedExpansion
    set "dialog_title=%~1"
    set "line1=%~2"
    set "line2=%~3"
    set "line3=%~4"
    set "dialog_fill_color=30;47"
    set "dialog_border_color=30;107"

    set /a "box_width=54"
    set /a "box_height=9"
    set /a "left=((%CONSOLE_COLS% - box_width) / 2) + 1"
    set /a "top=((%CONSOLE_ROWS% - box_height) / 2) + 1"
    set /a "right=left + box_width - 1"
    set /a "bottom=top + box_height - 1"
    set /a "row0=top + 1"
    set /a "row1=top + 2"
    set /a "row2=top + 3"
    set /a "row3=top + 4"
    set /a "row4=top + 6"

    call :Draw_Dialog_Box !left! !top! !right! !bottom! "!dialog_fill_color!" "!dialog_border_color!"
    call :Print_Centered_Color !row0! "!dialog_title!" "!dialog_fill_color!"
    call :Print_Centered_Color !row1! "!line1!" "!dialog_fill_color!"
    call :Print_Centered_Color !row2! "!line2!" "!dialog_fill_color!"
    call :Print_Centered_Color !row3! "!line3!" "!dialog_fill_color!"
    call :Print_Centered_Color !row4! "[F] Back  /  [Q] Back" "!dialog_fill_color!"

    choice /c FQ /n >nul
    endlocal
    exit /b 0


:Reflow_Settings_Layout
    set "OPT_SHOW_SUBTITLE=1"
    set "OPT_LIST_ROW_PITCH=2"
    if %CONSOLE_ROWS% lss 30 set "OPT_LIST_ROW_PITCH=1"
    if /i "%RENDER_QUALITY%"=="LOW" set "OPT_SHOW_SUBTITLE=0"

    if "%OPT_SHOW_SUBTITLE%"=="1" (
        set /a "OPT_LIST_TOP=OPT_TITLE_ROW + 4"
    ) else (
        set /a "OPT_LIST_TOP=OPT_TITLE_ROW + 3"
    )
    call set /a "OPT_LIST_BOTTOM=%%OPT_LIST_TOP%% + ((%OPT_COUNT% - 1) * %%OPT_LIST_ROW_PITCH%%)"

    set "OPT_SHOW_FOOTER=1"
    if %CONSOLE_ROWS% lss 28 set "OPT_SHOW_FOOTER=0"

    if "%OPT_SHOW_FOOTER%"=="1" (
        set /a "max_help_top=%OPT_FOOTER_ROW_1% - %OPT_HELP_BOX_HEIGHT% - 1"
    ) else (
        set /a "max_help_top=%CONSOLE_ROWS% - %OPT_HELP_BOX_HEIGHT% - 2"
    )

    call set /a "min_help_top=%%OPT_LIST_BOTTOM%% + 2"
    if %min_help_top% gtr %max_help_top% (
        set "OPT_LIST_ROW_PITCH=1"
        set "OPT_SHOW_SUBTITLE=0"
        set /a "OPT_LIST_TOP=OPT_TITLE_ROW + 3"
        call set /a "OPT_LIST_BOTTOM=%%OPT_LIST_TOP%% + ((%OPT_COUNT% - 1) * %%OPT_LIST_ROW_PITCH%%)"
        call set /a "min_help_top=%%OPT_LIST_BOTTOM%% + 2"
    )

    set /a "OPT_HELP_BOX_TOP=min_help_top"
    if %OPT_HELP_BOX_TOP% lss 1 set /a "OPT_HELP_BOX_TOP=1"
    if %OPT_HELP_BOX_TOP% gtr %max_help_top% set /a "OPT_HELP_BOX_TOP=max_help_top"
    set /a "OPT_HELP_BOX_BOTTOM=OPT_HELP_BOX_TOP + OPT_HELP_BOX_HEIGHT - 1"
    set /a "OPT_HELP_TEXT_ROW=OPT_HELP_BOX_TOP + 1"
    exit /b 0


:Show_Confirm_Dialog
    setlocal EnableDelayedExpansion

    set "dialog_title=%~1"
    set "dialog_style=%~2"
    set "dialog_fill_color=30;47"
    set "dialog_border_color=30;107"
    set "dialog_text_color=30;47"
    if /i "!dialog_style!"=="WARN" (
        set "dialog_fill_color=97;41"
        set "dialog_border_color=97;101"
        set "dialog_text_color=97;41"
    )

    set /a "box_width=42"
    set /a "box_height=7"
    set /a "left=((%CONSOLE_COLS% - box_width) / 2) + 1"
    set /a "top=((%CONSOLE_ROWS% - box_height) / 2) + 1"
    set /a "right=left + box_width - 1"
    set /a "bottom=top + box_height - 1"

    set /a "row_t=top + 2"
    set /a "row_a=top + 4"
    call :Draw_Dialog_Box !left! !top! !right! !bottom! "!dialog_fill_color!" "!dialog_border_color!"
    call :Print_Centered_Color !row_t! "!dialog_title!" "!dialog_text_color!"
    call :Print_Centered_Color !row_a! "[Y]es  /  [N]o" "!dialog_text_color!"

    choice /c YN /n >nul
    set "dialog_res=%errorlevel%"

    endlocal & set "DIALOG_RES=%dialog_res%"
    exit /b 0


:Show_Confirm_DialogEx
    setlocal EnableDelayedExpansion

    set "dialog_title=%~1"
    set "dialog_line2=%~2"
    set "dialog_style=%~3"
    set "dialog_fill_color=30;47"
    set "dialog_border_color=30;107"
    set "dialog_text_color=30;47"
    if /i "!dialog_style!"=="WARN" (
        set "dialog_fill_color=97;41"
        set "dialog_border_color=97;101"
        set "dialog_text_color=97;41"
    )

    set /a "box_width=46"
    set /a "box_height=8"
    set /a "left=((%CONSOLE_COLS% - box_width) / 2) + 1"
    set /a "top=((%CONSOLE_ROWS% - box_height) / 2) + 1"
    set /a "right=left + box_width - 1"
    set /a "bottom=top + box_height - 1"
    set /a "row_t1=top + 2"
    set /a "row_t2=top + 3"
    set /a "row_a=top + 5"

    call :Draw_Dialog_Box !left! !top! !right! !bottom! "!dialog_fill_color!" "!dialog_border_color!"
    call :Print_Centered_Color !row_t1! "!dialog_title!" "!dialog_text_color!"
    call :Print_Centered_Color !row_t2! "!dialog_line2!" "!dialog_text_color!"
    call :Print_Centered_Color !row_a! "[Y]es  /  [N]o" "!dialog_text_color!"

    choice /c YN /n >nul
    set "dialog_res=%errorlevel%"

    endlocal & set "DIALOG_RES=%dialog_res%"
    exit /b 0


:Draw_Dialog_Box
    setlocal EnableDelayedExpansion
    set "l=%~1"
    set "t=%~2"
    set "r=%~3"
    set "b=%~4"
    set "fill_color=%~5"
    set "border_color=%~6"
    set /a "box_w=r-l+1"
    set /a "inner_w=box_w-2"
    set /a "inner_t=t+1"
    set /a "inner_b=b-1"
    set "fill_line="
    for /l %%i in (1,1,!box_w!) do set "fill_line=!fill_line! "
    set "h_line="
    for /l %%i in (1,1,!inner_w!) do set "h_line=!h_line!-"

    for /l %%y in (!t!,1,!b!) do (
        echo !esc![%%y;!l!H!esc![!fill_color!m!fill_line!!esc![0m
    )
    echo !esc![!t!;!l!H!esc![!border_color!m+!h_line!+!esc![0m
    for /l %%y in (!inner_t!,1,!inner_b!) do (
        echo !esc![%%y;!l!H!esc![!border_color!m^|!esc![0m!esc![%%y;!r!H!esc![!border_color!m^|!esc![0m
    )
    echo !esc![!b!;!l!H!esc![!border_color!m+!h_line!+!esc![0m
    endlocal
    exit /b 0


:Draw_Box
    setlocal EnableDelayedExpansion
    set "l=%~1"
    set "t=%~2"
    set "r=%~3"
    set "b=%~4"
    set /a "inner_w=r-l-1"
    set /a "inner_t=t+1"
    set /a "inner_b=b-1"
    set "ln="
    for /l %%i in (1,1,!inner_w!) do set "ln=!ln!-"
    echo !esc![!t!;!l!H+!ln!+
    for /l %%y in (!inner_t!,1,!inner_b!) do (
        echo !esc![%%y;!l!H^|!esc![%%y;!r!H^|
    )
    echo !esc![!b!;!l!H+!ln!+
    endlocal
    exit /b 0


:Print_Centered
    setlocal EnableDelayedExpansion
    set "r=%~1"
    set "txt=%~2"
    call :StrLen txt txt_len
    set /a "c=((%CONSOLE_COLS% - txt_len) / 2) + 1"
    echo !esc![!r!;!c!H!txt!
    endlocal
    exit /b 0


:Print_Centered_Color
    setlocal EnableDelayedExpansion
    set "r=%~1"
    set "txt=%~2"
    set "color=%~3"
    call :StrLen txt txt_len
    set /a "c=((%CONSOLE_COLS% - txt_len) / 2) + 1"
    echo !esc![!r!;!c!H!esc![!color!m!txt!!esc![0m
    endlocal
    exit /b 0


:Print_Right
    setlocal EnableDelayedExpansion
    set "r=%~1"
    set "right_col=%~2"
    set "txt=%~3"
    call :StrLen txt txt_len
    set /a "c=right_col-txt_len"
    if !c! lss 1 set /a "c=1"
    echo !esc![!r!;!c!H!txt!
    endlocal
    exit /b 0


:Clear_Help_Line
    setlocal EnableDelayedExpansion
    set "row=%~1"
    set /a "width=%OPT_HELP_BOX_WIDTH% - 2"
    set /a "col=%OPT_HELP_BOX_LEFT% + 1"
    set "blank="
    for /l %%i in (1,1,!width!) do set "blank=!blank! "
    echo !esc![!row!;!col!H!blank!
    endlocal
    exit /b 0


:StrLen
    setlocal EnableDelayedExpansion
    set "s=!%~1!"
    set /a len=0
    :StrLenLoop
    if defined s (
        set "s=!s:~1!"
        set /a len+=1
        goto StrLenLoop
    )
    endlocal & set "%~2=%len%"
    exit /b 0
