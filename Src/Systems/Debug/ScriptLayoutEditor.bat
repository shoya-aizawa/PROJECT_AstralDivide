@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0..\Environment\SettingPath.bat" SILENT >nul 2>&1
for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"
set "CMDWIZ=%tools_dir%\cmdwiz.exe"
mode 240,67 >nul 2>&1
powershell -NoProfile -NonInteractive -InputFormat None -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{F11}')" >nul 2>&1
call :InitStaticUi

if "%~1"=="" (
    call :PickTargetFile
    if not defined TARGET_FILE endlocal & exit /b 0
) else (
    set "TARGET_FILE=%~f1"
)
if not exist "%TARGET_FILE%" (
    echo Target file not found: "%TARGET_FILE%"
    exit /b 1
)

set "BG_IMAGE=%~f2"
if not defined BG_IMAGE set "BG_IMAGE=%assets_images_dir%\AD_StarrySky.png"
call :BuildSceneSet
call :ApplyBackground

set "BACKUP_FILE=%TARGET_FILE%.layoutbak"
if not exist "%BACKUP_FILE%" copy /y "%TARGET_FILE%" "%BACKUP_FILE%" >nul

set "UNDO_DIR=%TEMP%\ad_layout_editor_%RANDOM%_%RANDOM%"
md "%UNDO_DIR%" >nul 2>&1
set /a undo_count=0
set /a redo_count=0

call :LoadFile
if %group_count% LEQ 0 (
    echo No {pos:y:x} lines found in target.
    exit /b 2
)

set "first_pos_line="
for /l %%i in (1,1,%line_count%) do (
    if not defined first_pos_line if defined line_y_%%i set "first_pos_line=%%i"
)
if not defined first_pos_line (
    echo No positioned lines found in target.
    exit /b 3
)
set /a cursor_y=!line_y_%first_pos_line%!
set /a cursor_x=!line_x_%first_pos_line%!
if %cursor_y% LSS 1 set /a cursor_y=1
if %cursor_x% LSS 1 set /a cursor_x=1

set "hover_group="
set "grabbed_group="
set "status_msg=Move cursor onto text and press G to grab."
set /a prev_cursor_y=0
set /a prev_cursor_x=0
set "prev_hover_group="
set "grid_on=0"

call :FullRender

:main_loop
call :PollKey
if "%key_code%"=="0" (
    "%CMDWIZ%" delay 10 >nul 2>&1
    goto :main_loop
)

if "%key_code%"=="81" call :ReturnToPicker & goto :main_loop
if /i "%key_code%"=="113" call :ReturnToPicker & goto :main_loop
if "%key_code%"=="88" goto :done
if /i "%key_code%"=="120" goto :done

if "%key_code%"=="82" call :ReloadFileAndRender & goto :main_loop
if /i "%key_code%"=="114" call :ReloadFileAndRender & goto :main_loop

if "%key_code%"=="85" call :UndoAndRender & goto :main_loop
if /i "%key_code%"=="117" call :UndoAndRender & goto :main_loop

if "%key_code%"=="90" call :RedoAndRender & goto :main_loop
if /i "%key_code%"=="122" call :RedoAndRender & goto :main_loop

if "%key_code%"=="69" call :EditCurrentTextAndRender & goto :main_loop
if /i "%key_code%"=="101" call :EditCurrentTextAndRender & goto :main_loop

if "%key_code%"=="73" call :EditCurrentIdAndRender & goto :main_loop
if /i "%key_code%"=="105" call :EditCurrentIdAndRender & goto :main_loop

if "%key_code%"=="71" call :ToggleGrabAndRender & goto :main_loop
if /i "%key_code%"=="103" call :ToggleGrabAndRender & goto :main_loop

if "%key_code%"=="74" call :JumpToIdAndRender & goto :main_loop
if /i "%key_code%"=="106" call :JumpToIdAndRender & goto :main_loop

if "%key_code%"=="80" call :PlayPreviewAndReturn & goto :main_loop
if /i "%key_code%"=="112" call :PlayPreviewAndReturn & goto :main_loop

if "%key_code%"=="76" call :ToggleGridAndRender & goto :main_loop
if /i "%key_code%"=="108" call :ToggleGridAndRender & goto :main_loop

if "%key_code%"=="66" call :PickBackgroundAndRender & goto :main_loop
if /i "%key_code%"=="98" call :PickBackgroundAndRender & goto :main_loop

if "%key_code%"=="78" call :OpenAdjacentScene 1 & goto :main_loop
if /i "%key_code%"=="110" call :OpenAdjacentScene 1 & goto :main_loop
if "%key_code%"=="77" call :OpenAdjacentScene -1 & goto :main_loop
if /i "%key_code%"=="109" call :OpenAdjacentScene -1 & goto :main_loop

