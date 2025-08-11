# Astral Divide — インターセプト / ランデブーポイント仕様書 (RVP Spec v1)

**作者**: HedgeHog (愛澤翔也)  
**プロジェクト**: PROJECT_AstralDivide / HedgeHogSoft  
**対象**: `Run.bat`（ホスト）と `Main.bat`（ゲーム本体）間の双方向通信・拡張フレームワーク  
**バージョン**: v1.0  
**最終更新**: 2025-08-09 (JST)

---

## 0. 目的と概要
本仕様は、`Run.bat`（ホスト）↔ `Main.bat`（クライアント）間の**インターセプトモード**を「汎用フック層」として定義する。ゲーム内に**ランデブーポイント（RVP: Rendezvous Point）**を設置し、実行時イベントを外部プロセス（ホスト）へ通知、必要に応じて**指示（コマンド）**を受け取り、ゲーム挙動を制御・拡張する。

### できること（ユースケース）
1. ~~リアルタイムチュートリアル/ヘルプ: 初回操作や連続失敗を検知し、ヒント/デモ入力を注入。~~
2. **テレメトリ/計測**: 戦闘・分岐・入出力などをNDJSONとして収集、後解析。
3. **ダイナミック難易度調整（DDA）**: 直近戦績に応じたパラメータ微調整（敵HP/ドロップ等）。
4. **セキュリティ/チート検知**: 重要値の不変条件/署名検証違反を即時検出し警告・中断。
5. **モッディングAPI**: イベントごとの外部プラグインに処理を委譲し、UI/挙動を拡張。
6. **収録/リプレイ**: 入力・分岐・RNGを記録し、後で自動再生。

> 重要: **INTERCEPTモードが無効でもゲームは単独で完結**すること。RVPは“あると便利な拡張口”であり、必須依存を避ける。

---

## 1. 用語
- **ホスト（Host）**: Run側の常駐ループ。RVPイベントを受け取りプラグインへディスパッチ。
- **クライアント（Client）**: Main側のゲーム本体。RVPユーティリティを呼ぶ。
- **RVPイベント**: Main→Run へ送る「起きたこと」の通知。ファイル単位。
- **ACK/応答**: Run→Main への「どうしてほしい」の指示。単一ファイル。
- **プラグイン**: Hostにぶら下がる処理単位（BAT/PS1）。イベントごとに判断/指示を返す。

---

## 2. ディレクトリ構成（推奨）
```
AstralDivide(root)
├─ Src
│  ├─ Main
│  │   ├─ Main.bat
│  │   └─ Run.bat               ← 司令塔（薄い）
│  └─ Systems
│      ├─ Debug
│      │   ├─ RVP.bat           ← Main側ユーティリティ（送受）
│      │   ├─ Watchdog_Host.bat ← Run側常駐（ディスパッチ）
│      │   └─ Plugins
│      │        ├─ 10_Tutorial.bat
│      │        ├─ 20_Telemetry.bat
│      │        ├─ 30_DDA.bat
│      │        ├─ 40_Security.bat
│      │        ├─ 50_Modding.bat
│      │        └─ 60_Replay.bat
│      └─ Environment ...
└─ Runtime
   └─ ipc
      ├─ .mode                ← INTERCEPT / NORMAL
      ├─ events\*.rvp        ← Main→Run 単発イベント
      ├─ replies\*.ack       ← Run→Main 応答
      ├─ logs\*.ndjson       ← テレメトリ/監査
      └─ state\*.vars        ← 状態（DDA等）
```

---

## 3. 起動モードとフェールセーフ
- `Runtime\ipc\.mode` が `INTERCEPT` の場合のみRVP有効。無ければ **無条件でNo-Op**（Mainは即時復帰）。
- Hostが未起動でも、Mainは**タイムアウト（既定: ~100ms）**で継続。
- 例外/不正応答時: Mainは応答を破棄して続行（安全第一）。

---

## 4. IPCファイル仕様

### 4.1 RVPイベントファイル（Main→Run）
- 置き場所: `Runtime/ipc/events/{TS}_{EVT}.rvp`
- 形式: **key=value** を1行ずつ（PSが使える環境ではJSON併用可）。
- 最低フィールド:
  ```
  EVT=BEFORE_BATTLE
  SCENE=02_Episode01
  NODE=Battle#SlimeHill
  PLAYER=Shoya
  CTX=hp=34/mp=10;retry=0;input_fail=0
  TS=20250809_014215_123    ; 任意、無ければHostが補完
  ```

