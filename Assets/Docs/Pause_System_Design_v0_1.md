# Pause System Design v0.1

## 1. Goal

ゲーム進行中に 2 系統のポーズ機能を追加する。

- `PauseLite`
  - イベント、タイプ送り、演出中向け
- `PauseFull`
  - 探索、通常操作中向け

要求:

- ポーズ時に BGM をフェードアウト
- できるだけ広い場面でポーズ可能
- ただし常時重い監視は避ける
- 割り込み不能な瞬間でも、次の安全地点でポーズ要求を消費できる

---

## 2. Core Decision

常駐グローバル監視は採用しない。

採用方式:

- 既存ループに `PausePoll` を差し込む
- 即時停止できない場面では `Pause Cue` を積む
- 次の安全地点で `PauseConsume` して実際にポーズへ入る

この方式の利点:

- コストが小さい
- バッチ構成に合う
- 既存モジュールへ段階導入しやすい
- 危険な中断を避けられる

---

## 3. Pause Types

## 3.1 PauseLite

対象:

- `TypeWriter`
- 会話シーン再生
- 演出中
- 自動進行イベント中

想定メニュー:

- `Resume`
- 必要なら `Skip`

画面:

- 小さいオーバーレイ
- `PAUSED`
- `Press P / Esc to resume`

特徴:

- 世界観破壊を最小化
- 操作項目を絞る

## 3.2 PauseFull

対象:

- `CampExplore`
- 通常探索
- 今後の自由移動、通常入力待ち

想定メニュー:

- `Resume`
- `Settings`
- `Return to Title`
- `Exit Game`

画面:

- 既存 UI ルールに合わせた正式メニュー

---

## 4. Pause Cue Model

厳密な複数キューは初版では不要。

初版は 1 件保留方式にする。

状態:

- `PAUSE_REQUESTED=0|1`
- `PAUSE_REQUEST_MODE=LITE|FULL`
- `PAUSE_REQUEST_SOURCE=TYPEWRITER|SCENE|EXPLORE|MENU`
- `PAUSE_REQUEST_MESSAGE=`
- `PAUSE_ACTIVE=0|1`
- `PAUSE_ALLOWED=0|1`
- `PAUSE_DEFERRED=0|1`

意味:

- `PAUSE_REQUESTED=1`
  - 次の安全地点でポーズへ入る要求が保留されている
- `PAUSE_DEFERRED=1`
  - 押されたが、その場で入れず保留になった
- `PAUSE_ACTIVE=1`
  - 現在ポーズ画面中

---

## 5. Control Flow

## 5.1 Immediate Pause

1. ループ中に `PausePoll` を呼ぶ
2. ポーズキーが押される
3. 現在地点が安全なら `PauseEnter`
4. BGM フェードアウト
5. `PauseLite` または `PauseFull` を表示

## 5.2 Deferred Pause

1. ループ中に `PausePoll` を呼ぶ
2. ポーズキーが押される
3. 現在地点が unsafe
4. `PAUSE_REQUESTED=1`
5. 次の安全地点で `PauseConsume`
6. BGM フェードアウト
7. ポーズ画面表示

---

## 6. Safe Points

## 6.1 TypeWriter

推奨:

- 1文字ごとではなく、短い間隔のポーリング点で `PausePoll`
- 実際の `PauseEnter` は文字表示処理の境界で行う

理由:

- ANSI シーケンス途中の中断を避ける
- 1文字単位の停止は不安定になりやすい

推奨挙動:

- 押下時は `Pause cue...`
- その行の安全地点で `PauseLite`

## 6.2 RenderScene

安全地点:

- 1行処理終了後
- `{delay}` 終了後
- `{pause:auto:n}` の待機ループ中

## 6.3 CampExplore

安全地点:

- メインループ 1 周ごと

ここでは基本的に即時 `PauseFull` に入ってよい。

## 6.4 Blocking Choice Loops

`choice` ベースの待機中は弱い。

初版方針:

- `choice` ベースのループはポーズ対象から外すか、後回し
- 将来的に `cmdwiz getch noWait` ベースへ寄せる

