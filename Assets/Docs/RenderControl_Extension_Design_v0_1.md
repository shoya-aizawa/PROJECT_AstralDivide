# RenderControl Extension Design v0.1

## 1. Goal

`RenderControl` 系ユニットに以下を追加する。

- テキストタイプに応じたセリフ送り SE
- プレイヤー入力による加速 / 行スキップ
- `{pause}` 系の入力待ちタグ
- 今後の UX 改善タグを安全に足せる拡張方針

前提条件:

- 既存の `{type:slow|normal|fast|数値}` は互換維持
- 既存のシナリオテキストは原則無修正で動作維持
- `RenderControl` / `RenderMarkup` / `TypeWriter` の責務分離は維持

---

## 2. Current Risk

現行構成では以下が壊れやすい。

- `RenderControl_v2.3.bat`
  - 先頭タグを再帰的に剥がす制御と表示分岐を兼ねている
- `TypeWriter_v2.3.bat`
  - 1文字ごとに固定 delay を入れるだけで、途中入力を見ていない
- `{type}` タグ
  - 実質的に「文字送り速度タグ」として使われている

このため、`{type}` に SE や入力制御まで背負わせると責務が崩れる。

---

## 3. Responsibility Split

### 3.1 RenderControl

担当:

- 行頭タグの解釈
- 表示モードの決定
- `RenderMarkup` と `TypeWriter` への橋渡し
- 明示的な待機タグの実行

担当しない:

- 文字ごとの入力監視
- 文字ごとの SE 発音タイミング管理の細部

### 3.2 RenderMarkup

担当:

- 色
- 装飾
- 変数展開

担当しない:

- 入力待ち
- タイプ速度
- スキップ制御

### 3.3 TypeWriter

担当:

- 文字送り
- 文字送り中の入力ポーリング
- 一時加速
- 行末まで即時表示
- タイプ送り中の SE 発火

---

## 4. Backward Compatibility Policy

以下は意味変更しない。

- `{type:slow}`
- `{type:normal}`
- `{type:fast}`
- `{type:数値}`
- `{delay:n}`
- `{clear}`
- `{pos:y:x}`

既存テキスト資産に対しては、追加タグ未使用時の表示結果を現状と一致させる。

---

## 5. Tag Design

## 5.1 Keep Existing

### `{type:...}...{/type}`

用途:

- 文字送り速度の指定

対応値:

- `slow`
- `normal`
- `fast`
- 数値ミリ秒

備考:

- SE 種別は持たせない
- スキップ可否は持たせない

## 5.2 New Tags

### `{pause}`

用途:

- 任意キー入力待ち

挙動:

- 行表示完了後、続行キー待ち
- 続行キー候補は `Space`, `Enter`, 決定キー

### `{pause:auto:n}`

用途:

- 指定ミリ秒の自動待機

例:

- `{pause:auto:500}`

挙動:

- `500ms` 待機後に自動続行
- スキップ入力中は待機を短縮または無視可能にする

### `{se:name}`

用途:

- この行のタイプ送り SE プロファイル指定

例:

- `{se:tick_soft}`
- `{se:tick_hard}`
- `{se:none}`

挙動:

- 現在行に対して `TypeWriter` が参照する SE プロファイルを設定
- 次行へ自動継承するかどうかは初版では「非継承」を推奨

### `{autonext:n}`

用途:

- 行表示後、指定ミリ秒で次行へ自動遷移

例:

- `{autonext:800}`

挙動:

- 行末表示完了後に `n ms` 待って次へ
- プレイヤー入力があれば即続行

### `{skip:off}`

用途:

- その行または区間だけ即時スキップ禁止

用途例:

- 演出上どうしても一瞬は読ませたい文

備考:

- 初版では「行単位」で十分
- 区間タグ化は後回しでよい

### `{instant}...{/instant}`

用途:

- その区間だけタイプ送りせず即時表示

用途例:

- 記号
- 演出用の短い挿入
- ログ風の固定表示

---

## 6. Input UX Design

## 6.1 Recommended Behavior

タイプ送り中の入力は 3 段階にする。

1. キー未入力
   - 通常速度で進む
2. 加速キー押下中
   - 速度倍率を上げる
3. 続行キー再入力
   - その行の残りを即時表示

推奨キー:

- `Space`
- `Enter`
- 将来の決定キー

加速専用キーを後で追加するなら候補:

- `Shift`
- `Ctrl`

## 6.2 Why This Is Safe

この方式は「行送り」と「次の行への進行」を分離しやすい。

- 1回目の入力で可読性を残しつつ加速
- 2回目の入力で待ち時間を消せる
- 誤爆で全文を飛ばしにくい

---

## 7. Type SE Design

## 7.1 Principle

SE 指定は `{type}` に含めず、`TypeWriter` の再生設定として渡す。

## 7.2 Recommended Profiles

初版プロファイル:

- `default`
- `tick_soft`
- `tick_hard`
- `narration_soft`
- `none`

## 7.3 Playback Rule

全文字で鳴らす必要はない。

推奨:

- 句読点では鳴らさない
- 空白では鳴らさない
- 2文字ごと、または最小間隔つきで鳴らす

理由:

- バッチ環境では 1文字ごと再生は過密になりやすい
- 非同期 SE 呼び出しの負荷を下げられる

---

## 8. Data Flow Proposal

推奨フロー:

1. `RenderControl`
   - 行頭タグを解釈
   - `speed`
   - `se_profile`
   - `pause_mode`
   - `autonext`
   - `skip_policy`
   をその行の表示設定として確定
2. `RenderMarkup`
   - 本文を装飾込みで解決
3. `TypeWriter`
   - 解決済み本文と表示設定を受けて描画
4. `RenderControl`
   - 必要なら `pause` / `autonext` を実行

重要:

- `TypeWriter` は「本文表示」
- `RenderControl` は「行進行制御」

---

## 9. Phased Implementation Plan

## Phase 1

対象:

- `TypeWriter` の入力ポーリング化
- 加速
- 行末まで即時表示

この段階ではタグ追加なしでも価値が高い。

## Phase 2

対象:

- `{pause}`
- `{pause:auto:n}`

理由:

- 演出待機とユーザー待機を分離できる

## Phase 3

対象:

- `{se:name}`
- タイプ送り SE プロファイル

理由:

- 速度制御と分離したまま音の差し替えができる

## Phase 4

対象:

- `{autonext:n}`
- `{skip:off}`
- `{instant}...{/instant}`

理由:

- 細かい演出最適化の段階

---

## 10. High-Risk Changes To Avoid

- `{type}` に複数責務を持たせる
- `RenderMarkup` に待機や入力制御を混ぜる
- `RenderControl` に文字単位ループを持たせる
- 既存タグの意味を変更する
- 既存シナリオを書き換えないと動かない設計にする

---

## 11. Minimal Implementation Contract

最低限の追加インターフェース案:

- `TypeWriter_v2.3.bat "text" speed se_profile skip_policy`

または環境変数受け渡し:

- `TYPEWRITER_SPEED`
- `TYPEWRITER_SE_PROFILE`
- `TYPEWRITER_SKIP_POLICY`

初版は環境変数受け渡しのほうが、既存 `call` 形式を壊しにくい。

---

## 12. Recommended Decision

採用方針:

- `{type}` は速度専用のまま固定
- SE は `{se:...}` で分離
- ユーザー待機は `{pause}` 系で分離
- 行内の入力加速とスキップは `TypeWriter` に閉じ込める

これなら既存設計の破壊リスクを最小化できる。
