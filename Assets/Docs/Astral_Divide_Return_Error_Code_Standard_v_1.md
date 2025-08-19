# ReturnCodeUtil.bat（RCU）仕様書 — RECS v1 Helper

**Project:** PROJECT\_AstralDivide / HedgeHogSoft\
**File:** `Src/Systems/Debug/ReturnCodeUtil.bat`（例）\
**Status:** Draft v1.0（実装準拠）\
**Purpose:** 統一戻り値（RC: `S DD RR CCC` → 8桁）を **生成／整形／返却／記録** する小型CLI

---

## 0. 要点（TL;DR）

- **ハイフン記法サブコマンド**：`-build` / `-decode` / `-return` / `-throw` / `-pretty` / `-trace`\
  ※`/help` 受理、`/build` は内部で `-build` に正規化。
- **区切り入力OK**：`-build 1 01 01 001` も `"1-01-01-001"` も可。
- **“自己防衛シフト”**：ディスパッチャでは `shift` せず、各ハンドラ先頭で必要時のみ `shift`。
- **戻り値規約**：`-return`/`-throw` は **終了コード＝RC**。それ以外は `0`（成功）/`3`（引数不正）。
- **ログ**：`-trace` は `Logs\` へ追記。`LOG_MODE`（`daily|session|single`）で回転/分割を選択。

---

## 1. 使用方法（コマンド一覧）

```
ReturnCodeUtil.bat <command> [args...]

build   S DD RR CCC | "S-DD-RR-CCC"   -> 8桁コードを標準出力（%CODE%にも格納）
decode  CODE                          -> S= DD= RR= CCC= を標準出力
return  S DD RR CCC [ctx...]          -> exit /b CODE     （終了コード＝8桁）
throw   S DD RR CCC [ctx...]          -> 標準エラー出力 + exit /b CODE
pretty  CODE                          -> 着色付きの要約表示（人間可読）
trace   LEVEL TAG MSG...              -> Logs\*.log へ追記
help                                  -> 使い方
```

### 1.1 エイリアス・互換

- `-help` / `/help` … どちらもヘルプ表示
- `/build` … 内部で `-build` として扱う（`set "cmd=!cmd:/=-!"` による正規化）

---

## 2. 引数仕様

### 2.1 RC（8桁）構造

```
S DD RR CCC
1桁 2桁 2桁 3桁  → 連結して 8桁（例：1-01-01-001 → 10101001）
```

- `S`（区分）: `1=FLOW`, `8=CANCEL`, `9=ERR`
- `DD`（ドメイン例）: `01=MainMenu, 02=SaveData, 03=Display, 04=Environment, 05=Audio, 06=Systems, 07=Network, 08=Story, 09=Debug/Intercept`
- `RR`（理由例）: `01=Selection, 10=I/O, 11=Parse, 12=Encode, 20=Network, 30=Validation, 50=Compat, 90=Other`
- `CCC`（詳細）: `000–999`

### 2.2 入力形式

- **分離形式**：`-build 1 01 01 001`
- **結合形式**：`-build "1-01-01-001"`（ダッシュ区切り）\
  → どちらもOK。`-decode` は `10101001` でも `"1-01-01-001"` でも可。

---

## 3. サブコマンド詳細

### 3.1 `-build`

- **役割**：`S DD RR CCC` から 8桁を生成して **標準出力**。環境変数 `CODE` にも格納。
- **引数**：`S DD RR CCC` **または** `"S-DD-RR-CCC"`
- **戻り値**：`0`（成功） / `3`（不正）
- **内部**：`padnum` で `1|2|2|3` 桁にゼロ詰め → `CODE=%RC_S%%RC_DD%%RC_RR%%RC_CCC%`

**例**

```bat
> ReturnCodeUtil.bat -build 1 01 01 001
10101001

