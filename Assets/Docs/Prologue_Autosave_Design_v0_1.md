# Prologue Autosave Design v0.1

## 1. Goal

Prologue の正式な終端で開発用メッセージを撤去し、その直後にオートセーブを実行する。

初版の目的は「Prologue 完了地点を安全に保存し、Continue で Prologue 冒頭へ戻らない状態を作る」ことである。手動セーブ、複数セーブポイント、セーブ詳細 UI の拡張は後続段階に分ける。

---

## 2. Current State

Prologue の現在の終端は次の流れである。

1. `Src/Stories/Scenes/00_NewGame/EnterYourName.bat`
2. `Scene02_NameConfirmed.txt`
3. `Scene03_PrologueOutro.txt`
4. `exit /b 604`

`Scene03_PrologueOutro.txt` には現在、開発用メッセージが含まれている。

```text
プロローグ仮実装はここまで。続きは次の開発段階で接続される。
```

既存のセーブ系は `SaveData_%slot%.txt` を `key=value` として読む仕組みがある。ただし、ゲーム進行中から保存する共通 Writer はまだ分離されていない。

---

## 3. Design Policy

初版は小さく作る。

- Prologue 終端専用ではなく、将来の手動セーブにも使える Writer を作る。
- 保存形式は既存の `key=value` を維持する。
- 書き込みは一時ファイルを作ってから置換する。
- 失敗時は RCS に記録し、呼び出し元へエラーコードを返す。
- Prologue の演出ファイルは物語テキストだけを持ち、保存処理は `.bat` 側へ置く。

やらないこと:

- セーブデータ暗号化
- チェックサム
- 圧縮
- 複数地点の巻き戻し
- セーブ UI の大改修

---

## 4. Save Writer

新規ファイル:

```text
Src/Systems/SaveSys/SaveDataWriter.bat
```

想定インターフェース:

```bat
call "%src_savesys_dir%\SaveDataWriter.bat" AUTO <slot> <save_point>
```

初版で使う呼び出し:

```bat
call "%src_savesys_dir%\SaveDataWriter.bat" AUTO "%current_save_slot%" prologue_end
```

引数:

| Arg | Meaning |
| --- | --- |
| `%1` | `AUTO` or `MANUAL` |
| `%2` | Save slot number |
| `%3` | Save point id |

戻り値:

| Code | Meaning |
| --- | --- |
| `0` | 保存成功 |
| `90210001` | スロット不正 |
| `90210002` | 一時ファイル書き込み失敗 |
| `90210003` | セーブファイル置換失敗 |
| `90230001` | 必須フィールド不足 |

RCS の既存定数に合わせる場合:

- `9 02 10 001` = ERR / SaveData / I/O / invalid slot
- `9 02 10 002` = ERR / SaveData / I/O / temp write failed
- `9 02 10 003` = ERR / SaveData / I/O / replace failed
- `9 02 30 001` = ERR / SaveData / Validation / required field missing

---

## 5. Save Data Schema

初版の `SaveData_%slot%.txt` は次のキーを持つ。

```ini
save_version=1
save_kind=auto
save_slot=1
save_point=prologue_end
saved_at=YYYY-MM-DD HH:mm:ss

player_name=シオン
player_level=1
player_storyroute=Chapter01

current_chapter=Chapter01
current_scene=Chapter01_Start
current_location=星が降る丘

prologue_completed=1
camp_explore_viewed_count=0
camp_seen_1=0
camp_seen_2=0
camp_seen_3=0
camp_seen_4=0
camp_seen_5=0
camp_seen_6=0
```

`SaveDataSelector.bat` は既に次を読むため、この3項目は必ず書く。

- `player_name`
- `player_level`
- `player_storyroute`

`player_storyroute` は Continue の遷移にも使われるため、Prologue 完了後に戻る先を明確にする必要がある。

暫定案:

- Chapter01 が存在する場合: `player_storyroute=Chapter01`
- Chapter01 が未接続の場合: `player_storyroute=PrologueComplete`

---

## 6. Slot Ownership

NewGame 開始時点で選択されたスロットを、ゲーム進行側へ渡す必要がある。

`Src/Main/Main.bat` の `:Start_NewGameSession` で次を設定する。

```bat
set "current_save_slot=%1"
```

この値を `EnterYourName.bat` から参照し、Prologue 終端のオートセーブに使う。

