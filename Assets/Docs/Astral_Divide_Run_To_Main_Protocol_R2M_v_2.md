# Astral Divide — Run→Main Protocol (R2M) v2.2

**Project:** PROJECT\_AstralDivide (HedgeHogSoft)
**Doc Type:** Implementation Standard / .md
**Status:** Draft v2.2
**Date:** 2025-08-09 (JST)

> 本版は **Watchdog を `start` ではなく `call` で同期実行**する設計へ修正したアップデートです。

---

## 1. 概要（Purpose）

R2Mは、**Run.bat（Launcher）→ Main.bat（Game Core）** の正式起動フローを規定し、以下を担保する：

* **安全性の高い起動継続**（各ステージのFail-Fastと可観測性）
* **profile.env の自動生成・検出・自己修復**（初回/非初回で分岐）
* **ルートパス受け渡し**（`-root "<path>"` / 未指定時は自動推定）
* **初回起動判定とセットアップウィザード**（言語/保存先）
* **モジュール分割による責務分離**（Launcher/Bootstrap/Environment/Security/Watchdog）
* **AD\_RC v1**（8桁コード）による戻り値の統一・ログ整形
* **非同期起動設計**：Run は Main を **/wait せず**起動。**Watchdog を `call` で同期起動**し、**終了原因の確定**を任せる

---

## 2. スコープ & 用語

* **Launcher**: Run.bat（本仕様の主対象）
* **Main**: Main.bat（ゲーム本体）
* **Bootstrap**: 初回/自己修復、`profile.env` 生成/読込/検証
* **Environment**: 画面/VT/PowerShell等の環境検査
* **Security**: 署名等の検証（任意 / Fail-Fast）
* **Watchdog**: 常駐監視（INTERCEPT対応、終了原因の確定担当）。**Run から `call` で同期実行**
* **AD\_RC v1**: `SDDRRCCC`（8桁）で戻り値を表現する標準（R/E兼用）

---

## 3. シーケンス（概要）

```
AstralDivide.bat/.exe (root)        
        │  -root <path> [-mode run|debug|intercept]
        ▼
Run.bat ──► LaunchGuard ──► Bootstrap_Init ──► ScreenEnvironmentDetection ──► VerifySignatures (opt)
   │
   │  .mode (NORMAL|INTERCEPT)
   │  session_<id>/ (create; write session.meta)
   │
   ├─► start Main.bat (async; env: LAUNCH_ID, SESSION_DIR)
   ├─► call Watchdog_Host.bat (sync; arg: session_dir)
   │
   └─► Return (Run は WD の終了まで継続。Run の終了コードは原則未使用)

Watchdog_Host ──► monitors session_<id>/ (heartbeat, final_rc.txt, reason.txt ...)
                 └─► determines final AD_RC (from final_rc.txt or inference) and logs analysis
```

---

## 4. 入出力契約（Contract）

### 4.1 Run.bat の入力

* **CLI**: `-root "<absolute project root>"`（省略可/自動推定），`-mode run|debug|intercept`（既定 run）

### 4.2 Run.bat の出力・副作用

* `Config\profile.env` の生成/更新（自己修復）
* `Runtime\ipc\.mode` に **NORMAL/INTERCEPT** を出力
* `Runtime\ipc\session_<id>\` ディレクトリを作成し、`session.meta` を出力
* **Run の終了コード**：原則**未使用**（Run は WD を同期実行し、最終状態は WD がログへ確定）
* ログ（`Logs/ad_YYYY-MM-DD_HH-mm-ss.log`）

### 4.3 Main.bat の入力契約

* **引数**: `Main.bat <codepage:65001> "AstralDivide[vX.Y.Z]"`
* **環境**: `project_root` / `build_profile` / `intercept_mode` に加え、**`LAUNCH_ID`** と **`SESSION_DIR`** を受け取る
* **責務（重要）**: 終了直前に **`final_rc.txt`**（8桁の AD\_RC）を `SESSION_DIR` へ書き出す。任意で `reason.txt`（短文）や `heartbeat`（定期更新ファイル）も出力

### 4.4 Watchdog の契約

* 引数で受け取った `session_dir` を監視し、以下で最終状態を判定：

  * `final_rc.txt` が存在する → その値を最終 AD\_RC として採用
  * 存在しないがプロセス消滅／ハートビート停止 → 分類規則に従い **`S=9`** を推定して採番
* `analysis.log` / `analysis.json` 等に決定根拠を記録
* **Run から `call` されるため**、WD が終了するまで Run は継続する

---

## 5. profile.env スキーマ（v1）

**必須キー**

```
PROFILE_SCHEMA=1
CODEPAGE=65001
LANGUAGE=ja-JP                ; 例：ja-JP / en-US
SAVE_MODE=portable            ; portable / localappdata / custom
SAVE_DIR=<abs path>           ; SAVE_MODEに応じて決定/入力
```

**自己修復ポリシ**（擬似コード）

```
if PROFILE_SCHEMA not set -> set 1
if CODEPAGE not set       -> set 65001
if LANGUAGE not set       -> set ja-JP
if SAVE_MODE not in {portable, localappdata, custom} -> set portable
if SAVE_DIR not set:
  if SAVE_MODE==localappdata -> %LOCALAPPDATA%\HedgeHogSoft\AstralDivide\Saves
  if SAVE_MODE==portable     -> %project_root%\Saves
  if SAVE_MODE==custom       -> call SetupStorageWizard.bat  ; 決定できなければFail-Fast
