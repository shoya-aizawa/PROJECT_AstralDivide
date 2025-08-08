::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

@echo off
@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")
@prompt $G
@chcp 65001 >nul
@mode 90,35

if not defined GAME_LAUNCHER (
   echo %esc%[31m[E1200]%esc%[0m Do not run this directly. Use %esc%[92m"AstralDivide.bat"%esc%[0m
   pause >nul
   exit /b 1200
   rem TODO : The error code is tentative
)& rem !Startup Protection!

set "PROJECT_ROOT=%~1"
if not exist "%PROJECT_ROOT%\Src\Main\Main.bat" (
   echo %esc%[31m[E1201]%esc%[0m Invalid PROJECT_ROOT: "%PROJECT_ROOT%"
   pause >nul
   exit /b 1201
   rem TODO : The error code is tentative
)& rem !Failed to get root folder!



set "CFG_DIR=%PROJECT_ROOT%\Config"
set "CFG_FILE=%CFG_DIR%\profile.env"

:: ====================================================================
:: Bootstrap: load or create profile
:: ====================================================================
if exist "%CFG_FILE%" goto :HaveProfile
goto :FirstRun

:HaveProfile
echo %esc%[92m[OK]%esc%[0m Welcome back! profile.env exists
call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || goto :FailFirstRun

:: --- Self-Repair defaults ---
if not defined PROFILE_SCHEMA set "PROFILE_SCHEMA=1"
if not defined CODEPAGE set "CODEPAGE=65001"
if not defined LANGUAGE set "LANGUAGE=ja-JP"
if /i not "%SAVE_MODE%"=="localappdata" if /i not "%SAVE_MODE%"=="portable" if /i not "%SAVE_MODE%"=="custom" set "SAVE_MODE=portable"
if not defined SAVE_DIR (
   if /i "%SAVE_MODE%"=="localappdata" (
      set "SAVE_DIR=%LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves"
   ) else if /i "%SAVE_MODE%"=="portable" (
      set "SAVE_DIR=%PROJECT_ROOT%\Saves"
   ) else (
      call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat" || goto :FailFirstRun
      call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || goto :FailFirstRun
   )
)

goto :ProfileReady

:FirstRun
echo %esc%[92m[WELCOME]%esc%[0m This is your first boot.
timeout /t 2 >nul
:: === First time: Language → Storage wizard (both persist to profile.env) ===
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat"         || goto :FailFirstRun
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat"    || goto :FailFirstRun

:: --- Re-sync from disk (the single source of truth) ---
if not exist "%CFG_DIR%" md "%CFG_DIR%" 2>nul
call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"  || goto :FailFirstRun
:ProfileReady
:: --- Ensure SAVE_DIR exists; create if missing (errorlevelを見ない) ---
if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
if not exist "%SAVE_DIR%" (
   echo %esc%[31m[WARN]%esc%[0m SAVE_DIR="%SAVE_DIR%" を作成できませんでした。再設定します。
   pause >nul
   call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat" || goto :FailFirstRun
   call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%" || goto :FailFirstRun
   if not exist "%SAVE_DIR%" md "%SAVE_DIR%" 2>nul
   if not exist "%SAVE_DIR%" goto :FailFirstRun
)

:: --- Write-back normalization（引用付きで安全に）---
>"%CFG_FILE%" (
   echo # Astral Divide profile
   echo set "PROFILE_SCHEMA=%PROFILE_SCHEMA%"
   echo set "CODEPAGE=%CODEPAGE%"
   echo set "LANGUAGE=%LANGUAGE%"
   echo set "SAVE_MODE=%SAVE_MODE%"
   echo set "SAVE_DIR=%SAVE_DIR%"
)


timeout /t 10

:Setting_Path
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat"

:Check_Environment
setlocal
call "%src_env_dir%\ScreenEnvironmentDetection.bat"
endlocal

:Start_Program
:: Start Main.bat with the specified encoding.
:: For now, I'll set the encoding to 65001. (for Japanese)
start "RPGGAME2024" /max cmd /c "%src_main_dir%\Main.bat" 65001
set launch_time=%time%


:: ______________________________________________
:: _______________WATCH DOG SYSTEM_______________
:: ______________________________________________

:: === watchdog monitor loop ===
:Watchdog
timeout /t 1 >nul

:: Check if Main.bat is running
tasklist /fi "windowtitle eq RPGGAME2024" | find /i "cmd.exe" >nul
if %errorlevel%==0 (
   cls
   echo [%launch_time%]
   echo [WD] Game launched compleated!
   echo [%time%]
   echo [WD] Main.bat is running...
   goto :Watchdog
)

:: If Main.bat is not running, exit the loop
echo [%time%]
echo [WD] Main.bat has exited!

set /p command=""
%command%

if "%command%"=="re" (cls & goto :Reconfigure)

exit /b

:FailFirstRun
echo %esc%[31m[E1300]%esc%[0m 初期設定に失敗しました。保存先や権限をご確認ください。
pause >nul
exit /b 1300

:Reconfigure
:: Force re-run of both wizards, then reload profile and relaunch
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupLanguage.bat" || goto :FailFirstRun
call "%PROJECT_ROOT%\Src\Systems\Environment\SetupStorageWizard.bat" || goto :FailFirstRun
call "%PROJECT_ROOT%\Src\Systems\Environment\LoadEnv.bat" "%CFG_FILE%"
goto :Setting_Path

rem ****************************共有：本プロジェクトの命名規則について****************************

rem *コマンド (Command) : 小文字で統一(command)
rem     ・コマンドは頻繁に使用されるため、小文字で統一することで視覚的ノイズを減らし、読みやすくなる。
rem     ・Windowsコマンドプロンプトでは大文字小文字を区別しないため、小文字統一で問題なく動作する。

rem *変数名(Variable name) ： スネークケース(snake_case)
rem     ・長い名前でも読みやすく、バッチの特殊文字（%や!）と区別がつきやすいため、可読性が向上する。
rem     ・例外として、デバッグ変数は大文字で統一することで、他の変数と区別しやすくなる。

rem *ラベル名(Label name) : パスカルケース＆プレフィックス/サフィックス(Label_PascalCase)
rem     ・関数や目的別のラベル名を明確に示せるため、コード全体の整理がしやすい。
rem     ・ジャンプ先をすぐに見つけられるため、コードのデバッグや変更がスムーズになる。
rem     ・視覚的に他のコード（コマンドや変数名）と区別がつきやすい。

rem *ファイル名(File name) : パスカルケース(PascalCase)
rem     ・ファイル名の命名に一貫性を持たせることで、プロジェクト全体の整理がしやすい。
rem     ・ファイル名がOS環境（例: Windows）で大文字小文字の区別がつかなくても、構造的に分かりやすい。

rem *フォルダ名(Folder name) : パスカルケース(PascalCase)
rem     ・視覚的に統一感を持たせることで、管理が容易になる。
rem     ・ファイル名と統一し、プロジェクト全体の一貫性を保つため。
rem     ・フォルダ名が階層構造を整理する役割を果たし、複数のファイルや機能を含む場合に利便性が高まる。


rem *************************************共有：戻り値一覧表*************************************

rem **バッチファイルの標準的な終了コード**
rem errorlevel|mean
rem         0 | 正常終了
rem         1 | 一般的なエラー
rem         2 | 指定されたファイルが見つからない
rem         3 | パスが見つからない
rem         4 | システムが要求された操作を実行できない
rem         5 | アクセスが拒否された
rem         6 | ハンドルが無効
rem        10 | 環境が正しく設定されていない
rem        87 | 無効なパラメータ
rem       123 | 無効な名前が指定された
rem      9009 | コマンドが見つからない(command not found)

rem **本プロジェクトの標準的な終了コード**(231128現段階では不確定)(not determined)
rem errorlevel| mean
rem         0 | 正常終了
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D
rem         N | D

rem *******************************************************************************************