スロット未定義の場合は保存しないで進めるのではなく、RCS にエラーを出して MainMenu へ戻す方が安全である。

---

## 7. Prologue End Flow

目標フロー:

```text
Scene02_NameConfirmed
  ↓
Scene03_PrologueOutro
  ↓
AutoSave(prologue_end)
  ↓
AutoSave notice
  ↓
exit /b 604
```

`Scene03_PrologueOutro.txt` からは開発用メッセージを削除する。

オートセーブ表示は演出を邪魔しない短い通知にする。

例:

```text
AUTO SAVE
```

または:

```text
オートセーブしました
```

表示位置はフッター付近か右下に寄せ、物語本文の中央領域を汚さない。

---

## 8. RCS Requirements

保存処理では必ず RCS を通す。

Writer 起動:

```bat
call "%RCSU%" -trace INFO SaveDataWriter "start kind=AUTO slot=%slot% point=%save_point%"
```

保存成功:

```bat
call "%RCSU%" -trace INFO SaveDataWriter "saved slot=%slot% path=%save_path%"
```

入力検証失敗:

```bat
call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_VALID% 001 "Save required field missing" "slot=%slot%;point=%save_point%"
```

I/O 失敗:

```bat
call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 002 "Save temp write failed" "slot=%slot%;path=%tmp_path%"
```

Prologue 側の接続ログ:

```bat
call "%RCSU%" -trace INFO EnterYourName "prologue autosave start slot=%current_save_slot%"
call "%RCSU%" -trace INFO EnterYourName "prologue autosave returned rc=%autosave_rc%"
```

RCS が未定義の環境でもゲームが即死しないように、呼び出しは必ず次の形にする。

```bat
if defined RCSU if exist "%RCSU%" call "%RCSU%" ...
```

---

## 9. Implementation Roadmap

### Phase 1: Save Writer

- `SaveDataWriter.bat` を追加する。
- `AUTO <slot> prologue_end` だけ対応する。
- `SaveData_%slot%.txt.tmp` に書き込む。
- 成功後に `SaveData_%slot%.txt` へ置換する。
- RCS trace / throw を入れる。

### Phase 2: Slot Wiring

- `Main.bat :Start_NewGameSession` で `current_save_slot` を設定する。
- NewGame overwrite 時も同じスロットを維持する。
- Prologue 側で `current_save_slot` 未定義を検出する。

### Phase 3: Prologue End Cleanup

- `Scene03_PrologueOutro.txt` から開発用メッセージを削除する。
- 正式な Prologue 終了演出だけを残す。

### Phase 4: Autosave Hook

- `EnterYourName.bat` の `Scene03_PrologueOutro.txt` 後に Writer を呼ぶ。
- 成功時は短い `AUTO SAVE` 通知を出す。
- 失敗時は RCS に記録し、ユーザーにも短く通知する。

### Phase 5: Continue Route

- `player_storyroute` の保存値を決める。
- `Main.bat :JumpToEpisode` に `Chapter01` または `PrologueComplete` の受け口を追加する。
- Continue が Prologue 冒頭へ戻らないことを確認する。

### Phase 6: Smoke Test

- 空スロットで NewGame を開始。
- Prologue を最後まで進める。
- 開発用メッセージが出ないことを確認。
- `SaveData_%slot%.txt` が作成されることを確認。
- SaveDataSelector に名前、Lv、route が表示されることを確認。
- Continue で保存地点以降へ進むことを確認。
- RCS ログに start/saved/returned が残ることを確認。

---

## 10. Open Decisions

1. Prologue 完了後の正式な `player_storyroute` 名
   - `Chapter01`
   - `PrologueComplete`
   - 別名

2. オートセーブ通知の表記
   - `AUTO SAVE`
   - `オートセーブしました`

3. Chapter01 未実装時の Continue 先
   - 仮の「続きは次の章へ」画面
   - MainMenu へ戻す
   - Chapter01 スタブへ進める

---

## 11. Recommended First Cut

最初の実装は次に絞る。

1. `SaveDataWriter.bat` を作る。
2. `current_save_slot` を渡す。
3. Prologue 終端で `AUTO prologue_end` を保存する。
4. `Scene03_PrologueOutro.txt` の開発用メッセージを消す。
5. Continue 先は暫定で `PrologueComplete` として、未実装画面へ逃がす。

これで「Prologue は正式に終わる」「終端で保存される」「再開時に冒頭へ戻らない」という最低ラインを満たせる。