```

**初回**は `SetupLanguage.bat` → `SetupStorageWizard.bat` を優先実行。以後は `LoadEnv.bat` が自己修復を担当。

---

## 6. フロー・ステージ定義（Run側）

Runは各ステージ実行直後に戻り値を評価し、**`S==1` のみ継続**。それ以外は即中断。

| Stage | 呼び出し                                                               | 目的                                | 失敗時の扱い                      |
| ----: | --------------------------------------------------------------------- | ----------------------------------- | -------------------------------- |
|   001 | LaunchGuard.bat                                                       | 多重起動/直叩き/整合性ガード          | Fail-Fast（`S=9`）                |
|   002 | Bootstrap\_Init.bat *or* {LoadEnv, SetupLanguage, SetupStorageWizard} | profile.env の生成/検出/自己修復     | Fail-Fast（`S=9` or `S=8`）       |
|   003 | ScreenEnvironmentDetection.bat                                        | PS/画面/VT 等の検査                  | Fail-Fast（`S=9`）                |
|   004 | VerifySignatures.bat (optional)                                       | 署名/検証                            | Fail-Fast（`S=9`）/ MissingはWARN続行 |
|   005 | Main.bat(**async start**) / **Watchdog(call)**                        | 本体起動（非同期）。Run は **WD を同期実行**して監視を委任 | 最終 AD\_RC は WD が確定しログ化           |

---

## 7. エラーハンドリング（AD\_RC v1 準拠）

* すべての**Run側ステージ**戻り値は **ReturnCodeUtil.bat** で **`_pretty`（整形表示）**＋**`_decode`（判定）**。
* `S!=1` なら即 `:_fail_first`。Run はユーザメッセージを表示し、`_throw` で **Run側のAD\_RC** を返す（`CCC` にステージIDを埋める運用を推奨）。
* **Main の終了分類は Run の責務外**。**Watchdog** が `session_dir`（`final_rc.txt`/heartbeat/プロセス状態）を根拠に確定し、ログ/分析を残す。

---

## 8. ロギング

* Run開始時に `ReturnCodeUtil.bat _log_init`。以後、要所で `_trace info|warn|err` を出す。

---

## 9. Watchdog / INTERCEPT

* `.mode` に **NORMAL / INTERCEPT** を書き出す（`Runtime\ipc\.mode`）。
* **起動**：`call "%sys_debug_dir%\Watchdog_Host.bat" "%session_dir%"`（同期）。
* **session\_dir 構造（推奨）**：

```
session_<id>/
  ├─ session.meta   ; root, build_profile, intercept_mode, launch_time
  ├─ heartbeat      ; Main が定期更新（ms精度で上書き）
  ├─ final_rc.txt   ; Main 終了直前に 8桁 AD_RC を書く（必須）
  └─ reason.txt     ; 任意の短文（例: "Save missing: slot=2"）
```

---

## 10. 互換性 & マイグレーション

* 旧R2M仕様は**廃止**。Runは **AD\_RC v1** を利用。
* 旧`exit /b` 直書きは **`_return/_throw` に置換**（生数値の使用禁止）。
* 旧 `10690000` 等のマジックナンバー比較は、**`_decode` で `S==1` 判定**へ移行。

---

## 11. 実装チェックリスト

* [ ] `ReturnCodeConst.bat` / `ReturnCodeUtil.bat` が配置されている（命名規約遵守）
* [ ] Run.bat が `-root` と `-mode` を解釈し、`.mode` を出力する
* [ ] `Bootstrap_Init.bat` が **profile.env 生成/検出/自己修復**を内包（なければフォールバック実装済み）
* [ ] 各ステージ直後に `_pretty` ログ＆ `S==1` 判定を行う
* [ ] **Main を非同期起動**し、`session_dir` を作成して **Watchdog を call で同期実行**
* [ ] 初回/非初回/キャンセル/エラーの各ケースでスモークテストが通る

---

## 12. 参照実装スニペット（Run側）

```bat
rem .mode 書き出し（INTERCEPT/NORMAL）
> "%runtime_ipc_dir%\.mode" (if "%intercept_mode%"=="1" (echo INTERCEPT) else (echo NORMAL))

rem Main 起動（async）
start "" cmd /c "set LAUNCH_ID=%launch_id%& set SESSION_DIR=%session_dir%& call Main.bat 65001 \"AstralDivide[vX.Y.Z]\""

rem Watchdog 起動（同期実行）
call "%project_root%\Src\Systems\Debug\Watchdog_Host.bat" "%session_dir%"
```

---

## 13. 変更点（v2.2 の主な差分）

* **Watchdog を `start` → `call` に変更**（Run は WD の終了まで継続）
* Run の終了コードは**未使用**である旨を明文化
* 関連セクション（シーケンス、契約、チェックリスト、スニペット）を更新

---

### 署名

Author: HedgeHog（オーナー） / Editor: ChatGPT（構成・整形）
