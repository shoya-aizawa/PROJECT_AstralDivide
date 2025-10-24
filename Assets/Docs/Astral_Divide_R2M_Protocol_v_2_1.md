# Astral Divide Run-To-Main Protocol (R2M) v1.0

**Project:** PROJECT_AstralDivide / HedgeHogSoft  
**Subsystem:** Process Synchronization & Verification  
**Author:** 愛澤翔也 (HedgeHog)  
**Date:** 2025-10-23  
**Status:** Stable Draft

---

## 1. 概要

`Run-To-Main Protocol`（R2M）は、`Run.bat`（ランチャー兼監督プロセス）と `Main.bat`（ゲーム本体）間の**相互監視・相互認証・状態連携**を規定するプロトコルである。  
本プロトコルは Astral Divide システム全体における **RCS（Return Code System）**, **RVP（Rendezvous Point）**, **Interception Protocol**, **Security Signature Check** 等と連携し、実行階層間の完全な同期性を保証する。

---

## 2. 目的
- **Run ⇔ Main 間の信頼通信を定義**する。  
- **RCSを共通言語として統一**し、すべての戻り値・エラーを一貫して扱う。  
- **異常時の即時停止（Fail-Fast）と自己修復（Fail-Soft）**を両立。  
- **プロセス間の監視責務を分離**し、再入防止・二重起動・環境破損を防ぐ。

---

## 3. システム構造

```
[ L1 ] AstralDivide.bat (Launcher/UI entry)
        │  defines PROJECT_ROOT + GAME_LAUNCHER token
        ▼
[ L2 ] Run.bat (Supervisor / Watchdog)
        │  RCS bootstrap, signature verify, environment check
        ▼
[ L3 ] Main.bat (Game Core)
        │  performs game logic, responds to R2M signals
        ▼
[ L4 ] RVP / Interception (Debug or Dev Layer)
```

---

## 4. プロトコル構成概要

### 4.1 起動フェーズ (Boot Phase)
1. **Launcher Token Verification**  
   - Run.bat 起動時に `GAME_LAUNCHER` が未定義なら、直叩き検知。
   - → `AD_RC = 9-06-30-010`（ERR / Systems / Validation）
2. **PROJECT_ROOT Fail-Safe**  
   - `if not defined PROJECT_ROOT` → エラー `9-06-10-001`
3. **RCS Bootstrap**  
   - `RCS_Util.bat` + `RCS_Const.bat` 読込、セッションログ生成。
4. **Signature Verification**  
   - `Src/Systems/Security/VerifySignatures.bat` によりデータ改ざん検知。
5. **Main.bat Launch**  
   - `call "%PROJECT_ROOT%\Src\Main\Main.bat"`

---

### 4.2 実行フェーズ (R2M Active Phase)

| 項目 | Run.bat の責務 | Main.bat の責務 |
|------|----------------|----------------|
| **プロセス状態管理** | Main の PID 監視、終了コード解析 | 自身のステータスをRCSで返却 |
| **RVP連携** | Rendezvousファイルの生成・監視 | RVP到達時に現在状態を記録 |
| **エラー伝搬** | RCS経由でMainから受領したコードをログ化 | `exit /b %AD_RC%` によりRunへ伝達 |
| **通信ファイル** | `.rendezvous`, `.command`, `.status` | 同名ファイルに応答を出力 |
| **ログ管理** | `Config\Logs\AstralDivide_Session_*.log` | サブプロセス側もRCS出力に従う |

---

### 4.3 終了フェーズ (Termination)
- Run は Main の終了コード (`errorlevel`) を取得。  
- RCSコードをデコードしてログに残す。  
- 致命エラー（S=9）の場合、**再試行・リカバリ**を実行せず即停止。  
- 正常終了（S=1）またはキャンセル（S=8）の場合、セッションをクリーンアップして終了。

---

## 5. 認証・監視機構

