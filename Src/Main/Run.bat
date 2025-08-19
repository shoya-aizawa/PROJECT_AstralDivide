::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

:: rem !) this file will restarting by [@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof] command. (!
:: rem !) so, can't recording return value by use exit /b options to "AstralDivide.bat". if want to use, a separate log file must be generated.   (!

@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof
@echo off
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")
@prompt $G
@chcp 65001 >nul
@mode 90,35

rem============================================= RCC/RCU bootstrap =============================================
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat" || (
    rem 定数の読み込みに失敗 (レガシーコードで最小フォールバック) : Systems/Other/001
    set "RC=90690001" & goto :FailRun
)
rem ★ ここで最初のトレースが Config\Logs に出るように強制（SettingPath 前でも集約先使用）
if not defined CONFIG_LOGS_DIR set "CONFIG_LOGS_DIR=%PROJECT_ROOT%\Config\Logs"

rem OKコードを定義 (FLOW/SYS/OTHER/000)
for /f %%E in ('call "%RCU%" -build %rc_s_flow% %rc_d_sys% %rc_r_other% 000') do set "RC_OK=%%E"

rem ログ設定 (任意) : このラン実行だけセッションログ化
set "LOG_MODE=session" & set "LOG_PREFIX=run"
call "%RCU%" -trace INFO Run "start profile=? args=%*"

rem================================================= Main Flow =================================================

rem 0) Mode Interpretation (Default=RUN) (*RUN*|DEBUG|INTERCEPT)
set "BUILD_PROFILE=release" & set "INTERCEPT_MODE=0"
if /i "%~1"=="-mode" if /i "%~2"=="debug"     set "BUILD_PROFILE=dev"
if /i "%~1"=="-mode" if /i "%~2"=="intercept" set "BUILD_PROFILE=dev" & set "INTERCEPT_MODE=1"
call "%RCU%" -trace INFO Run "mode profile=%BUILD_PROFILE% intercept=%INTERCEPT_MODE%"

rem 1) LaunchGuard
call "%PROJECT_ROOT%\Src\Systems\Launcher\LaunchGuard.bat" "%PROJECT_ROOT%"
call :_gate_ok "LaunchGuard" || goto :FailFirstRun
call "%RCU%" -trace INFO Run "vars: src_env_dir=%src_env_dir%"

rem 1.5) Bootstrap
call "%PROJECT_ROOT%\Src\Systems\Bootstrap\Bootstrap_Init.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCU%" -trace INFO Run "bootstrap ok"

rem 2) Path 解決は “最上位スコープ” で実施
call "%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCU%" -trace INFO Run "paths ready root=%root_dir%"


rem  2.5) 旧 -} 新 生成物のマイグレーション（集約先へ寄せる）
rem     -Up until now, config_logs_dir /runtime_ipc_dir has been defined by SettingPath
if exist "%PROJECT_ROOT%\Logs" (
  if not exist "%config_logs_dir%" md "%config_logs_dir%" >nul 2>&1
  move /y "%PROJECT_ROOT%\Logs\*" "%config_logs_dir%" >nul 2>&1
  dir /b "%PROJECT_ROOT%\Logs" | findstr /r /c:"^." >nul || rd "%PROJECT_ROOT%\Logs"
  call "%RCU%" -trace INFO Run "migrated Logs -> %config_logs_dir%"
)
if exist "%PROJECT_ROOT%\Runtime\ipc" (
  if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
  move /y "%PROJECT_ROOT%\Runtime\ipc\*" "%runtime_ipc_dir%" >nul 2>&1
  call "%RCU%" -trace INFO Run "migrated Runtime\ipc -> %runtime_ipc_dir%"
)

rem 3) Environment_Check (PowerShell availability/screen/VT)
call "%src_env_dir%\ScreenEnvironmentDetection.bat" "%PROJECT_ROOT%"
if not "%errorlevel%"=="%RC_OK%" goto :FailFirstRun
call "%RCU%" -trace INFO Run "screen env ok"

rem 4) Signature Verification (Fail-Fast)
rem TODO call "%PROJECT_ROOT%\Src\Systems\Security\VerifySignatures.bat"

rem 5) Main 起動
start /d "%src_main_dir%" Main.bat 65001 "AstralDivide[v0.1.0]"
set launch_time=%time%
call "%RCU%" -trace INFO Run "main launched time=%launch_time%"

rem 6) Watchdog always running (mode reflected)
rem Output destination is the aggregated IPC directory determined by SettingPath.
if not exist "%runtime_ipc_dir%" md "%runtime_ipc_dir%" >nul 2>&1
( if "%INTERCEPT_MODE%"=="1" (echo INTERCEPT) else (echo NORMAL) ) > "%runtime_ipc_dir%\.mode"

rem Pass IPC_DIR to WD as an argument
call "%src_debug_dir%\Watchdog_Host.bat" "%runtime_ipc_dir%" "AstralDivide[v0.1.0]"


rem 7) 後片付け
rem TODO del /q "%runtime_ipc_dir%\*.tmp" 2>nul
rem TODO exit /b %RC%

rem=============================================================================================================

rem//============================ Developer console (optional; keep off in release) ==========================//
set /p command="" & %command%
if "%command%"=="" (goto :eof)
rem//=========================================================================================================//

rem!========================================== Error & Exit sections ==========================================!
:FailFirstRun
rem 直前のRCを人間可読表示
call "%RCU%" -pretty %errorlevel%
call "%RCU%" -trace ERR Run "first-run failed rc=%errorlevel%"
echo %esc%[31m[E1300]%esc%[0m 初期設定に失敗しました。保存先や権限をご確認ください。
pause >nul
goto :ExitRun

:FailRun
call "%RCU%" -trace ERR Run "fatal boot rc=%RC%"
goto :ExitRun

:ExitRun
call "%RCU%" -trace INFO Run "exit"
pause >nul
exit /b
rem!===========================================================================================================!

rem?================================================= Helpers =================================================?
:_gate_ok
rem Usage: call :_gate_ok StepName
set "STEP=%~1"
set "RC=%errorlevel%"
if "%RC%"=="%RC_OK%" (
    call "%RCU%" -trace INFO Run "%STEP% ok rc=%RC%"
    exit /b 0
)
rem NG: 整形表示して戻る（呼び出し側で goto :FailFirstRun）
call "%RCU%" -trace WARN Run "%STEP% fail rc=%RC%"
call "%RCU%" -pretty %RC%
exit /b 1
rem?===========================================================================================================?

rem ****************************共有：本プロジェクトの命名規則について****************************

rem *コマンド (Command) : 小文字で統一(command)
rem     ・コマンドは頻繁に使用されるため、小文字で統一することで視覚的ノイズを減らし、読みやすくなる。
rem     ・Windowsコマンドプロンプトでは大文字小文字を区別しないため、小文字統一で問題なく動作する。

rem *変数名(Variable name) ： スネークケース(snake_case)
rem     ・長い名前でも読みやすく、バッチの特殊文字（%や!）と区別がつきやすいため、可読性が向上する。
rem     ・例外として、デバッグ変数は大文字で統一することで、他の変数と区別しやすくなる。

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

rem *******************************************************************************************