# PauseLite Design v0.1

## 1. Goal

`PauseLite` はイベント進行中の一時停止専用ポーズである。

対象は次の 3 系統に限定する。

- `TypeWriter` の文字送り中
- `RenderControl` の `{pause}` 待機中
- `RenderControl` の `{pause:auto:n}` 待機中

初版では、イベントスクリプト全体をどこでも中断する仕組みにはしない。
「既存の安全地点でだけ止まれる」ことを明示的に設計方針とする。

---

## 2. Core Policy

`PauseLite` は `PauseFull` と違って多機能 UI を持たない。
目的は演出を壊さずに短時間止めることだけである。

初版の責務は次だけに絞る。

- 進行中 BGM のフェードアウト
- 画面上への簡易 `PAUSED` 表示
- `Resume` のみ
- 必要なら将来 `Skip` を追加できる余地を残す

やらないこと:

- `Settings`
- `Return to Title`
- `Exit Game`
- セーブ関連
- 複数階層の確認ダイアログ

---

## 3. Why Separate From PauseFull

`PauseFull` をイベント中にも出すと、次の問題が出やすい。

- 演出テンポが完全に切れる
- 背景やテキスト表示途中の状態管理が重くなる
- タイトル戻りや終了の導線がイベント文脈を壊しやすい

そのため、イベント中は `PauseLite` で止めるだけにする。
自由移動や通常操作ループでは引き続き `PauseFull` を使う。

---

## 4. Entry Points

## 4.1 TypeWriter

`TypeWriter_v2.3.bat` の `:main_loop` 冒頭で毎周 `PausePoll LITE TYPEWRITER` を呼ぶ。

ただし、押した瞬間にその場で `PauseEnter` はしない。
1 文字だけ状態を進めてしまうと見た目が不安定になりやすいので、初版は次の方針にする。

- キー検出時は `PAUSE_REQUESTED=1`
- `PAUSE_REQUEST_MODE=LITE`
- `PAUSE_REQUEST_SOURCE=TYPEWRITER`
- 次の安全地点で `PauseConsume`

`TypeWriter` の安全地点:

- 1 文字出力後
- 加速・行スキップ判定後
- 文字送り delay 前

このとき、表示中の 1 行は維持される。
行途中でポーズに入っても、再開後は残りの文字送りを続ける。

## 4.2 RenderControl `{pause}`

`{pause}` は元々「入力待ち」なので、ここは即時 `PauseLite` と相性がよい。

実装方針:

- `WaitForAdvanceKey` のループを `getch noWait` ベースへ変更
- `PausePoll LITE RENDER_WAIT` を毎周呼ぶ
- ポーズ復帰後は元の入力待ちへ戻る

つまり、`{pause}` 自体は消費されず、復帰後もまだ「次へ進むための入力待ち」のままである。

## 4.3 RenderControl `{pause:auto:n}`

`{pause:auto:n}` の待機ループも `PauseLite` の対象にする。

実装方針:

- 既存の 15ms 単位ループ中で `PausePoll LITE RENDER_AUTO` を呼ぶ
- ポーズ要求が来たら `PauseConsume`
- 復帰後は残り待機時間を続行

重要なのは「ポーズ時間を待機時間にカウントしない」ことである。
たとえば `{pause:auto:800}` の途中で 5 秒止めても、復帰後に残り時間ぶんだけ待つ。

---

## 5. UI Spec

初版の見た目は最小でよい。

表示要素:

- 中央寄せの `PAUSED`
- 1 行下に `Press P / Esc to resume`

やること:

- 既存画面を消さない
- オーバーレイ風に軽く上書きする
- 復帰時にその表示行だけ消す

やらないこと:

- 背景マスク
- 複雑なメニュー枠
- 選択カーソル

---

## 6. Input Policy

`PauseLite` の入力キーは `PauseFull` と揃える。

- `Esc`
- `P`

復帰も同じキーでよい。
初版では `Enter` を復帰キーに混ぜない。

理由:

- `Enter` は会話送りと衝突しやすい
- 復帰直後にそのまま 1 行進んでしまう事故を避けたい

---

## 7. BGM Behavior

## 7.1 Enter

`PauseFull` と同じく、`PauseLite` でも BGM はフェードアウトして止める。

保存しておく値:

- `PAUSE_BGM_VOLUME`
- `PAUSE_BGM_PATH`
- `PAUSE_BGM_MODE`

## 7.2 Resume

`PauseFull` で安定した現在の方式をそのまま使う。

- `BgmPlayer RESUME`
- 短い待機
- `BgmPlayer VOLUME <saved/current volume>`