### 4.2 ACK応答ファイル（Run→Main）
- 置き場所: `Runtime/ipc/replies/{同名TS}_{EVT}.ack`
- 形式: **key=value** を1行ずつ。
- フィールド:
  ```
  ACTION=SHOW_HINT | PATCH | DEMO_INPUT | LOG_ONLY | ABORT
  PAYLOAD=...  ; 内容はACTIONごとに異なる
  TTL_MS=5000  ; 有効期間（ms）。期限切れは無視
  ```

### 4.3 ログ/状態
- `logs/*.ndjson`: テレメトリ（1イベント1行のJSON）。
- `state/*.vars`: `KEY=VALUE` の簡易KVS（DDA等の内部状態）。

---

## 5. イベント種別（案 / v1凍結）
- **コア**
  - `BEFORE_BATTLE`, `AFTER_BATTLE`
  - `OPEN_MENU`, `CLOSE_MENU`（`NODE=Inventory/Status/...`）
  - `SAVE`, `LOAD`
  - `SCENE_ENTER`, `SCENE_EXIT`
  - `CHOICE`, `INPUT`, `RNG`
  - `TICK_BATTLE`, `TICK_OVERWORLD`
  - `ERROR`（`CTX=code=xxxx;msg=...`）
- **観測値/CTXキー例**（必要に応じて任意拡張可）
  - `hp`, `maxhp`, `mp`, `gold`, `retry`, `input_fail`, `sig_ok`
  - `enemy_id`, `enemy_hp`, `enemy_atk`, `drop_rate`

> 命名は **UPPER_SNAKE** を基本。`NODE` は `領域#識別子` の複合が推奨。

---

## 6. Host（Run側）動作仕様

### 6.1 ディスパッチ順序と優先度
1. `40_Security.bat`（最優先）
2. `30_DDA.bat`
3. `10_Tutorial.bat`
4. `50_Modding.bat`
5. `60_Replay.bat`
6. `20_Telemetry.bat`（常時・最後）

> 最初に `ACTION` をセットしたプラグインの応答を採用（`PAYLOAD`/`TTL_MS` とともにACK作成）。何も応答しない場合はACK無しでイベント消化。

### 6.2 Rate Limit / TTL
- 同一`EVT`への**連続指示は最短500ms間隔**（既定値）
- `TTL_MS` 経過後に受け取ったACKは**破棄**。

### 6.3 エラーハンドリング
- プラグイン内エラーはHostが握りつぶし、ログにのみ出力。
- 破損イベント/欠損フィールドは `ERROR` として `logs/` へ記録して廃棄。

---

## 7. Main（クライアント）側 API

### 7.1 RVPユーティリティ呼び出し（疑似）
```bat
:: Systems\Debug\RVP.bat を想定
:: 使い方:
::   set "SCENE_ID=02_Episode01" & set "NODE_ID=Battle#SlimeHill"
::   call RVP.bat EVT BEFORE_BATTLE CTX "hp=!hp!;retry=!retry!"
::   if /i "%RVP_ACTION%"=="SHOW_HINT" call :ShowHint "%RVP_MSG%"
::   if /i "%RVP_ACTION%"=="PATCH"     call :ApplyPatch "%RVP_PATCH%"
::   set "RVP_ACTION=" & set "RVP_MSG=" & set "RVP_PATCH="
```

### 7.2 ACTION種別と期待挙動
- `SHOW_HINT`: 文字列（`PAYLOAD`）をタイプライタ/吹き出しでNミリ秒表示。
- `DEMO_INPUT`: `PAYLOAD` に応じて**一時的に入力フック**を差替え（例: `KeySeq:DOWN,ENTER`）。
- `PATCH`: ゲーム変数への**限定的変更**（§8）。
- `LOG_ONLY`: 挙動変更なし（記録のみ）。
- `ABORT`: 現在の処理を即時中断（例: 戦闘や演出をスキップ/タイトルへ）。

### 7.3 タイムアウト
- `ACK` が所定時間内に見つからない場合は**何もせず復帰**。

---