if "%key_code%"=="87" call :HandleMove -5 0 5 & goto :main_loop
if "%key_code%"=="119" call :HandleMove -1 0 1 & goto :main_loop
if "%key_code%"=="83" call :HandleMove 5 0 5 & goto :main_loop
if "%key_code%"=="115" call :HandleMove 1 0 1 & goto :main_loop
if "%key_code%"=="65" call :HandleMove 0 -10 10 & goto :main_loop
if "%key_code%"=="97" call :HandleMove 0 -1 1 & goto :main_loop
if "%key_code%"=="68" call :HandleMove 0 10 10 & goto :main_loop
if "%key_code%"=="100" call :HandleMove 0 1 1 & goto :main_loop

goto :main_loop

:done
<nul set /p="%ESC%[?25h%ESC%[0m"
if exist "%UNDO_DIR%" rd /s /q "%UNDO_DIR%" >nul 2>&1
endlocal
exit /b 0

:PollKey
set "key_code=0"
"%CMDWIZ%" getch noWait >nul 2>&1
set "key_code=%errorlevel%"
exit /b 0

:PickTargetFile
set /a pick_count=0
for /f "delims=" %%F in ('dir /b /s "%src_textassets_dir%\*.txt"') do (
    set /a pick_count+=1
    set "pick_file_!pick_count!=%%~fF"
)
if !pick_count! LEQ 0 exit /b 0
set /a pick_index=1
:pick_loop
cls
echo %ESC%[43;30m Script Layout Editor - File Picker %ESC%[0m
echo.
echo %ESC%[90mW/S = move   E = open   Q = cancel%ESC%[0m
echo.
set /a pick_start=pick_index-8
if !pick_start! LSS 1 set /a pick_start=1
set /a pick_end=pick_start+15
if !pick_end! GTR !pick_count! set /a pick_end=pick_count
for /l %%i in (!pick_start!,1,!pick_end!) do (
    set "mark=  "
    if %%i==!pick_index! set "mark=> "
    call set "entry=%%pick_file_%%i%%"
    echo(!mark!%%i. !entry!
)
choice /c WSEQ /n >nul
set "pick_key=!errorlevel!"
if !pick_key!==1 if !pick_index! GTR 1 set /a pick_index-=1
if !pick_key!==2 if !pick_index! LSS !pick_count! set /a pick_index+=1
if !pick_key!==3 call set "TARGET_FILE=%%pick_file_!pick_index!%%" & exit /b 0
if !pick_key!==4 exit /b 0
goto :pick_loop

:InitStaticUi
set "GRID_HLINE="
for /l %%i in (1,1,240) do set "GRID_HLINE=!GRID_HLINE!."
exit /b 0

:BuildSceneSet
for %%F in ("%TARGET_FILE%") do set "SCENE_DIR=%%~dpF"
set /a scene_count=0
set /a scene_index=0
for /f "delims=" %%F in ('dir /b /on "%SCENE_DIR%Scene*.txt" 2^>nul') do (
    set /a scene_count+=1
    set "scene_file_!scene_count!=%SCENE_DIR%%%F"
    if /i "%SCENE_DIR%%%F"=="%TARGET_FILE%" set /a scene_index=!scene_count!
)
if %scene_index% LEQ 0 set /a scene_index=1
exit /b 0

:SyncSceneIndex
set /a scene_index=0
for /l %%i in (1,1,%scene_count%) do (
    call set "candidate=%%scene_file_%%i%%"
    if /i "!candidate!"=="%TARGET_FILE%" set /a scene_index=%%i
)
if %scene_index% LEQ 0 set /a scene_index=1
exit /b 0

:ResetUndoHistory
if exist "%UNDO_DIR%" del /q "%UNDO_DIR%\*.txt" >nul 2>&1
set /a undo_count=0
set /a redo_count=0
exit /b 0

:ApplyBackground
if exist "%BG_IMAGE%" %tools_dir%\cmdbkg.exe "%BG_IMAGE%" /b >nul 2>&1
exit /b 0

:LoadFile
for /l %%i in (1,1,999) do (
    set "line_raw_%%i="
    set "line_id_%%i="
    set "line_y_%%i="
    set "line_x_%%i="
    set "line_w_%%i="
    set "line_hit_l_%%i="
    set "line_hit_r_%%i="
    set "line_cache_speaker_%%i="
    set "line_cache_markup_%%i="
)
for /l %%i in (1,1,999) do (
    set "group_id_%%i="
    set "group_first_line_%%i="
)
set /a line_count=0
set /a group_count=0

for /f "usebackq eol=# delims=" %%L in ("%TARGET_FILE%") do (
    set /a line_count+=1
    set "line_raw_!line_count!=%%L"
    set "scan=%%L"
    set "line_id="
    set "line_y="
    set "line_x="
    set "line_w="

    echo !scan! | findstr /c:"{id:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=1 delims=}" %%a in ("!scan:*{id:=!") do set "line_id=%%a"
    )

    echo !scan! | findstr /c:"{pos:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=1,2 delims=:}" %%a in ("!scan:*{pos:=!") do (
            set "line_y=%%a"
            set "line_x=%%b"
        )
        if not defined line_id set "line_id=L!line_count!"
        call :MeasureVisibleWidth "%%L" line_w
        call :MeasureSpeakerWidth "%%L" line_sw
        set /a total_w=!line_w! + !line_sw!
        if !total_w! LSS 1 set "total_w=1"
        set "line_id_!line_count!=!line_id!"
        set "line_y_!line_count!=!line_y!"
        set "line_x_!line_count!=!line_x!"
        set "line_w_!line_count!=!total_w!"
        set /a line_hit_l_!line_count!=!line_x! - 1
        set /a line_hit_r_!line_count!=!line_x! + !total_w!
        call :BuildRenderCache !line_count!
        call :RegisterGroup "!line_id!" !line_count!
    )
)
exit /b 0

:MeasureVisibleWidth
setlocal EnableDelayedExpansion
set "raw=%~1"
set "s=!raw!"
:strip_loop
for /f "tokens=1* delims={" %%a in ("!s!") do (
    set "left=%%a"
    set "rest=%%b"
)
if defined rest (
    for /f "tokens=1* delims=}" %%a in ("!rest!") do (
        set "rest_after=%%b"
    )
    set "s=!left!!rest_after!"
    set "rest="
    set "rest_after="
    goto :strip_loop
)
set "len=0"
:len_loop
if defined s (
    set "s=!s:~1!"
    set /a len+=1
    goto :len_loop
)
endlocal & set "%~2=%len%"
exit /b 0

:MeasureSpeakerWidth
setlocal EnableDelayedExpansion
set "raw=%~1"
set /a sw=0
echo !raw! | findstr /c:"{player_name_tag}" >nul
if !errorlevel! == 0 (
    set "pn=%player_name%"
    set /a sw=3
    :pn_len_loop
    if defined pn (
        set "pn=!pn:~1!"
        set /a sw+=1
        goto :pn_len_loop
    )
    endlocal & set "%~2=%sw%"
    exit /b 0
)
echo !raw! | findstr /c:"{player}" >nul
if !errorlevel! == 0 set /a sw=6
echo !raw! | findstr /c:"{heroine}" >nul
if !errorlevel! == 0 set /a sw=6
echo !raw! | findstr /c:"{unknown}" >nul
if !errorlevel! == 0 set /a sw=6
echo !raw! | findstr /c:"{both}" >nul
if !errorlevel! == 0 set /a sw=7
endlocal & set "%~2=%sw%"
exit /b 0

:RegisterGroup
set "candidate=%~1"
set "line_index=%~2"
for /l %%i in (1,1,%group_count%) do (
    if /i "!group_id_%%i!"=="%candidate%" exit /b 0
)
set /a group_count+=1
set "group_id_%group_count%=%candidate%"
set "group_first_line_%group_count%=%line_index%"
exit /b 0

:FullRender
cls
for /l %%i in (1,1,%line_count%) do (
    set "raw=!line_raw_%%i!"
    if defined raw (
        if not "!raw!"=="{clear}" call :RenderCachedLine %%i
    )
)
call :UpdateHover
if "%grid_on%"=="1" call :DrawGridFast
call :DrawGuide
call :DrawStatus
call :DrawCursor
set /a prev_cursor_y=%cursor_y%
set /a prev_cursor_x=%cursor_x%
set "prev_hover_group=%hover_group%"
exit /b 0

:DrawGuide
<nul set /p="%ESC%[4;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[5;24H%ESC%[0K"
<nul set /p="%ESC%[63;24H%ESC%[90m────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────%ESC%[0m"
<nul set /p="%ESC%[64;24H%ESC%[0K"
<nul set /p="%ESC%[65;28H%ESC%[90mlayout edit%ESC%[0m"
exit /b 0

:DrawStatus
set "hover_label=(none)"
if defined hover_group set "hover_label=%hover_group%"
set "grab_label=(none)"
if defined grabbed_group set "grab_label=%grabbed_group%"
<nul set /p="%ESC%[2;3H%ESC%[43;30m Script Layout Editor %ESC%[0m"
<nul set /p="%ESC%[4;3H%ESC%[0K%ESC%[96mFile:%ESC%[0m %TARGET_FILE%"
<nul set /p="%ESC%[5;3H%ESC%[0K%ESC%[93mCursor:%ESC%[0m Y=%cursor_y% X=%cursor_x%   %ESC%[93mHover:%ESC%[0m %hover_label%   %ESC%[93mGrab:%ESC%[0m %grab_label%"
<nul set /p="%ESC%[6;3H%ESC%[0K%ESC%[90mWASD=cursor/move  Shift+W/S=5step  Shift+A/D=10step  G=grab  U/Z=undo/redo  E=text  I=id  R=reload  P=play  J=jump  L=grid  B=bg  M/N=scene  Q=picker  X=exit%ESC%[0m"
<nul set /p="%ESC%[7;3H%ESC%[0K%ESC%[90m%status_msg%   Undo=%undo_count% Redo=%redo_count% Grid=%grid_on% Scene=%scene_index%/%scene_count%%ESC%[0m"
exit /b 0

:DrawGrid
for /l %%y in (1,4,67) do (
    <nul set /p="%ESC%[%%y;1H%ESC%[90m····················································································································································································································%ESC%[0m"
)
for /l %%x in (1,8,240) do (
    for /l %%y in (1,2,67) do (
        <nul set /p="%ESC%[%%y;%%xH%ESC%[90m·%ESC%[0m"
    )
)
<nul set /p="%ESC%[34;120H%ESC%[94m+%ESC%[0m"
exit /b 0

:DrawGridFast
for /l %%y in (1,4,67) do (
    <nul set /p="%ESC%[%%y;1H%ESC%[90m%GRID_HLINE%%ESC%[0m"
)
for /l %%x in (1,8,240) do (
    for /l %%y in (1,2,67) do (
        <nul set /p="%ESC%[%%y;%%xH%ESC%[90m.%ESC%[0m"
    )
)
<nul set /p="%ESC%[34;120H%ESC%[94m+%ESC%[0m"
exit /b 0

:DrawCursor
set "cursor_color=%ESC%[91m"
if defined hover_group set "cursor_color=%ESC%[92m"
if defined grabbed_group set "cursor_color=%ESC%[103;30m"
<nul set /p="%ESC%[%cursor_y%;%cursor_x%H%cursor_color%+%ESC%[0m"
exit /b 0

:RedrawCursorOnly
call :ErasePreviousCursor
call :UpdateHover
if defined prev_hover_group call :RenderGroup "%prev_hover_group%"
if defined hover_group if /i not "%hover_group%"=="%prev_hover_group%" call :RenderGroup "%hover_group%"
call :DrawStatus
call :DrawCursor
set /a prev_cursor_y=%cursor_y%
set /a prev_cursor_x=%cursor_x%
set "prev_hover_group=%hover_group%"
exit /b 0

:ErasePreviousCursor
if %prev_cursor_x% LEQ 0 exit /b 0
call :BlankSpan %prev_cursor_y% %prev_cursor_x% 1
exit /b 0

:RenderGroup
set "target_group=%~1"
if not defined target_group exit /b 0
for /l %%i in (1,1,%line_count%) do (
    if /i "!line_id_%%i!"=="%target_group%" (
        set "raw=!line_raw_%%i!"
        if defined raw if not "!raw!"=="{clear}" call :RenderCachedLine %%i
    )
)
exit /b 0

:RenderCachedLine
set "idx=%~1"
if not defined line_y_%idx% exit /b 0
call set "speaker=%%line_cache_speaker_%idx%%%"
call set "markup=%%line_cache_markup_%idx%%%"
if not defined markup exit /b 0
<nul set /p="%ESC%[!line_y_%idx%!;!line_x_%idx%!H!speaker!!markup!"
exit /b 0

:FastRenderLine
setlocal EnableDelayedExpansion
set "raw=%~1"
set "line=!raw!"
if "!line!"=="{clear}" exit /b 0
if defined line if "!line:~0,7!"=="{delay:" exit /b 0

echo !line! | findstr /b "{id:" >nul
if !errorlevel! == 0 set "line=!line:*}=!"

set "y="
set "x="
echo !line! | findstr /b "{pos:" >nul
if !errorlevel! == 0 (
    for /f "tokens=2,3 delims=:{}" %%a in ("!line!") do (
        set "y=%%a"
        set "x=%%b"
    )
    set "line=!line:*}=!"
)
if not defined y exit /b 0
if not defined x exit /b 0

set "speaker="
echo !line! | findstr /b "{player_name_tag}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[%player_name%]%ESC%[0m "
    set "line=!line:*{player_name_tag}=!"
)
echo !line! | findstr /b "{player}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[YOU]%ESC%[0m "
    set "line=!line:*{player}=!"
)
echo !line! | findstr /b "{heroine}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[91m[HER]%ESC%[0m "
    set "line=!line:*{heroine}=!"
)
echo !line! | findstr /b "{unknown}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[91m[???]%ESC%[0m "
    set "line=!line:*{unknown}=!"
)
echo !line! | findstr /b "{both}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[BO%ESC%[91mTH]%ESC%[0m "
    set "line=!line:*{both}=!"
)