これで、イベント中ポーズも「続きから再生」を優先できる。

---

## 8. State Model

初版は複数キュー不要。1 件保留だけでよい。

使う状態:

- `PAUSE_REQUESTED=0|1`
- `PAUSE_REQUEST_MODE=LITE|FULL`
- `PAUSE_REQUEST_SOURCE=TYPEWRITER|RENDER_WAIT|RENDER_AUTO|EXPLORE`
- `PAUSE_ACTIVE=0|1`

任意で追加可能:

- `PAUSE_REQUEST_MESSAGE=`

今回は `PauseLite` で保留文言までは出さなくてよい。
出すなら `TypeWriter` 限定で短く出す。

---

## 9. PauseManager Interface

`PauseManager.bat` に追加する入口は次の形が妥当。

### 9.1 Poll

```bat
call "%src_display_dir%\PauseManager.bat" POLL LITE TYPEWRITER
```

責務:

- ポーズキー検出
- 検出したら `PAUSE_REQUESTED=1`
- 即時停止はしない

### 9.2 Consume

```bat
call "%src_display_dir%\PauseManager.bat" CONSUME
```

責務:

- `PAUSE_REQUESTED=1` を見て実際に `PauseEnter`
- `PAUSE_REQUEST_MODE=LITE` なら `PauseLite` を出す
- 復帰後に `PAUSE_REQUESTED=0` へ戻す

### 9.3 Enter

```bat
call "%src_display_dir%\PauseManager.bat" ENTER LITE
```

責務:

- BGM フェードアウト
- `PauseLite` UI 表示
- 復帰待ち
- BGM 復帰

---

## 10. Safe-Point Rules

初版のルールは単純にする。

- `TypeWriter`
  - 1 文字表示中には割り込まない
  - 文字出力完了後にだけ `PauseConsume`
- `{pause}`
  - 入力待ちループ中なら即時 `PauseLite`
- `{pause:auto:n}`
  - 15ms 単位待機の切れ目でだけ `PauseLite`

これなら、表示崩れや再帰制御の事故をかなり減らせる。

---

## 11. Interaction With Existing Tags

`PauseLite` は既存タグの意味を変えない。

- `{type:...}` はそのまま
- `{pause}` はそのまま
- `{pause:auto:n}` はそのまま
- `{se:...}` もそのまま

注意点:

- `TypeWriter` 中のポーズ復帰では、その行の SE カウンタ状態は保持したまま続行する
- 行スキップ中にポーズ要求が来たら、復帰後も同じスキップ状態で続く

---

## 12. RCS

初版でも軽く入れる価値がある。

候補:

- `pause key detected mode=LITE source=TYPEWRITER`
- `pause queued mode=LITE source=TYPEWRITER`
- `pause consume mode=LITE source=TYPEWRITER`
- `enter lite pause`
- `lite pause resume selected`

`PauseFull` と同じ粒度で十分で、過剰な逐次ログは不要。

---

## 13. Risks

### 13.1 `Enter` 衝突

`{pause}` 復帰や会話送りに `Enter` を使っている場所で、ポーズ復帰まで `Enter` を許すと誤進行しやすい。
初版では `P` / `Esc` のみにして衝突を避ける。

### 13.2 ANSI 途中表示

`TypeWriter` は ANSI シーケンスを途中でも扱うので、割り込み地点が雑だと表示が壊れる。
そのため、割り込みは `PauseConsume` の安全地点のみとする。

### 13.3 キー残留

ポーズ突入前後で `flushkeys` を入れないと、復帰直後に会話送りやスキップが走る危険がある。
`PauseLite` でも `PauseFull` 同様にキー掃除を入れるべきである。

---

## 14. Recommended Phase

実装順は次でよい。

1. `PauseManager.bat` に `LITE` の `POLL / CONSUME / ENTER` を追加
2. `TypeWriter_v2.3.bat` に `PausePoll` と `PauseConsume` を差す
3. `RenderControl_v2.3.bat` の `WaitForAdvanceKey` をループ化して `PauseLite` 対応
4. `RenderControl_v2.3.bat` の `WaitAutoOrAdvance` に `PauseLite` 対応

初版ではこの範囲で止めるのが安全である。

---

## 15. Conclusion

`PauseLite` は「イベント中でもいつでも止められる万能ポーズ」ではなく、
「既存の安全地点でだけ確実に止められる軽量ポーズ」として設計するべきである。

この切り方なら、

- 既存イベント資産を壊しにくい
- `TypeWriter` / `RenderControl` に局所的に差せる
- `PauseFull` と責務が混ざらない

という利点がある。