## 8. PATCH命令仕様（Main側で厳格適用）

### 8.1 文法（BNF 風）
```
<patch>   ::= <stmt> ( ";" <stmt> )*
<stmt>    ::= <path> <op> <value>
<op>      ::= "=" | "+=" | "-="
<path>    ::= <token> ( "." <token> )*
<token>   ::= a-zA-Z0-9_+
<value>   ::= [-]?[0-9]+ | <percent>
<percent> ::= [0-9]+"%"   ; Main側で実数化して丸め（必要なら無効化）
```

### 8.2 ホワイトリスト（例 / v1）
- `enemy.hp`, `enemy.atk`, `enemy.def`, `drop.rate`, `player.recv_damage`
- **上記以外は無視**。値域チェック: 例 `hp ∈ [1, 9999]`, `drop.rate ∈ [0,100]`。

### 8.3 例
```
PATCH = "enemy.hp-=10;drop.rate+=5"
```

---

## 9. プラグイン API（Host→各プラグイン）

### 9.1 受け渡し環境変数（入力）
- `EVT`, `SCENE`, `NODE`, `PLAYER`, `CTX`, `TS`
- ホスト内部状態（任意）: `WINRATE`, `RECENT_DMG`, など `state/*.vars` に保存し `set` で渡す

### 9.2 応答（出力）
- `ACTION` / `PAYLOAD` / `TTL_MS`

### 9.3 プラグインのサンプル
**Tutorial**
```bat
@echo off
if /i "%EVT%"=="OPEN_MENU" if /i "%NODE%"=="Inventory" (
  echo %CTX% | find "first_time=1" >nul && (
    set "ACTION=SHOW_HINT"
    set "PAYLOAD={blue}アイテムは [R] で並び替え{/blue}"
    set "TTL_MS=4000"
  )
)
```

**Telemetry**
```bat
@echo off
set "LG=%IPC%\logs"
>>"%LG%\telemetry.ndjson" echo {"ts":"%date%T%time%","evt":"%EVT%","scene":"%SCENE%","node":"%NODE%","ctx":"%CTX%"}
```

**DDA**
```bat
@echo off
if /i "%EVT%"=="BEFORE_BATTLE" (
  call :load
  if %WINRATE% LSS 40 (
    set "ACTION=PATCH" & set "PAYLOAD=enemy.hp-=10;drop.rate+=5" & set "TTL_MS=1000"
  )
)
exit /b
:load
for /f "usebackq tokens=1,2 delims==" %%A in (`type "%IPC%\state\dda.vars" 2^>nul`) do set "%%A=%%B"
exit /b
```

**Security**
```bat
@echo off
if /i "%EVT%"=="TICK_BATTLE" (
  for %%K in (hp maxhp delta_gold sig_ok) do call :kv "%%K"
  if "%sig_ok%"=="0" (set "ACTION=ABORT" & set "PAYLOAD=SIG_FAIL")
  if %hp% GTR %maxhp% (set "ACTION=ABORT" & set "PAYLOAD=HP_OVERFLOW")
)
exit /b
:kv
for /f "tokens=2 delims==" %%v in ('echo %CTX% ^| findstr /i "\<%~1="') do set "%~1=%%v"
exit /b
```

**Replay（収録）**
```bat
@echo off
if /i "%EVT%"=="INPUT" >>"%IPC%\logs\replay_%PLAYER%.log" echo %TS% INPUT %CTX%
```

---

## 10. リターン/エラーコード運用（AD_RC v1準拠）
本仕様で扱う**すべての戻り値**は、別紙 **“Astral Divide Return/Error Code Standard (v1)”** に定義された **AD_RC (8桁: `S DD RR CCC`)** を用いる。数値は原則として **ハードコードせず、`rcutil.bat` などのユーティリティで生成**する。

- **S（種別）**: `1=FLOW`（正常フロー）、`2=CANCEL`（設計上の中断/ユーザーキャンセル）、`9=ERR`（異常）
- **DD（ドメイン）**: Run/Intercept系は以下を主に使用する（詳細は標準書に従う）。
  - `06=Systems/Core` … LaunchGuard/Bootstrap/Env_Probe/GameStart など起動系
  - `09=Debug/Intercept` … Watchdog/Host、RVP、プラグイン層