### 5.1 トークン認証
| 変数名 | 発行者 | 用途 | 説明 |
|--------|--------|------|------|
| `GAME_LAUNCHER` | AstralDivide.bat | 起動トークン | 正規経路起動を識別。未定義ならRunは停止。 |
| `PROJECT_ROOT` | AstralDivide.bat | ルートディレクトリ | すべてのモジュール呼び出しに使用。 |

### 5.2 RCS統合
- すべての戻り値・エラーは RCSフォーマット（S-DD-RR-CCC）で統一。  
- Run ⇔ Main 間通信にも `RCS_Util.bat` を介して数値一元管理。

### 5.3 RVP (Rendezvous Point)
- Mainが特定ラベル到達時に `.rendezvous` ファイルを生成。  
- Runはそれを監視し、状態変化をログに記録。

### 5.4 Interception Protocol 連携
- Devモードで `MODE=INTERCEPT` 時、Runは `.command.in` 経由で指令を送信。  
- Mainは受信・応答・一時停止・再開を行う。

---

## 6. 例外処理フロー

| 状況 | 発生モジュール | 対応 | 返却コード例 |
|------|----------------|------|--------------|
| Run直叩き | Run.bat | 実行拒否＋メッセージ表示 | `9-06-30-010` |
| PROJECT_ROOT未定義 | Run.bat | Fail-Fast停止 | `9-06-10-001` |
| Main起動失敗 | Run.bat | エラーログ出力 | `9-06-10-002` |
| RCS読込失敗 | Run.bat | 即時終了 | `9-06-10-003` |
| Signature検証失敗 | Run.bat | データ破損エラー | `9-06-30-021` |
| Main側例外終了 | Main.bat | RCSコード返却 | 任意（S=9系） |

---

## 7. ログ・RCS出力仕様

```
[2025-10-23 13:40:01.125] [INFO] R2M Boot Start
[2025-10-23 13:40:02.452] [OK] Main started successfully RC=10101001
[2025-10-23 13:40:03.011] [TRACE] RVP_MENU_SELECTED_START detected
[2025-10-23 13:40:05.222] [ERR] PROJECT_ROOT undefined RC=90610001
```

- すべてのレコードは `Config\Logs\AstralDivide_Session_*.log` に統合。  
- `AD_RC` / `AD_RC_TAG` / `AD_RC_MSG` も併記可能。

---

## 8. 今後の拡張
| バージョン | 機能予定 |
|-------------|-----------|
| v1.1 | RVPを多層化し、シーン単位での同期（SceneRVP）を導入。 |
| v1.2 | IPCフォルダの自動クリーンアップ・セッションキャッシュ管理。 |
| v1.3 | Signature Protocol v2（オンライン署名鍵対応）。 |
| v2.0 | Codex統合によるR2Mログのメタ解析・再生可能リプレイ化。 |

---

## Appendix A: Pre-R2M Layer (Launcher Authentication)

この層は `AstralDivide.bat → Run.bat` 間の **ユーザー起動経路** を定義し、R2Mプロトコルの**前提条件**として動作する。

### A.1 Launch Token Validation
- AstralDivide.bat にて `set "GAME_LAUNCHER=1"` を発行。
- Run.bat はこのトークンを確認し、未定義なら直叩き検知として停止。

### A.2 PROJECT_ROOT Fail-Safe
- AstralDivide.bat で `PROJECT_ROOT` を定義。Run.bat 起動時に再検証。
- 未定義時には再定義を試行し、失敗時に `9-06-10-001` を発行。

### A.3 UX設計指針
- ユーザーが誤って `Run.bat` を実行した場合は、次のようなメッセージを表示：
  ```
  [ERROR] Direct execution detected.
  Please launch the game using "AstralDivide.bat".
  ```
- 開発中のみ `DEBUG_MODE=1` により直叩きを許可可能。

---

**End of Document – Astral Divide R2M Protocol v1.0**

