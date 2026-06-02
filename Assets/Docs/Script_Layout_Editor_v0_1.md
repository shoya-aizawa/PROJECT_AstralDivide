# Script Layout Editor v0.1

## 目的

台本テキストの `{pos:y:x}` を視覚的に調整し、その結果を**元ファイルへ即時反映**する。

## 対応方針

- `RenderControl_v2.3.bat` に `{id:...}` を追加
- エディタは `{id:...}` 単位で移動対象を扱う
- `{id:...}` がない `{pos:...}` 行は `L行番号` の仮IDで扱う
- 変更はターゲット `.txt` にホットスワップする

## 現在の実装

ファイル:

- `Src/Systems/Debug/ScriptLayoutEditor.bat`

起動例:

```bat
call "C:\Users\shoya\Desktop\AstralDivide\Src\Systems\Debug\ScriptLayoutEditor.bat" ^
  "C:\Users\shoya\Desktop\AstralDivide\Src\Stories\TextAssets\00_NewGame\Scene01_PrologueIntro.txt"
```

背景指定:

```bat
call "C:\Users\shoya\Desktop\AstralDivide\Src\Systems\Debug\ScriptLayoutEditor.bat" ^
  "C:\Users\shoya\Desktop\AstralDivide\Src\Stories\TextAssets\00_NewGame\Scene01_PrologueIntro.txt" ^
  "C:\Users\shoya\Desktop\AstralDivide\Assets\Images\AD_StarrySky.png"
```

## 操作

- 引数なし起動:
  - `Src\Stories\TextAssets` 配下の `.txt` 一覧から選択
- `N` / `P`: ID選択
- `WASD`: 1マス移動
- `Shift+WASD`: 5マス移動
- `E`: 現在IDの先頭行を生編集
- `I`: 現在IDのID名を変更
- `R`: ファイル再読込
- `U`: Undo
- `Z`: Redo
- `J`: IDジャンプ
- `Q`: 終了

## 推奨する台本記法

```txt
{id:prologue_intro_01}{pos:35:66}{type:slow}{hi_white}丘の上に着くと、そこには何もなかった。{/hi_white}{/type}
```

複数行を同じIDにすれば、**会話のまとまりごと一括移動**できる。

## 今後追加したい機能

- 複数行グループの一覧パネル
- 現在行だけでなく、ID配下の全行個別編集
- `{delay}` のタイムライン編集
- 行の新規追加 / 削除
- ファイル保存前の dirty 状態表示
- 変更履歴の `.diff` 出力
- 背景画像切替
- 会話帯 / 入力枠のオーバーレイ切替
- 複数ファイルを跨ぐシーンセット編集