set "line=!line:{/type}=!"
set "line=!line:{/shake}=!"
echo !line! | findstr /c:"{type" >nul
if !errorlevel! == 0 set "line=!line:*}=!"
echo !line! | findstr /c:"{shake" >nul
if !errorlevel! == 0 set "line=!line:*}=!"

call "%src_display_mod_dir%\RenderMarkup_v2.3.bat" "!line!" parsed
<nul set /p="%ESC%[!y!;!x!H!speaker!!parsed!"
endlocal
exit /b 0

:BuildRenderCache
set "idx=%~1"
call set "raw=%%line_raw_%idx%%%"
set "line_cache_speaker_%idx%="
set "line_cache_markup_%idx%="
if not defined raw exit /b 0

set "line=%raw%"
if "!line!"=="{clear}" exit /b 0
if "!line:~0,7!"=="{delay:" exit /b 0

echo !line! | findstr /b "{id:" >nul
if !errorlevel! == 0 set "line=!line:*}=!"
echo !line! | findstr /b "{pos:" >nul
if !errorlevel! == 0 set "line=!line:*}=!"

set "speaker="
echo !line! | findstr /b "{player_name_tag}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[%player_name%]%ESC%[0m "
    set "line=!line:*{player_name_tag}=!"
)
echo !line! | findstr /b "{player}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[YOU]%ESC%[0m "
    set "line=!line:*{player}=!"
)
echo !line! | findstr /b "{heroine}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[91m[HER]%ESC%[0m "
    set "line=!line:*{heroine}=!"
)
echo !line! | findstr /b "{unknown}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[91m[???]%ESC%[0m "
    set "line=!line:*{unknown}=!"
)
echo !line! | findstr /b "{both}" >nul
if !errorlevel! == 0 (
    set "speaker=%ESC%[36m[BO%ESC%[91mTH]%ESC%[0m "
    set "line=!line:*{both}=!"
)

