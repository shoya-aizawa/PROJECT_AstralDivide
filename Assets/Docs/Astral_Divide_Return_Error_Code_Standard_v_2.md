# Astral Divide Return/Error Code Standard (RCS) – v2.0

**Project:** PROJECT_AstralDivide / HedgeHogSoft  
**Developer:** 愛澤翔也 (HedgeHog)  
**File:** `RCS_Const.bat` v0.1a / `RCS_Util.bat` v0.4  
**Status:** Stable Release (Adopted)  
**Date:** 2026-05-31  

---

## 1. 概要

本仕様書は、Astral Divide 全体における戻り値・例外・状態コードを統一的に扱うための **Return Code System (RCS) コード規格** を規定する。  
本規格は従来の 4桁エラーコードおよび RECS v1 仕様を完全に統合・刷新し、8桁の数値表記によって実行コンテキストとエラー情報を一元的に表現する。

---

## 2. RCS コード構造 (8桁: `SDDRRCCC`)

すべての RCS コードは、8桁の固定長整数値（`SDDRRCCC`）で表現され、以下のように分割してデコードされる。

```
S DD RR CCC
1桁 2桁 2桁 3桁  → 連結して 8桁（例：1-06-90-000 → 10690000）
```

### 2.1 区分（S - State / 1桁）
実行状態またはコードの重要度を規定する。

| 値 | 区分名 | 意味・用途 |
|---|---|---|
| `1` | `FLOW` | 正常フロー（処理成功、シーン遷移など） |
| `2` | `INFO` | 情報（ログ用、非エラー状態の通知） |
| `3` | `WARN` | 警告（非致命的な不具合、フォールバック等） |
| `8` | `CANCEL` | ユーザー操作による意図的なキャンセル・戻る |
| `9` | `ERR` | 異常終了・致命的なシステムエラー（即時安全停止対象） |

---

### 2.2 ドメイン（DD - Domain / 2桁）
エラーまたはフローが発生したモジュール領域（サブシステム）を示す。

| 値 | ドメイン名 | 対象の処理領域 |
|---|---|---|
| `01` | `MainMenu` | タイトル画面・メインメニュー UI |
| `02` | `SaveData` | セーブスロット選択・セーブデータの検出と入出力 |
| `03` | `Display` | 画面レンダリング・Markup処理・テンプレート表示 |
| `04` | `Environment` | 画面サイズ検出・仮想ターミナル設定・環境チェック |
| `05` | `Audio` | BGM・SE 再生制御サブシステム |
| `06` | `Systems` | システムブート・モジュール初期化・統合起動シーケンス |
| `07` | `Network` | GAS連携・HTTP通信・ログ転送処理 |
| `08` | `Story` | シナリオ処理・ストーリーエピソード制御・テキスト資産 |
| `09` | `Debug` | デバッグHUD・Watchdogホスト・インターセプトフック |

---

### 2.3 理由（RR - Reason / 2桁）
イベントまたはエラーが発生した根本原因・カテゴリを示す。

| 値 | 理由名 | 意味 |
|---|---|---|
| `01` | `Selection` | UI上の選択・決定・ユーザー入力 |
| `10` | `I/O` | ファイル入出力失敗・ディレクトリ作成失敗・権限不足 |
| `11` | `Parse` | テキスト/プロファイルのパース失敗・構文解析不一致 |
| `12` | `Encode` | 文字コードエンコーディング不一致・JSONシリアライズ失敗 |
| `20` | `Network` | 通信タイムアウト・GAS側エラー応答・接続切断 |
| `30` | `Validation` | 署名検証不一致・事前条件不成立・引数不正 |
| `50` | `Compat` | 互換性不一致・PowerShellバージョン非対応・Font不在 |
| `90` | `Other` | その他分類不能な事象 |

---

### 2.4 詳細ID（CCC - Case / 3桁）
各モジュール内の具体的なケースを示す 3桁の数値（`000`〜`999`）。ドメインおよび理由が同一であっても、異なる詳細IDを割り当てることで、ソースコード内のどこでエラーが発生したかをピンポイントで特定できる。

- `000` : 各カテゴリにおける標準の成功 / 完了コード（例: `10690000` = システム共通の成功コード `RC_OK`）
- `001–999` : モジュール内で定義される個別のケースID

---

## 3. RCS ユーティリティ使用規約 (`RCS_Util.bat`)

システム内のバッチファイルは、RCSコードの生成や終了処理に直接生数値（マジックナンバー）を使用せず、必ず `RCS_Util.bat` を介して制御しなければならない。

### 3.1 正常返却 (`-return`)
呼び出し側で `FLOW` コードを作成して終了する。

```bat
:: 成功コード 1-06-90-000 を返して終了
call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000 "Bootstrap successful"
exit /b %errorlevel%
```

### 3.2 例外送出 (`-throw`)
エラーログ（`Config\Logs\AstralDivide_Error_*.log`）へ二重記録し、`ERR` コードを返して終了する。

```bat
:: セーブデータ書き込み失敗を投げる
call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 002 "Failed to write save slot 1"
exit /b %errorlevel%
```

### 3.3 結果のデコードと判定 (`-decode`)
返却された RCS コードを分解し、区分 (`rcs_s`) に応じてフローを制御する。`if errorlevel` などの数値大小判定は行わず、必ず完全一致で判定する。

```bat
call "%src_display_dir%\MainMenuModule.bat"
call "%RCSU%" -decode %errorlevel%
if not "%rcs_s%"=="1" (
    :: 正常フロー以外（キャンセルやエラー）の例外処理へ
    goto :STATE_EXIT
)
```

---

## 4. マスターコード定義

現在 `RCS_Code_Master.csv` に定義されている標準コードの対応表。

| RCSコード | 区分 (S) | ドメイン (DD) | 理由 (RR) | ケース (CCC) | ラベル名 | 意味 |
|---|---|---|---|---|---|---|
| `10690000` | FLOW | Systems | Other | 000 | `RC_OK` | システム正常終了（共通成功コード） |
| `20101001` | INFO | MainMenu | Selection | 001 | `MENU_SELECT` | メニュー項目が選択された |
| `20210002` | INFO | SaveData | I/O | 002 | `SAVE_CREATED` | 新規セーブデータ作成完了 |
| `20450001` | INFO | Environment | Compat | 001 | `ENV_COMPAT_OK` | 環境互換性チェック成功 |
| `80101001` | CANCEL | MainMenu | Selection | 001 | `MENU_CANCEL` | メニュー操作がキャンセルされた |
| `90610001` | ERR | Systems | I/O | 001 | `SYS_IO_FAIL` | システムI/O失敗（起動停止） |

---

**End of Document – Return/Error Code Standard v2.0**
