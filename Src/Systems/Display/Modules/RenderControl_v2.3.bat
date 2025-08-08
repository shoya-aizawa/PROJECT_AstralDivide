@echo off
chcp 65001 >nul

:: RenderControl_v2.3.bat

:: 引数1: タグ付きテキスト行

:: 戻り値なし。順次タグ処理を再帰的に実行（goto不使用）

for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"

setlocal enabledelayedexpansion
set "line=%~1"

:: 再帰的なタグ処理（順次スキャンして除去＆再呼び出し）













:: {pos:y:x}
echo !line! | findstr /b "{pos:" >nul
if !errorlevel! == 0 (
    for /f "tokens=2,3 delims=:{}" %%a in ("!line!") do (
        set "Y=%%a"
        set "X=%%b"
    )
    set "CURRENT_CURSOR_Y=!Y!"
    set "CURRENT_CURSOR_X=!X!"
    %tools_dir%\cmdwiz.exe print "%ESC%[!Y!;!X!H"
    set "line=!line:*}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)






:: {delay:n} Supports both single and mixed use
if "!line:~0,7!"=="{delay:" (
    for /f "tokens=2 delims=:{}" %%a in ("!line!") do (
        %tools_dir%\cmdwiz.exe delay %%a
        set "line=!line:*}=!"
    )
    if defined line (
        call "%~dp0RenderControl_v2.3.bat" "!line!"
    )
    exit /b 0
)


:: {clear} only
if "!line!"=="{clear}" (
    cls
    exit /b 0
)

:: {clear} + more
echo !line! | findstr /b "{clear}" >nul
if !errorlevel! == 0 (
    cls
    set "line=!line:*{clear}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

:: {player}
echo !line! | findstr /b "{player}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[36m[YOU]%ESC%[0m"
    set "line=!line:*{player}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

:: {heroine}
echo !line! | findstr /b "{heroine}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[91m[HER]%ESC%[0m"
    set "line=!line:*{heroine}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)

:: {both}
echo !line! | findstr /b "{both}" >nul
if !errorlevel! == 0 (
    set "SPEAKER=%ESC%[36m[BO%ESC%[91mTH]%ESC%[0m"
    set "line=!line:*{both}=!"
    call "%~dp0RenderControl_v2.3.bat" "!line!"
    exit /b 0
)



:: {type[:speed]} ～ {/type}
echo !line! | findstr /c:"{type" >nul
if !errorlevel! == 0 (
    set "type_speed=100" & rem default speed

    rem === Branch only if the tag contains ":" ===
    echo !line! | findstr /c:"{type:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:}" %%a in ("!line!") do (
            set "type_spec=%%a"

            rem --Preset compatible ---
            if /i "!type_spec!"=="slow" set "type_speed=250"
            if /i "!type_spec!"=="normal" set "type_speed=100"
            if /i "!type_spec!"=="fast" set "type_speed=30"

            rem ---If it's a number, overwrite ---
            echo !type_spec! | findstr "^[0-9][0-9]*$" >nul
            if !errorlevel! == 0 set "type_speed=!type_spec!"
        )
    )

    rem --- Text part extraction (common processing) ---
    set "inner=!line:*}=!"
    set "inner=!inner:{/type}=!"
    call "%~dp0RenderMarkup_v2.3.bat" "!inner!" parsed
    if defined SPEAKER <nul set /p="!SPEAKER! "
    call "%~dp0TypeWriter_v2.3.bat" "!parsed!" !type_speed!
    exit /b 0
)

:: {shake[:n]} ～ {/shake}
echo !line! | findstr /c:"{shake" >nul
if !errorlevel! == 0 (
    set "shake_count=5"
    echo !line! | findstr /c:"{shake:" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:}" %%a in ("!line!") do (
            set "shake_count=%%a"
        )
    )
    rem Text part extraction
    set "inner=!line:*}=!"
    set "inner=!inner:{/shake}=!"
    call "%~dp0RenderMarkup_v2.3.bat" "!inner!" parsed

    rem ==== SPEAKERが定義されていれば表示 ====
    if defined SPEAKER <nul set /p="!SPEAKER! "

    set "cur_x=!CURRENT_CURSOR_X!"
    set "cur_y=!CURRENT_CURSOR_Y!"
    if not defined cur_x set "cur_x=10"
    if not defined cur_y set "cur_y=10"

    set "last_sx="
    set "last_sy="

    for /l %%i in (1,1,!shake_count!) do (
        rem === Clear previous ===
        if defined last_sx if defined last_sy (
            <nul set /p="%ESC%[!last_sy!;!last_sx!H%ESC%[0K"
        )

        set /a offset_x=!random! %% 3 - 1
        set /a offset_y=!random! %% 3 - 1
        set /a sx=!cur_x! + !offset_x!
        set /a sy=!cur_y! + !offset_y!

        <nul set /p="%ESC%[!sy!;!sx!H!parsed!"
        %tools_dir%\cmdwiz.exe delay 90

        set "last_sx=!sx!"
        set "last_sy=!sy!"
    )

    rem === 残像を消去して確定表示 ===
    if defined last_sx if defined last_sy (
        <nul set /p="%ESC%[!last_sy!;!last_sx!H%ESC%[0K"
    )
    <nul set /p="%ESC%[!cur_y!;!cur_x!H%ESC%[0K!parsed!"
    exit /b 0
)












:: === 通常台詞 ===

call "%~dp0RenderMarkup_v2.3.bat" "!line!" parsed
if defined SPEAKER <nul set /p=!SPEAKER!

:: non tags
<nul set /p=!parsed!
endlocal
exit /b 0