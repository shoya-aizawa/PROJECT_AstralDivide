::    +=================================================================+
::    | Run.bat                                                         |
::    | aka : "Launcher"                                                |
::    | This is Launcher for start the RPG game.                        |
::    | In addition to starting Main.bat,                               |
::    | checks the environment and set up the necessary configurations. |
::    +=================================================================+

@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof
@for /f %%a in ('cmd /k prompt $e^<nul') do (set "esc=%%a")
@reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
@echo off
@prompt $G

:: if exist .WIP files(work in progress),goto Set_Encording
:: else goto Set_Path

:Set_Encoding
:: (!) ONLY AT FIRST TIME LAUNCH (!)
:: Ask the user to set the language and system encoding.
:: In the future, call ArgumentsCheck.bat here,
:: I plan to check the listed arguments
:: For example, if the user wants to use Japanese, set the encoding to 65001.
:: If the user wants to use English, set the encoding to 437.
:: Developer HegdeHog is JAP XD
chcp 65001 >nul

:Set_Path
call "%cd%\Src\Systems\SettingPath.bat"

:Check_Environment
:: Localize to preventing variable scope pollution (dev now not needed)
setlocal
:: Check user environment
:: e.g. : check display size, can u use powershell, etc.


:: TEST(20250726)
call "%src_environment_dir%\ScreenEnvironmentDetection.bat"


endlocal





:StartProgram
:: Start Main.bat with the specified encoding.
:: For now, I'll set the encoding to 65001. (for Japanese)
start "RPGGAME2024" /max cmd /c %src_main_dir%\Main.bat 65001
set launch_time=%time%

:: in the future,
:: Main.bat "Japanese" or "English"
:: will be used to pass the encoding argument from Run.bat to Main.bat.

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

exit /b

rem ****************************共有：本プロジェクトの命名規則について****************************

rem コマンド (Command) : 小文字で統一(command)
rem     ・コマンドは頻繁に使用されるため、小文字で統一することで視覚的ノイズを減らし、読みやすくなる。
rem     ・Windowsコマンドプロンプトでは大文字小文字を区別しないため、小文字統一で問題なく動作する。

rem 変数名(Variable name) ： スネークケース(snake_case)
rem     ・長い名前でも読みやすく、バッチの特殊文字（%や!）と区別がつきやすいため、可読性が向上する。
rem     ・例外として、デバッグ変数は大文字で統一することで、他の変数と区別しやすくなる。

rem ラベル名(Label name) : パスカルケース＆プレフィックス/サフィックス(Label_PascalCase)
rem     ・関数や目的別のラベル名を明確に示せるため、コード全体の整理がしやすい。
rem     ・ジャンプ先をすぐに見つけられるため、コードのデバッグや変更がスムーズになる。
rem     ・視覚的に他のコード（コマンドや変数名）と区別がつきやすい。

rem ファイル名(File name) : パスカルケース(PascalCase)
rem     ・ファイル名の命名に一貫性を持たせることで、プロジェクト全体の整理がしやすい。
rem     ・ファイル名がOS環境（例: Windows）で大文字小文字の区別がつかなくても、構造的に分かりやすい。

rem フォルダ名(Folder name) : パスカルケース(PascalCase)
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