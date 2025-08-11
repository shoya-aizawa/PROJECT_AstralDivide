::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

:: rem !) this file alredy restarted by [@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof] command. (!
:: rem !) so, can't recording return value by use exit /b options. if want to use, a separate log file must be generated.   (!

::
@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof
@echo off
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")
@prompt $G
@chcp 65001 >nul
@mode 90,35
::



rem TODO: 理想処理フロー
rem !!!! Flow -1  :  未実装

rem **** Flow 0   :  実装済み

rem ???? Flow 1   :  仮実装済み

rem ???? Flow 2   :  仮実装済み

rem ???? Flow 3   :  仮実装済み

rem !!!! Flow 4   :  未実装

rem ???? Flow 5   :  仮実装済み

rem ???? Flow 6   :  仮実装済み

rem !!!! Flow 7   :  未実装
::==============================================================================================================
rem -1) AD_RC initialization (load constants)
rem TODO: if not defined RC_S_FLOW call "%PROJECT_ROOT%\Src\Systems\Debug\Rc.Const.bat" || (set "AD_RC=90690001" & goto :FailRun)

::

rem 0) Mode Interpretation (Default=RUN) (*RUN*|DEBUG|INTERCEPT)
set "BUILD_PROFILE=release" & set "INTERCEPT_MODE=0"
if /i "%~1"=="-mode" if /i "%~2"=="debug"     set "BUILD_PROFILE=dev"
if /i "%~1"=="-mode" if /i "%~2"=="intercept" set "BUILD_PROFILE=dev" & set "INTERCEPT_MODE=1"

::

rem 1) LaunchGuard
call "%PROJECT_ROOT%\Src\Systems\Launcher\LaunchGuard.bat" "%PROJECT_ROOT%"
call :_gate_ok "LaunchGuard" || goto :FailFirstRun
::

rem 2) Bootstrap
call "%PROJECT_ROOT%\Src\Systems\Bootstrap\Bootstrap_Init.bat" "%PROJECT_ROOT%"
if not %errorlevel% equ 10690000 goto :FailFirstRun

::

rem 3) Environment_Check (PowerShell availability/screen/VT)
call "%src_env_dir%\ScreenEnvironmentDetection.bat" "%PROJECT_ROOT%"
if not %errorlevel% equ 10690000 goto :FailFirstRun

::

rem 4) Signature Verification (Fail-Fast)
rem TODO call "%PROJECT_ROOT%\Src\Systems\Security\VerifySignatures.bat"

::

rem 5) Main 起動
start /d "%src_main_dir%" Main.bat 65001 "AstralDivide[v0.1.0]"
set launch_time=%time%

::

rem 6) Watchdog 常時起動（モード反映）
> "%PROJECT_ROOT%\Runtime\ipc\.mode" (if "%INTERCEPT_MODE%"=="1" (echo INTERCEPT) else (echo NORMAL))
call "%PROJECT_ROOT%\Src\Systems\Debug\Watchdog_Host.bat"

::

rem 7) 後片付け
rem TODO del /q "%PROJECT_ROOT%\Runtime\ipc\*.tmp" 2>nul
rem TODO exit /b %AD_RC%

::==============================================================================================================


rem//============================ Developer console (optional; keep off in release) ==========================//
set /p command="" & %command%
if "%command%"=="" (goto :eof)
rem//=========================================================================================================//

rem!========================================== Error & Exit sections ==========================================!
:FailFirstRun
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _pretty %errorlevel%
echo %esc%[31m[E1300]%esc%[0m 初期設定に失敗しました。保存先や権限をご確認ください。
set "rc_code=%errorlevel%"
goto :ExitRun

:FailRun
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _pretty %rc_code%
goto :ExitRun

:ExitRun
call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _trace info "Run.bat exit rc=%rc_code%"
endlocal & exit /b %rc_code%
rem!===========================================================================================================!

rem?================================================= Helpers =================================================?
:_gate_ok
rem use after any module call
set "mod=%~1"
set "rc=%errorlevel%"

if %rc% LSS 10000000 (
    rem 外部/未規格は Systems/Other で包む（1行）
    call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _return %rc_s_err% %rc_d_sys% %rc_r_other% 1 "Wrapped external rc=%rc%"
    set "rc=%errorlevel%"
)

call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _decode %rc%
if "%rc_s%"=="1" exit /b 0

call "%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat" _trace err "%mod% failed rc=%rc%"
exit /b %rc%
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