- **RR（理由）**: 代表例 `10=I/O`, `11=Parse`, `20=NotFound`, `30=Validation`, `40=Timeout`, `50=Compat`, `90=Other`
- **CCC（詳細ID）**: 0–999。処理単位やスロット番号等に割当可。

### 10.1 Run/Intercept の返却方針
- **LaunchGuard**（直叩き/引数不正等）: `DD=06` + `RR=30(Validation)` + 適切な `CCC`
- **Bootstrap**（profile.env 読込/作成/保存）: `DD=06` + `RR=10(I/O)` or `11(Parse)`
- **Env_Probe**（PS不可/画面検出/VT設定）: `DD=06` + `RR=50(Compat)` or `30(Validation)`
- **GameStart**（Main 起動不能/未検出/異常終了）: `DD=06` + `RR=20(NotFound)` or `10(I/O)`
- **Watchdog/Host**（IPC 初期化/応答不整合/署名不正）: `DD=09` + `RR=10/30/50` を状況に応じて選択

> 具体的な 8桁コードは **`rcutil.bat` のマクロ/関数**で生成し、ログには `AD_RC`（例: `90630001`）と付帯メタ（`AD_RC_KIND`, `AD_RC_TAG` 等）を併記すること。

### 10.2 透過と記録
- **Main 側が返す AD_RC は、そのまま Run の終了コードとして透過**する（親→子→親の一貫性維持）。
- すべての返却点で **`AD_RC` を環境変数にも設定**し、`Runtime/ipc/logs/*.ndjson` に記録する。

---

## 11. セキュリティ/安全装置 セキュリティ/安全装置
- **ホワイトリスト**: PATCH対象・キーを明示列挙。未知キーは無視。
- **値域チェック**: 上下限・型検証。過大値は丸め/破棄。
- **レートリミット**: 同一EVTの連発制御（500ms）。
- **TTL**: 応答の期限切れは破棄。
- **モード切替**: `.mode != INTERCEPT` ならRVP無効（性能劣化なし）。
- **監査ログ**: セキュリティ関連は `logs/security.ndjson` に二重記録。

---

## 12. パフォーマンス考慮
- ファイルベースIPCのため、**イベント粒度は「ポイント」単位**（毎フレームは避ける）。
- 重いプラグインは**非同期/バッファ**処理（Telemetryまとめ書き等）。
- タイムアウトは**~100ms**を目安に、ゲーム体験を阻害しない。

---

## 13. 移行手順（MVP）
1. `RVP.bat` を作成し、**主要ポイント**（メニュー開閉/戦闘開始終了/セーブ）へ差し込む。
2. `Watchdog_Host.bat` + `20_Telemetry.bat` を導入（**読むだけ**）。
3. `10_Tutorial.bat` を1–2トリガーで試験。
4. `30_DDA.bat` を **READ専用**で先行→後にPATCH解禁。
5. `40_Security.bat` を LOG_ONLY→警告→ABORT の段階導入。
6. `60_Replay.bat` は入力/分岐の記録から開始。

---

## 14. テスト観点
- **直叩き防止**: Run単体起動で `0001` 返却。
- **初回起動**: `Config/profile.env` 未存在→作成/自己修復。
- **PS無し環境**: `POWERSHELL_AVAILABLE=0` でフォールバック動作。
- **画面差分**: ScreenEnvironmentDetectionによる切替が記録される。
- **デバッグON**: `.mode=INTERCEPT` でACK往復/注入確認。
- **戻り値透過**: Mainの `2051` 等がRunの`exit /b`へ反映。

---

## 15. 将来拡張（v1以降）
- **高速IPC**: 名前付きパイプ/クリップボード/WSLブリッジ等の研究。
- **スキーマ**: RVPイベントのJSONスキーマと検証器。
- **署名**: イベント/ACK双方にHMACを付与（改竄検知）。
- **プラグインマニフェスト**: 権限（READ/WRITE）/対応EVTを宣言。
- **UI統合**: SHOW_HINTのテーマ/位置/優先度をタグ化（RenderMarkup連携）。

---

## 付録A: 参考コード断片

