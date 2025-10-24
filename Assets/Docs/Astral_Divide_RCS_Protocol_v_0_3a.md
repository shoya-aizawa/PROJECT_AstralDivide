# Astral Divide RCS Protocol – v0.3a Final Summary

**Project:** PROJECT\_AstralDivide\
**Developer:** HedgeHogSoft (愛澤翔也 / HedgeHog)\
**Subsystem:** Return Code System (RCS)\
**File:** `RCS_Util.bat` v0.3a\
**Date:** 2025-10-22

---

## 1. 概要

RCS (Return Code System) は、Astral Divide 全体に統一的な戻り値・例外・ログ出力管理を提供する基盤モジュールである。\
本プロトコルは旧仕様「ReturnCodeUtil.bat (RECS v1)」をベースに、構造・命名規則・ログ制御を再設計し、**冗長性を排しつつも可読性と再利用性を維持する設計**へと刷新した。

本バージョン（v0.3a）は、**RCS機能の基礎完成段階**として、今後のCodex移行・エラーコード標準化に対応可能な仕様を確立した最終安定版である。

---

## 2. 開発履歴 / バージョン推移

| Version   | Date       | 主な更新内容                                             |
| --------- | ---------- | -------------------------------------------------- |
| **v0.1d** | 2025-10-18 | 旧Run.batにRCS導入実験版。RC\_LAST等の暫定変数を運用。               |
| **v0.2**  | 2025-10-20 | RCS\_Util独立化、構文統一（-build / -throw / -trace）。       |
| **v0.3**  | 2025-10-21 | 統合ログシステム実装（セッション単位ログ）、Powershell時刻精密化。             |
| **v0.3a** | 2025-10-22 | サイレントログ仕様採用（INFO系出力抑制）、pretty/helpのみ表示許可。最終安定リリース。 |

---

## 3. システム構造

```
PROJECT_ROOT
 └─ Src\Systems\Debug\RCS_Util.bat     (本体)
 └─ Src\Systems\Debug\ReturnCodeConst.bat (定数群)（将来的にRCS_Const.batとして一新予定）
 └─ Config\Logs\                         (出力ディレクトリ)
```

### 主な関数一覧

| ラベル       | 機能      | 出力    | 備考                     |
| --------- | ------- | ----- | ---------------------- |
| `-build`  | 8桁コード生成 | 非表示   | SDDRRCCCを算出し数値返却       |
| `-decode` | コード分解   | 非表示   | rcs\_s/dd/rr/ccc 変数へ展開 |
| `-return` | 正常終了処理  | サイレント | traceに転送・exit /b code  |
| `-throw`  | 例外処理    | サイレント | ログのみ書込、stderr出力廃止      |
| `-trace`  | ログ出力    | サイレント | すべてConfig\Logsに集約出力    |
| `-pretty` | 整形表示    | 表示あり  | 人間可読確認用。ログには残さない       |
| `-help`   | コマンド説明  | 表示あり  | 明示呼出時のみ表示              |

---

## 4. サイレントログ仕様（v0.3a 方針）

| 対象                     | コンソール出力 | ログ出力 | 理由             |
| ---------------------- | ------- | ---- | -------------- |
| trace / throw / return | ❌ 無     | ✅ 有  | 実行時ノイズを排除、UX改善 |
| pretty / help          | ✅ 有     | ❌ 無  | デバッグ・確認専用機能    |

### ログフォーマット

```
[YYYY-MM-DD_HH:MM:SS.fff] [LEVEL] [MODULE] message
```

### 出力先例

- メインログ：`Config\Logs\AstralDivide_Session_YYYY-MM-DD.log`
- エラーログ：`Config\Logs\AstralDivide_Error_YYYY-MM-DD.log`

---

## 5. 旧RECS v1 → RCS v0.3a 機能移行表

| 機能名               | 旧\:ReturnCodeUtil | 新\:RCS\_Util  | 状態    |
| ----------------- | ----------------- | ------------- | ----- |
| コード構築 (`-build`)  | 同等機能              | 改良・簡潔化        | ✅ 完了  |
| コード分解 (`-decode`) | 同等                | 改良            | ✅ 完了  |
| 例外送出 (`-throw`)   | stderr出力＋ログ       | ログのみ（静音）      | ✅ 改良  |
| 戻り値返却 (`-return`) | exit /b のみ        | trace呼出＋返却    | ✅ 改良  |
| 整形出力 (`-pretty`)  | 部分的表示             | 改良（色対応）       | ✅ 継承  |
| トレースログ (`-trace`) | モジュール別ファイル多数      | 統合出力1～2ファイル   | ✅ 改良  |
| ログローテーション         | 有り                | 一時削除（後日再実装予定） | ⚠ 未対応 |
| ctx（呼出元情報）        | 有り                | 廃止（冗長）        | 🚫 削除 |

---

## 6. 命名・変数ポリシー

| 種別     | 命名規則        | 例                                    |
| ------ | ----------- | ------------------------------------ |
| コマンド   | 小文字統一       | `call rcs_util -trace ...`           |
| 変数     | snake\_case | `runtime_ipc_dir`, `config_logs_dir` |
| 定数     | 大文字＋アンダースコア | `RCS_LOG_FILE`, `RCS_LOG_DIR`        |
| デバッグ変数 | 全大文字        | `RC_LAST`, `RCS_EXIT`                |

---

## 7. 運用フロー

```
AstralDivide.bat  (配布用起動ファイル)
   ↓
Run.bat  (Launcher)
   ├─ RCS bootstrap
   │    ├─ RCS_Util存在確認
   │    ├─ ReturnCodeConst読込
   │    └─ RC_OK定義
   │
   └─ Main.bat 実行
```

初回起動時に RCSU/Const が存在しない場合は `FailRun` へ遷移し、 共通エラー `90610001`（Systems / I/O / case001）を発行する。

---

## 8. 今後の展望

- **v0.4.x:** Codex連携 / RCS\_ERROR\_CODE.md 自動生成連動
- **v1.0:** RCSをAstralDivide Coreモジュールとして統合。Bootstrapから直接リンク。
- **vFuture:** Pretty出力のJSON形式拡張、マルチスレッド対応検討（cmdgfx統合時）

---

## 9. 総評

RCS v0.3aは、旧来のReturnCodeUtilの冗長性を完全排除し、 ログ・戻り値・例外の三本柱を分離・明文化した初の安定版である。\
開発者の理念「**黙って記録し、必要な時だけ語る**」を体現する構造となった。

> **RCS Philosophy:**
>
> - “Trace everything, but display nothing.”
> - “Human-readable only when needed.”

---

**End of Document – RCS Protocol v0.3a**

