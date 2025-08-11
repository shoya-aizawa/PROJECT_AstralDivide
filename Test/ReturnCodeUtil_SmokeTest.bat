@echo off
chcp 65001 >nul

rem ============================================================
rem ReturnCodeUtil.bat  Smoke Test (RC v1)
rem ============================================================




rem 0) パスを環境変数化
cd ..
set PROJECT_ROOT=%cd%
set "RECS_Util=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
set "RECS_Const=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeConst.bat"
if not exist "%RECS_Util%"  (echo [NG] util not found: "%RECS_Util%"  & pause>nul & popd & exit /b 1)
if not exist "%RECS_Const%" (echo [NG] const not found: "%RECS_Const%" & pause>nul & popd & exit /b 1)

rem 1) シンボルを設定
call "%RECS_Const%"

rem 2) コード生成（8桁）を標準出力で受け取る
for /f %%R in ('call "%RECS_Util%" -build 1 02 10 004') do set "RC=%%R"

rem 3) 整形表示
call "%RECS_Util%" -pretty %RC%

rem 4) 正常終了を返す（exit /b 10101001）
call "%RECS_Util%" -return 1 01 01 001

rem 5) 例外系（標準エラーにログを出して終了コードも設定）
call "%RECS_Util%" -throw 9 02 10 004 "slot=2 not found"

