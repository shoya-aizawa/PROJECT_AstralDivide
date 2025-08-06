# Main-Run Debug Intercept Protocol (MRD-Prot)

## 概要
`MRD-Prot` は、RPGGAME2024 プロジェクトにおける `Main.bat`の実行フローにおけるデバッグログを `Run.bat` (ウォッチドッグ)側で監視、リアルタイムに特定ランデブーポイントにおけるプロセス切り替えを可能にする「分散型デバッグ監視プロトコル」である。

---

## 目的
- プロセス異常の早期検出
- Main.bat側のデバッグ情報の精密なログ出力
- Run.bat側の通信ロジックによるインターセプト
- デバッグモードON時の特別操作

---

## 構成

### [Main.bat]
- 実行ライン每に以下を追加

```bat
call :log "[MAIN] メインメニュー初期化開始"
```

- `:log` ラベルの中で
```bat
:: デバッグモードの場合のみ
if "%DEBUG%"=="1" (
    echo %~1>> logs\main.debug.log
)
```

- ランデブーポイントでは毎ログ書き込後に
```bat
if exist .rendezvous (
    echo %time% LOG > .rendezvous
)
```

### [Run.bat - Watchdog]
- `.rendezvous` の更新時刻を監視

```bat
:watch
if exist .rendezvous (
    for /f %%T in ('more .rendezvous') do set "last=%%T"
    echo [WD] Rendezvous hit at %last%
    del .rendezvous
)
```

- `.debugmode` があれば定期的に logs\main.debug.log を tailして表示

```bat
if exist .debugmode (
    more +10 logs\main.debug.log | find /v "" > con
)
```

---

## モード

| モードID | 説明 |
|----------|------|
| 0 | デフォルト (静的動作) |
| 1 | デバッグモードON (監視有効) |
| 2 | デバッグ+インターセプト機構 |

---

## 結論
MRD-Prot は、バッチプロセスの弱点である「静的デバッグ」をインターセプト化し、Run.bat との分散型監視系として高度なエラー検知、時間調査、デバッグUIの策定を可能にする。

