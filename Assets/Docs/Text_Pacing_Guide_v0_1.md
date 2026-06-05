# Text Pacing Guide v0.1

## Goal

テキストシーンのテンポを、演出都合の待機とプレイヤー主導の待機に分けて扱う。

今後の基準は単純に次の 2 つでよい。

- `{delay:n}` は作者主導の演出待機
- `{pause}` はプレイヤー主導の入力待機

---

## Use `{delay:n}` When

次のような場面では `{delay}` を残す。

- カメラ切替や背景切替の直後に余韻を作りたい
- SE や BGM の演出タイミングを固定したい
- 地の文やモノローグに、作者が決めた間を必ず入れたい
- プレイヤーの入力速度に依存させたくない

例:

```text
{bg:Ruins.png}{delay:300}
{type:normal}The wind had already stopped.{/type}
```

---

## Use `{pause}` When

次のような場面では `{pause}` を使う。

- 台詞の意味をプレイヤーに受け取らせたい
- 感情の間をプレイヤー側で決めてよい
- 次へ進む前に一度読み切り待ちを入れたい
- これまで `{delay}` で実質的に入力待ちを代用していた

例:

```text
{type:normal}I did not answer right away.{/type}
{pause}
{type:normal}There was nothing easy to say.{/type}
```

---

## Do Not Replace Everything

既存の `{delay}` を一括で `{pause}` に置換しない。

理由:

- 演出テンポがプレイヤー依存になって崩れる
- BGM や SE の置き方が変わる
- 背景切替やカメラ演出の沈黙が不安定になる

置き換えてよいのは、
「固定待機に見えるが、実際には読了待ちとして使っている箇所」
だけである。

---

## Recommended Review Pass

既存シナリオを見直すときは、この順で判断すると速い。

1. その待機は演出都合か、読了待ちか
2. プレイヤーに主導権を渡して問題ないか
3. BGM や SE のタイミングが崩れないか
4. 迷うなら `{delay}` を残す

---

## UX Note

現行の会話シーンでは次の操作ガイドを表示する。

- `F / Space`: Fast-forward line
- `P / Esc`: Pause

そのため `{pause}` を使う場面が増えても、プレイヤーは操作を把握しやすい。