set "line=!line:{/type}=!"
set "line=!line:{/shake}=!"
echo !line! | findstr /c:"{type" >nul
if !errorlevel! == 0 set "line=!line:*}=!"
echo !line! | findstr /c:"{shake" >nul
if !errorlevel! == 0 set "line=!line:*}=!"

call "%src_display_mod_dir%\RenderMarkup_v2.3.bat" "!line!" parsed
set "line_cache_speaker_%idx%=%speaker%"
set "line_cache_markup_%idx%=%parsed%"
exit /b 0

:ClearGroupArea
set "target_group=%~1"
if not defined target_group exit /b 0
for /l %%i in (1,1,%line_count%) do (
    if /i "!line_id_%%i!"=="%target_group%" (
        call :BlankRow !line_y_%%i!
    )
)
exit /b 0

:BlankRow
setlocal
set "row_y=%~1"
<nul set /p="%ESC%[%row_y%;1H%ESC%[2K"
endlocal
exit /b 0

:BlankSpan
setlocal EnableDelayedExpansion
set /a span_y=%~1
set /a span_x=%~2
set /a span_w=%~3
if !span_w! LSS 1 set "span_w=1"
set "spaces="
for /l %%s in (1,1,!span_w!) do set "spaces=!spaces! "
<nul set /p="%ESC%[!span_y!;!span_x!H!spaces!"
endlocal
exit /b 0