---

## 7. Input Policy

推奨ポーズキー:

- `Esc`
- `P`

補足:

- `Esc` は一般的で直感的
- `P` は環境依存が少なく、代替入力として有効

ルール:

- どちらかを押したらポーズ要求
- `PauseLite` 中も同じキーで復帰可能

---

## 8. BGM Behavior

## 8.1 Enter Pause

ポーズ時:

- 現在 BGM をフェードアウト
- 一定時間後に停止

保存する状態:

- `PAUSE_BGM_TRACK`
- `PAUSE_BGM_VOLUME_BEFORE`
- `PAUSE_BGM_MODE`

## 8.2 Resume

再開時:

- 保存したトラックを再開
- フェードインして元音量へ戻す

注意:

- 既存の `Play_BGM.bat` / `BgmPlayer.bat` の責務に寄せる
- ポーズ専用で音声状態を二重管理しない

---

## 9. Module Proposal

新規候補:

- `Src\Systems\Display\PauseManager.bat`

責務:

- ポーズ要求の受付
- 保留要求の消費
- `PauseLite` / `PauseFull` の分岐
- BGM フェードアウト / 復帰の窓口

---

## 10. Suggested Interface

## 10.1 Poll

`call "%src_display_dir%\PauseManager.bat" POLL FULL`

意味:

- 現在ループでポーズキーが押されたか確認
- 可能なら即時ポーズ
- 無理なら要求だけ積む

## 10.2 Consume

`call "%src_display_dir%\PauseManager.bat" CONSUME`

意味:

- 保留中のポーズ要求を安全地点で実行

## 10.3 Enter

`call "%src_display_dir%\PauseManager.bat" ENTER LITE`

`call "%src_display_dir%\PauseManager.bat" ENTER FULL`

意味:

- 明示的にポーズ画面へ入る

## 10.4 Resume

`call "%src_display_dir%\PauseManager.bat" RESUME`

意味:

- BGM を復帰し、ポーズ状態を解除

## 10.5 Reset

`call "%src_display_dir%\PauseManager.bat" RESET`

意味:

- シーン切り替え時にポーズ要求を掃除

---

## 11. Return Codes

例:

- `0`
  - no action / normal continue
- `1`
  - pause entered
- `2`
  - pause queued
- `3`
  - title requested
- `4`
  - exit requested

これで呼び出し元ループが分岐しやすくなる。

---

## 12. UX Messages

ポーズ保留時の短い表示候補:

- `Pause cue...`
- `Pausing after current line...`
- `Pause pending`

表示ルール:

- `TypeWriter` 中だけ表示
- 探索中は即ポーズなので表示不要

---

## 13. Initial Rollout Plan

### Phase P1

対象:

- `PauseManager.bat` 新設
- `CampExplore` に `PauseFull`

理由:

- ループが明確
- 即時停止しやすい
- 効果が大きい

### Phase P2

対象:

- `TypeWriter` に `PauseLite`
- `RenderScene` の行境界で `PauseConsume`

理由:

- イベント中ポーズの需要が高い

### Phase P3

対象:

- `SettingsMenu` など他の `getch` 系ループ

### Phase P4

対象:

- `choice` ベースループの置換または限定対応

---

## 14. Risks

- ANSI シーケンス途中停止で表示が壊れる
- `choice` 待機中は即時ポーズが難しい
- BGM の復帰状態を正しく保持できないと違和感が出る
- シーン切替時に `PAUSE_REQUESTED` が残ると誤動作する

対策:

- 停止地点を明示する
- `RESET` をシーン開始時に呼ぶ
- BGM 状態は `PauseManager` に集約する

---

## 15. Recommendation

最初にやるべきなのは `CampExplore` 向けの `PauseFull` である。

理由:

- ポーズ価値が高い
- 実装が安全
- `PauseManager` の骨格を作りやすい

その次に `TypeWriter` / `RenderScene` 側へ `PauseLite` を入れる。

この順なら、常時監視を避けながら「ほぼいつでもポーズ」の体験へ近づける。
