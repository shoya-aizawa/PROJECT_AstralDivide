# Astral Divide — Run→Main Protocol (R2M) v2.2

**Project:** PROJECT_AstralDivide (HedgeHogSoft)  
**Developer:** 愛澤翔也 (HedgeHog)  
**Doc Type:** Implementation Standard / .md  
**Status:** Stable Release (Adopted)  
**Date:** 2026-05-31  

---

## 1. 概要（Purpose）

R2M（Run-To-Main Protocol）は、**Run.bat（Launcher兼監視プロセス）→ Main.bat（Game Core）** の起動フロー、環境変数継承、および終了コードの同期検証を規定するプロトコルである。

本バージョン（v2.2）は、以下の最新機能と動作実績を包含する：

- **デバッグ起動モード (`-mode debug`)**:
  VSCode等の統合ターミナルでの動作を考慮し、起動時のウィンドウ多重起動回避（`start cmd /c`）をバイパス。さらに `Main.bat` の呼び出しを `start` から `CALL` に切り替え、同一コンソール上でデバッグ可能な環境を提供。
- **リモートデバッグモード (`-mode remote`)**:
  起動引数に `-mode remote` が指定された場合、セッションログ（`Config\Logs\AstralDivide_Session_*.log`）を自動検出し、バックグラウンドタスクとして `LogTailToGAS.ps1` を起動。Google Apps Script (GAS) へリアルタイムでログをテール転送する。
- **親シェルスコープへの自動エクスポート（自己修復・最適化）**:
  `Splash.bat` にてすべてのプロファイル判定、環境構築、画面サイズ計算を非同期ローディングアニメーションと同期して実行。完了後、親シェルスコープ内で `LoadEnv.bat` および `SettingPath.bat` をサイレントに実行することで、RCS定数や各種パス環境変数を完全にロード。

---

## 2. スコープ & 構成要素

```
Platform [Windows 10/11 CMD (conhost.exe / Windows Terminal)]
  │
  ▼  set "GAME_LAUNCHER=1" & call Run.bat
[ L1 ] Launcher (Run.bat)
  │   - ブートストラップ (RCS_Util.bat / RCS_Const.bat ロード)
  │   - 起動モード解析 (run / debug / intercept / remote / remoteadmin)
  │   - Splash.bat 同期起動
  │   - 親スコープへ環境変数・RCS定数をサイレントエクスポート
  │
  ├─► [ L2 ] Main Game Core (Main.bat)
  │     - 実行モード: CALL (debug時) / start /d (通常時)
  │     - エコー/ログ: RCS_Util.bat 経由のサイレント記録
  │
  └─► [ L3 ] Watchdog Subsystem (Watchdog_Host.bat)
        - 実行モード: CALL 同期監視 (通常時のみ / debug時はバイパス)
        - 役割: クライアントプロセスの死活監視HUD、緊急シャットダウンシグナル受け手
```

---

## 3. モード別動作仕様

R2M v2.2 は起動引数によって以下のモードに分岐する。

| 起動モード | 指定方法 | ウィンドウ制御 | Watchdog | ログ転送 | 用途 |
|---|---|---|---|---|---|
| **RUN (通常)** | なし | 新ウィンドウで起動 (`start`) | ✅ 同期常駐 (`call`) | ❌ ローカルのみ | 配布パッケージ用 (Release) |
| **DEBUG (開発)** | `-mode debug` | 同一ウィンドウ内で実行 (`CALL`) | ❌ バイパス | ❌ ローカルのみ | VSCode等での構文エラー診断用 |
| **INTERCEPT** | `-mode intercept` | 新ウィンドウで起動 (`start`) | ✅ 同期常駐 (`call`) | ❌ ローカルのみ | RVP/フックデバッグ用 |
| **REMOTE (リモート)** | `-mode remote` | 新ウィンドウで起動 (`start`) | ✅ 同期常駐 (`call`) | ✅ GASリアルタイム転送 | リモートプレイ検証用 |

---

## 4. プロセス間データ連携契約

### 4.1 Run.bat の責務（親プロセス）
1. **Launch Token 発行**: `GAME_LAUNCHER=1` を親シェルに設定し、`Run.bat` の直叩きを防止。
2. **RCS ブートストラップ**: `RCS_Util.bat` および `RCS_Const.bat` が存在することを確認し、欠損時は即時安全停止（Fail-Fast）。
3. **プロファイル・パスのロード**: Splash画面がプロファイルと環境変数ファイルを確定させた後、親シェルスコープでサイレントにロード。
   - `%PROJECT_ROOT%\Config\user_config.env` -> `LoadEnv.bat`
   - `%PROJECT_ROOT%\Src\Systems\Environment\SettingPath.bat`

### 4.2 Main.bat の責務（子プロセス）
1. **引数チェック**: 第一引数として受け取るコードページ（`65001` = UTF-8）を検証。不一致時は `exit /b 1` で安全停止。
2. **状態トラッキング**: メインメニュー、セーブデータ選択などの重要UI遷移点で、`RCS_Util.bat -trace` を用いてログをサイレント追記。
3. **リターンコード伝搬**: 終了時に `exit /b 0` または適切な RCS コードを返却。

### 4.3 リモートログ転送 (`LogTailToGAS.ps1`)
`-mode remote` 起動時、`Run.bat` は以下のパラメータを渡してPowerShellプロセスを非同期起動（`/b`）する。
- `-LogPath` : `Config\Logs\AstralDivide_Session_YYYY-MM-DD.log`
- `-GasUrl` : `user_config.env` またはデフォルトで定義されたGAS WebApp URL
- `-SessionToken` : リモートセッション確立用のトークンコード

---

## 5. エラーハンドリングと例外処理

RCSコード（`S-DD-RR-CCC`）に基づき、以下のFail-Fast（即時安全停止）ポリシーを適用する。

- **RCS関連ファイル欠損**: `90610001` (ERR / Systems / I/O / case001) または `90610002` を返して終了。
- **環境パス設定失敗**: `SettingPath.bat` の終了コードが `RC_OK (10690000)` 以外の場合、`FailFirstRun` へ遷移して警告UIを表示。
- **デバッグログのコンソール出力制限**: コンソールへの出力は `-pretty` またはエラー発生時（`-throw`）のHUD警告に限定し、通常のログ追記（`-trace`）はコンソールノイズを徹底排除する。

---

## 6. 実装整合性チェックリスト

- [x] `AstralDivide.bat` にて `GAME_LAUNCHER=1` が定義されている
- [x] `Run.bat` は `-mode debug` を検知し、多重起動回避 (`start cmd /c`) をバイパスする
- [x] `Run.bat` の `Main.bat` 呼び出しが、デバッグモードでは `CALL`、通常モードでは `start` に分岐する
- [x] `Splash.bat` 完了後のパス・環境変数ロードが `SILENT` 引数付きで二重ログを抑止している
- [x] `-mode remote` 時、`LogTailToGAS.ps1` がバックグラウンドタスクとしてログディレクトリ/ファイルを事前生成した上でテール転送を開始する

---

**End of Document – R2M Protocol Specification v2.2**