:UpdateHover
set "hover_group="
for /l %%i in (1,1,%line_count%) do (
    if defined line_y_%%i (
        set /a test_y=!line_y_%%i!
        set /a test_x1=!line_hit_l_%%i!
        set /a test_x2=!line_hit_r_%%i!
        if !cursor_y! GEQ !test_y! if !cursor_y! LEQ !test_y! if !cursor_x! GEQ !test_x1! if !cursor_x! LEQ !test_x2! (
            set "hover_group=!line_id_%%i!"
            goto :hover_done
        )
    )
)
:hover_done
exit /b 0

:HandleMove
set /a dy=%~1
set /a dx=%~2
set /a step=%~3
if defined grabbed_group (
    call :MoveGrabbed !dy! !dx!
) else (
    set /a cursor_y+=dy
    set /a cursor_x+=dx
    if %cursor_y% LSS 1 set /a cursor_y=1
    if %cursor_x% LSS 1 set /a cursor_x=1
    set "status_msg=Cursor moved."
    call :RedrawCursorOnly
)
exit /b 0

:MoveGrabbed
call :PushUndoSnapshot
set /a dy=%~1
set /a dx=%~2
set "moved_group=%grabbed_group%"
call :ClearGroupArea "%moved_group%"
for /l %%i in (1,1,%line_count%) do (
    if /i "!line_id_%%i!"=="%moved_group%" (
        set /a ny=!line_y_%%i! + dy
        set /a nx=!line_x_%%i! + dx
        if !ny! LSS 1 set "ny=1"
        if !nx! LSS 1 set "nx=1"
        call set "updated=%%line_raw_%%i:{pos:!line_y_%%i!:!line_x_%%i!}={pos:!ny!:!nx!}%%"
        set "line_raw_%%i=!updated!"
        set "line_y_%%i=!ny!"
        set "line_x_%%i=!nx!"
        set /a line_hit_l_%%i=!nx! - 1
        set /a line_hit_r_%%i=!nx! + !line_w_%%i!
    )
)
set /a cursor_y+=dy
set /a cursor_x+=dx
if %cursor_y% LSS 1 set /a cursor_y=1
if %cursor_x% LSS 1 set /a cursor_x=1
call :WriteBack
call :RenderGroup "%moved_group%"
set "status_msg=Moved %moved_group% and hot-swapped file."
call :RedrawCursorOnly
exit /b 0