### A-1. Host骨格（Watchdog_Host.bat）
```bat
@echo off & setlocal EnableDelayedExpansion
set "ROOT=%~dp0..\..\.."
set "IPC=%ROOT%\Runtime\ipc"
set "EV=%IPC%\events"
set "RP=%IPC%\replies"
set "LG=%IPC%\logs"
if not exist "%RP%" md "%RP%"
if not exist "%LG%" md "%LG%"

:loop
for %%F in ("%EV%\*.rvp") do call :handle "%%~fF"
timeout /t 0 >nul
goto :loop

:handle
set "F=%~1"
for /f "usebackq tokens=1,* delims==" %%A in (`type "%F%"`) do set "%%A=%%B"
for %%P in ("%~dp0Plugins\*.bat") do (
  call "%%~fP"
  if defined ACTION goto respond
)
:: Telemetryは常時
call "%~dp0Plugins\20_Telemetry.bat"
goto cleanup

:respond
(
  echo ACTION=%ACTION%
  echo PAYLOAD=%PAYLOAD%
  echo TTL_MS=%TTL_MS%
)> "%RP%\%~nF.ack"
set ACTION=&set PAYLOAD=&set TTL_MS=

:cleanup
del "%F%" >nul 2>&1
exit /b
```

### A-2. Main側RVPユーティリティ（RVP.bat, 抜粋）
```bat
@echo off & setlocal enabledelayedexpansion
set "IPC=%~dp0..\..\..\Runtime\ipc"
set "EVT=%~2" & set "CTX=%~4"
for /f %%a in ('powershell -NoLogo -c "(Get-Date).ToString(\"yyyyMMdd_HHmmss_fff\")" 2^>nul') do set "TS=%%a"
if not defined TS set "TS=%date:~0,10%_%time: =0_%random%"
set "EVTFILE=%IPC%\events\%TS%_%EVT%.rvp"
(
  echo EVT=%EVT%
  echo SCENE=%SCENE_ID%
  echo NODE=%NODE_ID%
  echo PLAYER=%PLAYER_NAME%
  echo CTX=%CTX%
  echo TS=%TS%
)> "%EVTFILE%"

set "ACK=%IPC%\replies\%TS%_%EVT%.ack"
set /a wait=0
:__wait
if exist "%ACK%" goto __got
if %wait% geq 10 goto __timeout
cmd /c "exit /b 0" >nul & set /a wait+=1 & goto __wait

:__timeout
endlocal & exit /b 0

:__got
for /f "usebackq delims=" %%L in ("%ACK%") do set "%%L"
del "%ACK%" >nul 2>&1
endlocal & (
  if /i "%ACTION%"=="SHOW_HINT" (set "RVP_ACTION=SHOW_HINT" & set "RVP_MSG=%PAYLOAD%")
  if /i "%ACTION%"=="PATCH"     (set "RVP_ACTION=PATCH"     & set "RVP_PATCH=%PAYLOAD%")
  if /i "%ACTION%"=="DEMO_INPUT"(set "RVP_ACTION=DEMO_INPUT"& set "RVP_KEYS=%PAYLOAD%")
  if /i "%ACTION%"=="ABORT"     (set "RVP_ACTION=ABORT")
)
exit /b 0
```

---

## 付録B: ライセンス/著作権
- 本仕様書は PROJECT_AstralDivide の内部設計資料。外部公開時はプロジェクトのライセンス/規約に従う。

---

**この.mdを別セッションで読み込めば、同じ設計前提で会話を継続可能**。必要に応じて v1.1 以降へ追補（PATCHキーの追加・イベント定義の確定・セキュア化方針など）を行うこと。


---

## 16. 運用モードとセキュリティ：ヒントと INTERCEPT の切り分け

### 16.1 結論（要点）
- **ヒント表示は“ゲーム機能”**。**デバッグ起動とは無関係**に動作させる。
- **INTERCEPT（RVP 注入）は別軸の“拡張フラグ”**。配布ビルドでは既定で OFF。
- Watchdog は **全モード常駐**。`INTERCEPT=OFF` のときは **センチネル（見張りのみ）**。

### 16.2 フラグ設計（内部）
```
BUILD_PROFILE = release | dev    ; ログ/アサート/診断の深さ
INTERCEPT_MODE = 0 | 1          ; RVP/プラグイン注入の可否
FEATURE_HINTS = 1               ; ローカル（Mainのみ）ヒント機能の有効
ALLOW_REMOTE_HINTS = 0|1        ; Host経由ヒント注入の許可（既定 0）
```
- 外部からは3モード UI を維持：`RUN / DEBUG / INTERCEPT`。
  - **RUN** → `release + INTERCEPT=0`（本番）
  - **DEBUG** → `dev + INTERCEPT=0`
  - **INTERCEPT** → `dev + INTERCEPT=1`

