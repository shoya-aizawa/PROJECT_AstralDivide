# Astral Divide RCS Protocol – v0.4 Specification

**Project:** PROJECT_AstralDivide  
**Developer:** HedgeHogSoft (愛澤翔也 / HedgeHog)  
**Subsystem:** Return Code System (RCS)  
**File:** `RCS_Util.bat` v0.4  
**Date:** 2026-05-31  
**Status:** Stable Release (Adopted)  

---

## 1. 概要

RCS (Return Code System) は、Astral Divide 全体に統一的な戻り値・例外・ログ出力管理を提供する基盤モジュールである。  
本バージョン（v0.4）は、旧仕様（v0.3a）で確立されたサイレントログ設計を踏襲しつつ、プロセス同期・開発時のデバッグ効率化のために**戻り値の親スコープ伝搬機構 (`rcs_code`)** や、**超高速な pure batch タイムスタンプ生成** を導入した完全安定版である。

---

## 2. 開発履歴 / バージョン推移

| Version   | Date       | 主な更新内容                                             |
| --------- | ---------- | -------------------------------------------------- |
| **v0.1d** | 2025-10-18 | 旧Run.batにRCS導入実験版。RC_LAST等の暫定変数を運用。               |
| **v0.2**  | 2025-10-20 | RCS_Util独立化、構文統一（-build / -throw / -trace）。       |
| **v0.3**  | 2025-10-21 | 統合ログシステム実装（セッション単位ログ）、Powershell時刻精密化。             |
| **v0.3a** | 2025-10-22 | サイレントログ仕様採用（INFO系出力抑制）、pretty/helpのみ表示許可。最終安定リリース。 |
| **v0.4**  | 2026-05-31 | **親スコープへの `rcs_code` エクスポート**、**pure batch 高速タイムスタンプ生成**、コマンドヘルプの構造化。 |

---

## 3. システム構造

```
PROJECT_ROOT
 └─ Src\Systems\Debug\RCS_Util.bat     (本体)
 └─ Src\Systems\Debug\RCS_Const.bat    (定数定義レイヤ v0.1a)
 └─ Config\Logs\                        (ログ出力ディレクトリ)
```

### 3.1 主な関数一覧とコマンド分類

RCS_Util.bat v0.4 は、役割に応じてコマンドが分類されている。

| 分類 | ラベル | 機能 | 出力 | 備考 |
|---|---|---|---|---|
| **[External Commands]** | `-return` | 正常終了処理 | サイレント | traceに転送しつつ、親スコープにコードを返却 |
| | `-throw` | 例外送出処理 | サイレント | 統合ログ・エラーログに書き込み、親スコープにコードを返却 |
| | `-trace` | トレースログ出力 | サイレント | `Config/Logs` にタイムスタンプ付きで追記 |
| **[Internal Mechanics]** | `-build` | 8桁コード構築 | 非表示 | SDDRRCCCを算出し、`rcs_code` / `ERRORLEVEL` に設定 |
| | `-decode` | 8桁コード分解 | 非表示 | `rcs_s`, `rcs_dd`, `rcs_rr`, `rcs_ccc` 変数へ展開 |
| **[Debug/Confirmation]** | `-pretty` | 人間可読整形表示 | 表示あり | デバッグ確認用（ログには残さない） |
| | `-help` | ヘルプ表示 | 表示あり | 明示呼出時のみ表示 |

---

## 4. v0.4 での新機能と実装詳細

### 4.1 グローバル変数 `rcs_code` による親スコープ連携
バッチスクリプト内の `setlocal` 環境から親スコープに戻り値をエクスポートするため、終了時に以下の機構を使用している。
呼び出し側は `errorlevel` を直接チェックするだけでなく、呼び出し後に `%rcs_code%` 変数を参照することで最後に生成/返却されたRCを取得できる。

```bat
:: RCS_Util.bat 内の実装例
endlocal & (
    set "rcs_code=%code%"
    exit /b %code%
)
```

### 4.2 pure batch による超高速タイムスタンプ取得 (`ts`)
タイムスタンプの取得に `PowerShell` や外部プロセス（`wmic`等）を呼び出すと、conhostのフォントリセットバグを引き起こすか、あるいは大きな遅延（数百ms）が発生する。  
v0.4 では Windows の標準変数展開のみを用いた高速タイムスタンプ生成を実装し、オーバーヘッドを 0ms に抑えた。

```bat
:: 高速タイムスタンプ展開処理の実装
set "t_date=%date%"
set "t_time=%time: =0%"
set "date_tag=%t_date:~0,4%-%t_date:~5,2%-%t_date:~8,2%"
set "ts=%date_tag%_%t_time:~0,2%-%t_time:~3,2%-%t_time:~6,2%"
```

---

## 5. サイレントログ仕様

開発者の理念 **「黙って記録し、必要な時だけ語る (Trace everything, but display nothing)」** を体現するため、コンソールノイズを排除したログ設計となっている。

| 対象 | コンソール出力 | ログ出力 | 理由 |
|---|---|---|---|
| `-trace` / `-throw` / `-return` | ❌ 無し | ✅ 有り | 実行時のユーザー体験（UX）向上とノイズ排除 |
| `-pretty` / `-help` | ✅ 有り | ❌ 無し | デバッグ時の確認専用機能 |

### 5.1 ログ出力仕様
- **出力ディレクトリ**: `PROJECT_ROOT\Config\Logs`
- **セッションログ**: `Config\Logs\AstralDivide_Session_YYYY-MM-DD.log` (すべてのログを集約)
- **エラーログ**: `Config\Logs\AstralDivide_Error_YYYY-MM-DD.log` (`ERR` レベルのイベントのみを二重記録)

**フォーマット:**
```
[YYYY-MM-DD_HH-MM-SS] [LEVEL] [MODULE] message
```

---

## 6. 変数・命名規約ポリシー

| 種別 | 命名規則 | 例 |
|---|---|---|
| コマンド | 小文字統一、ハイフン開始 | `call RCS_Util.bat -trace ...` |
| 変数 | snake_case | `runtime_ipc_dir`, `config_logs_dir`, `rcs_code` |
| 定数 | 大文字＋アンダースコア | `RCS_LOG_FILE`, `RCS_LOG_DIR`, `RCS_S_FLOW` |
| デバッグ/グローバル | 全大文字 | `RC_LAST`, `RC_OK` |

---

## 7. 運用フローと Bootstrap

配布用ランチャ（`AstralDivide.bat`）から起動される `Run.bat` が最初に RCS のブートストラップ（読み込み）を行う。

```
AstralDivide.bat (起動エントリ)
   │
   ▼  set "GAME_LAUNCHER=1" & call Run.bat
Run.bat (ランチャー)
   │
   ├─ [RCS Bootstrap]
   │    ├─ RCS_Util.bat 存在確認 (無ければ FailRun)
   │    ├─ RCS_Const.bat 読込 (定数定義)
   │    └─ RC_OK 定義
   │
   ▼  call Main.bat
Main.bat (ゲーム本体)
```

ブートストラップ時に RCS_Util.bat または RCS_Const.bat が欠損している場合、システムは `90610001` (ERR / Systems / I/O / case001) または `90610002` を発行し、直ちに安全停止（Fail-Fast）する。

---

## 8. 将来の拡張予定

- **v0.5.x:** Codex メタシステムとの動的連携、エラーコード自動一覧出力。
- **v1.0.x:** RCSをコアモジュールとして `Systems/Core` に統合。
- **vFuture:** `Pretty` 出力の JSON 形式サポート、Watchdog側RVPイベントとの同期連携。

---

**End of Document – RCS Specification v0.4**
