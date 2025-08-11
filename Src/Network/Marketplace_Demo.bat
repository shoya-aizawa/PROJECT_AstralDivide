@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: [1] 出品一覧を表示

call Marketplace_ShowItems.bat

:: [2] ユーザーに item_id を聞く

set /p "SELECTED_ITEM_ID=購入したい item_id を入力してください: "

:: [3] 購入処理へ渡す

call Marketplace_BuyItem.bat %SELECTED_ITEM_ID%

:: [4] 終了

echo 処理完了。Enterで終了。
pause >nul
endlocal
exit /b