:ToggleGrabAndRender
call :UpdateHover
if defined grabbed_group (
    set "status_msg=Released %grabbed_group%."
    set "grabbed_group="
    call :RedrawCursorOnly
    exit /b 0
)
if defined hover_group (
    set "grabbed_group=%hover_group%"
    set "status_msg=Grabbed %hover_group%."
) else (
    set "status_msg=No text block under cursor."
)
call :RedrawCursorOnly
exit /b 0

:EditCurrentTextAndRender
set "target_id=%grabbed_group%"
if not defined target_id set "target_id=%hover_group%"
if not defined target_id (
    set "status_msg=No target block selected for edit."
    call :FullRender
    exit /b 0
)
for /l %%i in (1,1,%group_count%) do if /i "!group_id_%%i!"=="%target_id%" set "target_line=!group_first_line_%%i!"
set "current=!line_raw_%target_line%!"
cls
echo Editing first line of ID "%target_id%"
echo.
echo Current:
echo !current!
echo.
set "edited="
set /p "edited=New raw line (blank to cancel): "
if not defined edited (
    set "status_msg=Edit cancelled."
    call :FullRender
    exit /b 0
)
call :PushUndoSnapshot
set "line_raw_%target_line%=%edited%"
call :RefreshLineMeta %target_line%
call :WriteBack
set "status_msg=Edited first line of %target_id%."
call :FullRender
exit /b 0

:EditCurrentIdAndRender
set "target_id=%grabbed_group%"
if not defined target_id set "target_id=%hover_group%"
if not defined target_id (
    set "status_msg=No target block selected for ID edit."
    call :FullRender
    exit /b 0
)
cls
echo Current ID: %target_id%
set /p "new_id=New ID (blank to cancel): "
if not defined new_id (
    set "status_msg=ID edit cancelled."
    call :FullRender
    exit /b 0
)
call :PushUndoSnapshot
for /l %%i in (1,1,%line_count%) do (
    if /i "!line_id_%%i!"=="%target_id%" (
        set "raw=!line_raw_%%i!"
        echo !raw! | findstr /c:"{id:" >nul
        if !errorlevel! == 0 (
            call set "raw=%%raw:{id:%target_id%}={id:%new_id%}%%"
        ) else (
            set "raw={id:%new_id%}!raw!"
        )
        set "line_raw_%%i=!raw!"
        set "line_id_%%i=%new_id%"
    )
)
if defined grabbed_group set "grabbed_group=%new_id%"
call :RebuildGroups
call :WriteBack
set "status_msg=Renamed ID %target_id% -> %new_id%."
call :FullRender
exit /b 0

:JumpToIdAndRender
cls
echo Available IDs:
for /l %%i in (1,1,%group_count%) do echo   !group_id_%%i!
echo.
set /p "jump_id=Jump to ID: "
if not defined jump_id (
    set "status_msg=Jump cancelled."
    call :FullRender
    exit /b 0
)
for /l %%i in (1,1,%group_count%) do (
    if /i "!group_id_%%i!"=="%jump_id%" (
        set "jump_line=!group_first_line_%%i!"
        set /a cursor_y=!line_y_%jump_line%!
        set /a cursor_x=!line_x_%jump_line%!
        set "status_msg=Jumped to %jump_id%."
        call :FullRender
        exit /b 0
    )
)
set "status_msg=ID not found: %jump_id%."
call :FullRender
exit /b 0