### 16.3 ヒントの二層構造
- **ローカルヒント（既定ON）**: Main側だけで発火・描画（RVPは使わない）。
  - 例: 初回インベントリで `{blue}並び替えは[R]{/blue}` を表示。
- **リモートヒント（任意/サポート用）**: INTERCEPT=1 かつ **能力トークン**が許可する範囲で Host が `SHOW_HINT` を返す。

### 16.4 能力トークン（Capability Token）
- 目的: 配布ビルドでの **権限の最小化**。
- 形式: `Runtime/ipc/.caps`（key=value, 署名付き）。
  ```
  ALLOW_ACTIONS=SHOW_HINT           ; 許可アクション列挙（カンマ区切り）
  EXPIRES=2025-08-09T02:30:00+09:00 ; 有効期限
  SESSION=SUPPORT-1TIME-ABCD        ; セッションID
  SIGNATURE=HMAC-SHA256:xxxx...     ; 署名（§16.5）
  ```
- **配布既定**: `.caps` 不在 → **ALLOW_ACTIONS=（なし）** と同義（Host応答は全無視）。

### 16.5 応答署名（ACK Envelope）
- `replies/*.ack` は以下を満たさないと **release では破棄**：
  - `ACTION` が `.caps` の `ALLOW_ACTIONS` に含まれる
  - `TS <= EXPIRES`（期限内）
  - `SIGNATURE`（ACK本文 + SESSION を HMAC）検証 OK
- HMAC 秘密鍵は Run 側に**難読化**して埋め込み。dev では検証を緩和可。

### 16.6 Main 側の強制（最終防衛）
- Main は常に **ホワイトリスト + 値域検証** を実施（§8）。
- **release** では `PATCH / DEMO_INPUT / ABORT` を**無効化**または `.caps` で個別許可されたときのみ適用。
- `ALLOW_REMOTE_HINTS=0` の場合、`SHOW_HINT` も無視（完全ローカルのみ）。

### 16.7 Watchdog の役割分離
- **センチネル（常時）**: Main PID 心拍、異常終了ログ、ミニテレメトリ。
- **ホスト（INTERCEPT=1 かつ .caps あり）**: イベント受信→プラグイン→ACK 返却。

### 16.8 一時 INTERCEPT（サポート用）
- 手順（例）：
  1) プレイヤーがサポート PIN を入力 → Run が `.caps` を生成/取得（EXPIRES を短く）。
  2) `.mode=INTERCEPT` に一時切替、`ALLOW_REMOTE_HINTS=1`。
  3) 期限切れで自動的に `NORMAL` に復帰し `.caps` を削除。
- **範囲**は `ALLOW_ACTIONS=SHOW_HINT` のみに限定（PATCH等は不可）。

### 16.9 脅威モデルと対策（抜粋）
- **改変 Host からの不正指示** → `.caps` + HMAC + ACTION ホワイトリストで拒否。
- **ACK リプレイ** → `TS/EXPIRES/TTL_MS` を厳密検証。既処理 ACK は破棄。
- **バッチの秘匿困難性** → 重要データは難読 + 冗長監査（`security.ndjson`）で検知側を強化。

### 16.10 実装チェックリスト
- [ ] `Run` 起動時に `.mode` と `.caps` を初期化（配布は `.caps` 生成なし）。
- [ ] `RVP.bat` 先頭で `.mode` を確認し、`INTERCEPT` 以外は即 return。
- [ ] `Watchdog_Host.bat` で `.caps` を読取り、ACK 作成時に **署名**を付与。
- [ ] `Main` 応答受理時に **署名/期限/許可アクション**を再検証。
- [ ] `FEATURE_HINTS=1` でローカルヒントは常時有効。
- [ ] 例外時は**安全側（無視）**に倒す。

> これにより「ヒントを出す＝デバッグが起動」とはならず、**配布時の脆弱性を最小化**しつつ、開発/サポートでは INTERCEPT を安全に活用できる。