> ReturnCodeUtil.bat -build "9-06-30-021"
90630021
```

> 実装メモ：現在 `echo %CODE%` が 2 行あるため、パイプ受けで 2 回出力になります。実運用では 1 行に整理推奨。

### 3.2 `-decode`

- **役割**：8桁コードを `S= DD= RR= CCC=` で表示
- **引数**：`CODE`（`10101001` または `"1-01-01-001"`）
- **戻り値**：`0` / `3`

**例**

```bat
> ReturnCodeUtil.bat -decode 90630021
S=9 DD=06 RR=30 CCC=021
```

### 3.3 `-return`

- **役割**：与えた `S DD RR CCC` を構成して `` で終了
- **引数**：`S DD RR CCC [ctx...]`（`ctx` は呼び出し元のログ用途）
- **戻り値**：**終了コード＝8桁**（`ERRORLEVEL` に反映）

**例（呼び出し側）**

```bat
call ReturnCodeUtil.bat -return 1 02 01 051
if "%errorlevel%"=="10201051" echo OK
```

### 3.4 `-throw`

- **役割**：`-return` と同様だが、**標準エラーへ要約 1 行出力**してから終了
- **引数/戻り**：`-return` と同様

**例**

```bat
> ReturnCodeUtil.bat -throw 9 06 10 001 "pubkey missing"
[RECS] THROW 90610001 pubkey missing   1>&2
```

### 3.5 `-pretty`

- **役割**：コードを **色付き** で人間可読表示（STATUS / DOMAIN / REASON 名を併記）
- **引数**：`CODE`
- **戻り**：`0`

**出力例**

```
OK  10101001 [MainMenu / Selection]
ERR 90630021 [Systems / Validation]
```

> 色は ANSI（OK=緑, INTERRUPT=黄, ERROR=赤 など）

### 3.6 `-trace`

- **役割**：`Logs\*.log` へ 1 行追記（**タイムスタンプ + LEVEL + TAG + MSG…**）
- **引数**：`LEVEL TAG MSG...`\
  *MSG は未引用でも、内部で安全に連結して記録*
- **戻り**：`0`

**例**

```bat
set "LOG_MODE=daily" & set "LOG_PREFIX=ad"
ReturnCodeUtil.bat -trace INFO Boot "Env ok / PS=Yes"
ReturnCodeUtil.bat -trace WARN Save "slot=2 missing"
ReturnCodeUtil.bat -trace ERR  Main "Unhandled state X"
```

---

## 4. ログ仕様（`-trace` / `:init_log`）

- **出力先**：`%~dp0..\..\..\Logs`
- **モード**（環境変数 `LOG_MODE`）
  - `daily`（既定） … `ad_YYYY-MM-DD.log`
  - `session` … `ad_YYYY-MM-DD_HH-mm-ss.log`（起動毎に新規）
  - `single` … `ad.log`（**5MB** 超で日時付きへローテ）
- **任意環境変数**
  - `LOG_PREFIX`：既定 `ad`
  - 直接 `LOGFILE` を事前定義すれば完全固定も可
- **レコード例**
  ```
  [2025/08/11 18:35:02.12] INFO SaveLoad start slot=2
  ```

---

## 5. マップ辞書（`-pretty` 内部）

- **Domain（DD）**\
  `01=MainMenu, 02=SaveData, 03=Display, 04=Environment, 05=Audio, 06=Systems, 07=Network, 08=Story, 09=Debug/Intercept`
- **Reason（RR）**\
  `01=Selection, 10=I/O, 11=Parse, 12=Encode, 20=Network, 30=Validation, 50=Compat, 90=Other`

---

## 6. 例：典型フロー

```bat
rem --- 正常選択を返す
call ReturnCodeUtil.bat -return 1 01 01 001  & rem NewGame 決定

rem --- エラー整形表示（Run側）
set "RC=%errorlevel%"
call ReturnCodeUtil.bat -pretty %RC%

rem --- 任意トレース
call ReturnCodeUtil.bat -trace INFO Main "Menu drawn A"
```

---

## 7. 失敗時の規約

- **入力検証失敗**（数値でない／桁不正） … `exit /b 3`
- ``** の内部 **``** 失敗** … `exit /b 3`
- **比較は等価判定**（`if "%errorlevel%"=="N"`）を前提。`if errorlevel N` の≧判定は使用しない。

---

## 8. 実装メモ（安全運用のための要点）

- **自己防衛シフト**：各ハンドラ先頭で `if /i "%~1"=="-xxxx" shift`。
- **パディング**：`padnum`（1/2/3 桁）でゼロ詰め確実化（事前展開衝突回避）。
- **コード正規化**：`normalize_code` で `-` を除去→8桁チェック。
- **ANSI**：`-pretty` の色は CMD の VT 対応環境を前提（`chcp 65001` 等）。

---

## 9. 推奨コーディングパターン（呼び出し側）

```bat
:: 戻り値をそのまま親へ伝搬
call ReturnCodeUtil.bat -return 1 06 90 000 "bootstrap ok"
exit /b %errorlevel%

:: 異常時は throw で即終了
call ReturnCodeUtil.bat -throw 9 06 10 001 "pubkey missing"
```

---

## 10. 変更履歴（抜粋）

- **v1.0 初版**
  - ハイフンCLI／ディスパッチ無シフト化
  - `-trace` の安全メッセージ組立
  - ログモード：`daily/session/single`（`single` 5MBローテ）

---

## 付録A：コマンド別戻り規約（要約）

| Command   | 成功時 | 失敗時 | 備考                          |
| --------- | --- | --- | --------------------------- |
| `-build`  | `0` | `3` | `CODE` へ格納、標準出力あり（※現状は二重出力） |
| `-decode` | `0` | `3` | 入力は `8桁` or `S-DD-RR-CCC`   |
| `-return` | ``  | `3` | 呼び出し元 `ERRORLEVEL` に直結      |
| `-throw`  | ``  | `3` | 事前に標準エラーへ 1 行出力             |
| `-pretty` | `0` | `3` | ANSI カラー                    |
| `-trace`  | `0` | `0` | ログ初期化は自動（`LOG_MODE` で切替）    |

---

## 付録B：環境変数一覧

| 変数           | 既定       | 役割                         |
| ------------ | -------- | -------------------------- |
| `LOG_MODE`   | `daily`  | `daily / session / single` |
| `LOG_PREFIX` | `ad`     | ログファイル接頭辞                  |
| `LOGDIR`     | `…\Logs` | ログ格納ディレクトリ（自動生成）           |
| `LOGFILE`    | *未定義*    | 完全指定したい場合は事前にフルパス設定        |

> 本仕様は、提示の実装スニペットに準拠した **Markdown 原文** です。ゲーム本体・ランチャ各モジュールは **“生数値を書かず、必ず RCU 経由”** を徹底してください。