:ReturnToPicker
call :PickTargetFile
if not defined TARGET_FILE goto :done
call :BuildSceneSet
set "BACKUP_FILE=%TARGET_FILE%.layoutbak"
if not exist "%BACKUP_FILE%" copy /y "%TARGET_FILE%" "%BACKUP_FILE%" >nul
call :ResetUndoHistory
call :LoadFile
call :ResetCursorToFirstPos
set "grabbed_group="
set "hover_group="
set "prev_hover_group="
set /a prev_cursor_y=0
set /a prev_cursor_x=0
set "status_msg=Opened file from picker."
call :FullRender
exit /b 0

:OpenAdjacentScene
if %scene_count% LEQ 1 (
    set "status_msg=No additional scene files in this folder."
    call :DrawStatus
    exit /b 0
)
call :SyncSceneIndex
set /a next_scene=scene_index + %~1
if %next_scene% LSS 1 set /a next_scene=scene_count
if %next_scene% GTR %scene_count% set /a next_scene=1
call set "TARGET_FILE=%%scene_file_%next_scene%%%"
set /a scene_index=%next_scene%
call :ResetUndoHistory
call :LoadFile
call :ResetCursorToFirstPos
set "grabbed_group="
set "hover_group="
set "prev_hover_group="
set /a prev_cursor_y=0
set /a prev_cursor_x=0
set "status_msg=Opened scene %scene_index%/%scene_count%."
call :FullRender
exit /b 0

