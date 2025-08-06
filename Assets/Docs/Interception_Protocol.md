# Interception Protocol Specification (IPS)

## 概要
`Interception Protocol Specification` (IPS) は、RPGGAME2024 プロジェクトの `Main.bat`と `Run.bat` (ウォッチドッグ)の間で、モード=INTERCEPT時に違うバッチプロセス間で「部分的な指示パス交信」を行うためのプロトコルである。

---

## 目的
- ウォッチドッグ側からの命令によって Main.bat の挙動を制御する
- Main.bat 側の現在状態や内部情報をリアルタイムで見る
- デバッグ機構やプレース調査機能を実装する

---

## プロトコル構成

### ▶ 起動時
- `Main.bat` の先頭で:
```bat
echo INTERCEPT > .mode
```

- `Run.bat` 側で:
```bat
if exist .mode (
  set /p MODE=<.mode
  if /i "%MODE%"=="INTERCEPT" call :Intercept_Loop
)
```

### ▶ Main.bat 側

```bat
:RVP_MENU_SELECTED_START
call :log "[RVP] MENU_SELECTED"
echo RVP_MENU_SELECTED_START > .rendezvous
echo READY > .command

:wait_for_cmd
if not exist .command.in (
    timeout /t 1 >nul
    goto :wait_for_cmd
)
set /p cmd=<.command.in
del .command.in
if "%cmd%"=="force_continue" goto :continue
if "%cmd%"=="dump_vars" call :dump_env
:: この他の指示は追加可
```


### ▶ Run.bat 側
```bat
:Intercept_Loop
:loop
if exist .rendezvous (
    set /p RVP=<.rendezvous
    echo [INTCPT] RVP: %RVP%
    :: オペレータにて指示を取得
    set /p command=Command? [force_continue/dump_vars/...]:
    echo %command% > .command.in
    del .rendezvous
    goto :loop
)
timeout /t 1 >nul
goto :loop
```

---

## 使用ファイル統一
| ファイル | 作成側 | 内容 |
|----------|----------|-------|
| `.mode` | Main.bat | INTERCEPT を表すモード認識用 |
| `.rendezvous` | Main.bat | 現在のRVP ID |
| `.command` | Main.bat | READYと書かれる。WDによるコマンド受信の準備 |
| `.command.in` | Run.bat | 命令を仕込む。Main.bat側が解析 |

---

## 代表指令
| 指令 | 意味 |
|--------|------|
| `force_continue` | メインを通常展開させる |
| `dump_vars` | 現在の環境変数をログへ出力 |
| `exit_now` | Main.bat を強制終了させる |

---

## 結論
`IPS` は、Main.bat と Run.bat の間での「静的監視」を超えた「互互通信型の実行管理」を実現するためのデザインであり、操作一時停止、命令受信、現在情報の把握を可能にし、バッチゲームのデバッグ性を高める。