:PickBackgroundAndRender
set /a bg_count=0
for /f "delims=" %%F in ('dir /b /s "%assets_images_dir%\*.png" "%assets_images_dir%\*.jpg" "%assets_images_dir%\*.jpeg" "%assets_images_dir%\*.bmp" "%assets_images_dir%\*.gif" "%assets_images_dir%\*.webp" 2^>nul') do (
    set /a bg_count+=1
    set "bg_file_!bg_count!=%%~fF"
)
if !bg_count! LEQ 0 (
    set "status_msg=No background images found."
    call :DrawStatus
    exit /b 0
)
set /a bg_index=1
for /l %%i in (1,1,!bg_count!) do (
    call set "candidate=%%bg_file_%%i%%"
    if /i "!candidate!"=="%BG_IMAGE%" set /a bg_index=%%i
)
:bg_pick_loop
cls
echo %ESC%[43;30m Script Layout Editor - Background Picker %ESC%[0m
echo.
echo %ESC%[90mW/S = move   E = apply   Q = cancel%ESC%[0m
echo.
set /a bg_start=bg_index-8
if !bg_start! LSS 1 set /a bg_start=1
set /a bg_end=bg_start+15
if !bg_end! GTR !bg_count! set /a bg_end=bg_count
for /l %%i in (!bg_start!,1,!bg_end!) do (
    set "mark=  "
    if %%i==!bg_index! set "mark=> "
    call set "entry=%%bg_file_%%i%%"
    echo(!mark!%%i. !entry!
)
choice /c WSEQ /n >nul
set "bg_key=!errorlevel!"
if !bg_key!==1 if !bg_index! GTR 1 set /a bg_index-=1
if !bg_key!==2 if !bg_index! LSS !bg_count! set /a bg_index+=1
if !bg_key!==3 (
    call set "BG_IMAGE=%%bg_file_!bg_index!%%"
    call :ApplyBackground
    set "status_msg=Background changed."
    call :FullRender
    exit /b 0
)
if !bg_key!==4 (
    set "status_msg=Background change cancelled."
    call :FullRender
    exit /b 0
)
goto :bg_pick_loop

:ResetCursorToFirstPos
set "first_pos_line="
for /l %%i in (1,1,%line_count%) do (
    if not defined first_pos_line if defined line_y_%%i set "first_pos_line=%%i"
)
if defined first_pos_line (
    call set "tmp_cursor_y=%%line_y_%first_pos_line%%%"
    call set "tmp_cursor_x=%%line_x_%first_pos_line%%%"
    set /a cursor_y=%tmp_cursor_y%
    set /a cursor_x=%tmp_cursor_x%
)
if %cursor_y% LSS 1 set /a cursor_y=1
if %cursor_x% LSS 1 set /a cursor_x=1
exit /b 0

:ReloadFileAndRender
call :LoadFile
set "grabbed_group="
set "status_msg=Reloaded file from disk."
call :FullRender
exit /b 0

:ToggleGridAndRender
if "%grid_on%"=="1" (
    set "grid_on=0"
    set "status_msg=Grid hidden."
) else (
    set "grid_on=1"
    set "status_msg=Grid shown."
)
call :FullRender
exit /b 0

:PlayPreviewAndReturn
cls
set "RENDERCONTROL_FAST_PREVIEW="
for /l %%i in (1,1,%line_count%) do (
    set "raw=!line_raw_%%i!"
    if defined raw call "%src_display_mod_dir%\RenderControl_v2.3.bat" "!raw!"
)
<nul set /p="%ESC%[66;3H%ESC%[90mPress any key to return to editor...%ESC%[0m"
"%CMDWIZ%" getch >nul 2>&1
set "status_msg=Preview finished."
call :FullRender
exit /b 0

:RefreshLineMeta
set "idx=%~1"
set "scan=!line_raw_%idx%!"
set "line_id_%idx%="
set "line_y_%idx%="
set "line_x_%idx%="
set "line_w_%idx%="
set "line_hit_l_%idx%="
set "line_hit_r_%idx%="
set "line_cache_speaker_%idx%="
set "line_cache_markup_%idx%="
echo !scan! | findstr /c:"{id:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1 delims=}" %%a in ("!scan:*{id:=!") do set "line_id_%idx%=%%a"
)
echo !scan! | findstr /c:"{pos:" >nul
if !errorlevel! == 0 (
    for /f "tokens=1,2 delims=:}" %%a in ("!scan:*{pos:=!") do (
        set "line_y_%idx%=%%a"
        set "line_x_%idx%=%%b"
    )
    call :MeasureVisibleWidth "!scan!" line_w_tmp
    call :MeasureSpeakerWidth "!scan!" line_sw_tmp
    set /a total_w=!line_w_tmp! + !line_sw_tmp!
    if !total_w! LSS 1 set "total_w=1"
    set "line_w_%idx%=!total_w!"
    set /a line_hit_l_%idx%=!line_x_%idx%! - 1
    set /a line_hit_r_%idx%=!line_x_%idx%! + !total_w!
)
if not defined line_id_%idx% if defined line_y_%idx% set "line_id_%idx%=L%idx%"
if defined line_y_%idx% call :BuildRenderCache %idx%
call :RebuildGroups
exit /b 0

:RebuildGroups
for /l %%i in (1,1,999) do (
    set "group_id_%%i="
    set "group_first_line_%%i="
)
set /a group_count=0
for /l %%i in (1,1,%line_count%) do (
    if defined line_y_%%i call :RegisterGroup "!line_id_%%i!" %%i
)
exit /b 0

:WriteBack
set "tmp_file=%TEMP%\ad_script_layout_editor_%RANDOM%.tmp"
type nul > "%tmp_file%"
for /l %%i in (1,1,%line_count%) do >> "%tmp_file%" echo(!line_raw_%%i!
move /y "%tmp_file%" "%TARGET_FILE%" >nul
exit /b 0

:PushUndoSnapshot
set /a undo_count+=1
copy /y "%TARGET_FILE%" "%UNDO_DIR%\undo_!undo_count!.txt" >nul
for /l %%i in (1,1,!redo_count!) do del "%UNDO_DIR%\redo_%%i.txt" >nul 2>&1
set /a redo_count=0
exit /b 0

:UndoAndRender
if %undo_count% LEQ 0 (
    set "status_msg=Nothing to undo."
    call :FullRender
    exit /b 0
)
set /a redo_count+=1
copy /y "%TARGET_FILE%" "%UNDO_DIR%\redo_!redo_count!.txt" >nul
copy /y "%UNDO_DIR%\undo_%undo_count%.txt" "%TARGET_FILE%" >nul
del "%UNDO_DIR%\undo_%undo_count%.txt" >nul 2>&1
set /a undo_count-=1
call :LoadFile
set "grabbed_group="
set "status_msg=Undo applied."
call :FullRender
exit /b 0

:RedoAndRender
if %redo_count% LEQ 0 (
    set "status_msg=Nothing to redo."
    call :FullRender
    exit /b 0
)
set /a undo_count+=1
copy /y "%TARGET_FILE%" "%UNDO_DIR%\undo_!undo_count!.txt" >nul
copy /y "%UNDO_DIR%\redo_%redo_count%.txt" "%TARGET_FILE%" >nul
del "%UNDO_DIR%\redo_%redo_count%.txt" >nul 2>&1
set /a redo_count-=1
call :LoadFile
set "grabbed_group="
set "status_msg=Redo applied."
call :FullRender
exit /b 0
