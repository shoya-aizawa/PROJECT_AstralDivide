# Astral Divide Return/Error Code Standard (RECS) v1

**Project:** PROJECT_AstralDivide (HedgeHogSoft)  
**Doc Type:** Implementation Standard / .md  
**Status:** Draft v1.0  
**Date:** 2025-08-09 (JST)

---

## 1. 目的（Why）
- バッチファイルの**`ERRORLEVEL`**を基盤に、**正常フロー**と**異常（エラー）**を統一形式で返す。  
- **人力で生数値を書かない**・**こまめにログ**・**即デコード**を実現し、運用（Run/Intercept/Debug）で読みやすくする。  
- 将来の拡張（新モジュールやオンライン要素）に耐える。

### 本仕様が解決する課題
- 返却値の**衝突/乱立**、意味の**不明瞭**、**ログ欠如**、**即死時の追跡困難**。

---

## 2. 数値フォーマット（8桁固定）

```
S DD RR CCC   （例：10,101,001）
│ │  │  └─ 詳細(0–999)：スロット番号や個別原因ID
│ │  └──── 理由グループ(00–99)：I/O, Network, Selection など
│ └─────── ドメイン(00–99)：MainMenu, SaveData, Audio…
└───────── 区分(1桁)：1=正常フロー, 8=ユーザ中断, 9=障害
```
- 数式：`code = S*10,000,000 + DD*100,000 + RR*1,000 + CCC`
- 32bit 符号付き整数の安全圏（< 2,147,483,647）。
- **比較は必ず `EQU` / 明示条件**を用い、`if errorlevel N`（>=判定）は使わない。

### 2.1 区分 `S`
| 値 | 意味 |
|---:|---|
| **1** | 正常フロー（選択結果・通常遷移）|
| **8** | ユーザ中断／キャンセル（戻る・Esc）|
| **9** | エラー（失敗・致命・要復旧）|
| 2/3/4 | 予約（情報/警告/リトライ推奨 など、将来拡張）|

### 2.2 ドメイン `DD`（初期割当）
| 値 | ドメイン | 例 |
|---:|---|---|
| **01** | MainMenu | タイトル/メインメニュー |
| **02** | SaveData | セーブ選択/作成/読み込み |
| **03** | Display | 画面描画/枠テンプレート |
| **04** | Environment | 言語/コードページ/画面環境 |
| **05** | Audio | BGM/SE 再生 |
| **06** | Systems(Core) | 初期化/プロセス制御 |
| **07** | Network | GAS/HTTP/Timeout |
| **08** | Story | シーン/テキスト資源 |
| **09** | Debug & Intercept | 監視/介入/ブレーク |
| **10–19** | Tools/Reserved | 予備 |

### 2.3 理由グループ `RR`（共通辞書）
| 値 | 理由 | 典型例 |
|---:|---|---|
| **01** | Selection | ユーザ選択結果/分岐 |
| **10** | I/O | ファイル/ディレクトリ/権限 |
| **11** | Parse | 構文/フォーマット/パース失敗 |
| **12** | Encode | 文字コード/URL/JSON |
| **20** | Network | 通信/HTTP/タイムアウト |
| **30** | Validation | 事前条件・環境検証不成立 |
| **50** | Compat | 互換性/バージョン不一致 |
| **90** | Other | 一時・分類不能 |

### 2.4 `CCC`（詳細 ID）
- ドメインや理由ごとの**詳細識別**（0–999）。
- スロット番号等を割り当て可能（例：Slot2 → `002`）。

---

## 3. 付帯メタ情報（任意）
返却時に以下の環境変数を併送可能：
- `AD_RC`：8桁コード（数値）。
- `AD_RC_KIND=FLOW|CANCEL|ERR`（`S`から導出）。
- `AD_RC_TAG`：任意の短いタグ（MainMenu/SaveData 等）。
- `AD_RC_MSG`：短い説明文（英語/Japanese OK）。

> Run/Debug/Intercept のログで**人間が即状況を理解**できるようにする。

---

## 4. ユーティリティ（標準ライブラリ）
本仕様は**生数値の直書きを禁止**し、ラッパー経由で発行する。

### 4.1 ファイル配置（提案）
```
Src/Systems/Debug/
  ├─ rc.const.bat   （定数：S/DD/RR のシンボル）
  └─ rcutil.bat     （BUILD/DECODE/THROW/RETURN/TRACE 等）
```

### 4.2 `rc.const.bat`（抜粋）
```bat
:: 区分
set RC_S_FLOW=1
set RC_S_CANCEL=8
set RC_S_ERR=9

:: ドメイン
set RC_D_MENU=01
set RC_D_SAVE=02
set RC_D_DISPLAY=03
set RC_D_ENV=04
set RC_D_AUDIO=05
set RC_D_SYS=06
set RC_D_NET=07
set RC_D_STORY=08
set RC_D_DEBUG=09

:: 理由グループ
set RC_R_SELECT=01
set RC_R_IO=10
set RC_R_PARSE=11
set RC_R_ENC=12
set RC_R_NET=20
set RC_R_VALID=30
set RC_R_COMPAT=50
set RC_R_OTHER=90
```

### 4.3 `rcutil.bat`（インタフェース）
| コマンド | 役割 | 引数 |
|---|---|---|
| `_BUILD` | 8桁生成 | `S DD RR CCC` → `%ERRORLEVEL%`/`AD_RC` |
| `_DECODE` | 分解 | `<code>` → `AD_S/AD_DD/AD_RR/AD_CCC` |
| `_NAME_DOM` | ドメイン名 | `<DD>` → `AD_DNAME` |
| `_NAME_REASON` | 理由名 | `<RR>` → `AD_RNAME` |
| `_LOG_INIT` | ログ初期化 | `[dir]` → `AD_LOG` |
| `_TRACE` | 任意ログ追記 | `<LEVEL> <message...>` |
| `_THROW` | 失敗発行＆ログ | `S DD RR CCC "MSG" ["CTX"]` → `exit /b code` |
| `_RETURN` | 正常発行＆ログ | `S DD RR CCC "MSG"` → `exit /b code` |
| `_PRETTY` | 整形表示 | `<code>`（人間可読） |

> 詳細実装はプロジェクトリポジトリに同梱。各モジュールは**この API のみ**使用する。

---

## 5. 使い方（例）
### 5.1 モジュール先頭で定数読み込み
```bat
call "%PROJECT_ROOT%\Src\Systems\Debug\rc.const.bat"
```

### 5.2 正常フロー（New Game 決定）
```bat
call "%PROJECT_ROOT%\Src\Systems\Debug\rcutil.bat" _RETURN ^
  %RC_S_FLOW% %RC_D_MENU% %RC_R_SELECT% 001 "MainMenu:NewGame"
```
→ 返却コード：`10,101,001`

### 5.3 エラー（Save Slot2 not found）
```bat
if not exist "%SAVE_DIR%\slot2.sav" (
  call "%PROJECT_ROOT%\Src\Systems\Debug\rcutil.bat" _THROW ^
    %RC_S_ERR% %RC_D_SAVE% %RC_R_IO% 004 "Save missing" "slot=2;path=%SAVE_DIR%\slot2.sav%"
)
```
→ 返却コード：`90,210,004`

### 5.4 Run.bat 側で整形表示
```bat
set "RC=%errorlevel%"
call "%PROJECT_ROOT%\Src\Systems\Debug\rcutil.bat" _PRETTY %RC%
rem 出力例:  ERR  SaveData  I/O  #004  (code=90210004)
```

### 5.5 こまめなトレース
```bat
call "%PROJECT_ROOT%\Src\Systems\Debug\rcutil.bat" _TRACE TRACE "MainMenu: frame A drawn"
```

---

## 6. 互換運用（外部/未規格終了コード）
- 閾値ルール：`code < 10,000,000` は **外部 or 未規格**として扱う。  
- Run 側で `90-06-90-xxx`（Systems/Other）等に**ラップ**し、ログ化してから上位へ伝搬する。

---

## 7. 命名・メッセージ規約
- `AD_RC_TAG`：`MainMenu/SaveData/...` の**Camel/Pascal**推奨。  
- `AD_RC_MSG`：**英語ベース + 補足日本語可**（ログ検索性を重視）。  
- `CTX`：`key=value;key2=value2` の軽量 KV 文字列。

---

## 8. マイグレーション方針（旧 1000/2000 台 → v1）
- 旧：`1001(NewGame)` → 新：`1-01-01-001`（**10,101,001**）
- 旧：`1002(Continue)` → 新：`1-01-01-002`
- 旧：`1099(Exit)` → 新：`8-01-01-099`（キャンセル/戻る系に寄せる）
- 旧：`2031(Continue Slot1)` → 新：`1-02-01-001`
- 旧：`2051(New Slot1 Created)` → 新：`1-02-01-051` *（運用に合わせて `CCC` 採番を調整）*

> 置換は**rcutil ラッパー化**で一括機械化する（`exit /b`直書きを撤廃）。

---

## 9. ログ仕様
- 既定パス：`Logs/ad_YYYY-MM-DD_HH-mm-ss.log`
- レコード例：
```
[2025-08-09 01:23:45.678] OK   RC=10101001 S=1 DD=1 RR=1 CCC=1 MSG=MainMenu:NewGame
[2025-08-09 01:23:46.012] ERR  RC=90210004 S=9 DD=2 RR=10 CCC=4 MSG=Save missing CTX=slot=2;path=C:\...\slot2.sav
[2025-08-09 01:23:46.050] TRACE MainMenu: frame A drawn
```

---

## 10. テスト/レビュー チェックリスト
- [ ] すべての `exit /b` が `_RETURN` or `_THROW` に置換されている。  
- [ ] 主要分岐（Menu/Save/Display/Env/Audio/Systems/Network/Story/Debug）で**最低1件**の戻り値が規格化。  
- [ ] Run 側が `_PRETTY` で**人間可読ログ**を出す。  
- [ ] `code < 10,000,000` のラップ処理がある。  
- [ ] 即死しうる箇所に `_TRACE` を適切に挿入。  
- [ ] CI/ローカルで**異常系（S=9）**を少なくとも1件強制発火して確認。

---

## 11. FAQ
**Q. なぜ 8 桁？**  
A. 32bit 整数の安全圏内で、外部終了コードと**帯域が被りにくい**から。分解/合成が `/` と `%` だけで高速。  

**Q. ドメインや理由は増やせる？**  
A. `DD`/`RR`は 00–99 の二桁。**先に予約表を更新**してから使用する。  

**Q. “警告”や“リトライ推奨”は？**  
A. `S=2/3/4` を将来利用。現時点は `S=1/8/9` に集約。

---

## 12. 変更履歴
- **v1.0 (2025-08-09)** 初版（8桁固定／ラッパー API／ログ規約／互換運用）。

---

## 13. 付録：実装スニペット
### 13.1 BUILD/DECODE の参考実装
```bat
:_BUILD
set "S=%~1" & set "DD=%~2" & set "RR=%~3" & set "CCC=%~4"
set /a _RC=S*10000000 + DD*100000 + RR*1000 + CCC
endlocal & set "AD_RC=%_RC%" & exit /b %_RC%

:_DECODE
set "C=%~1"
set /a S  =  C / 10000000
set /a DD = (C / 100000) %% 100
set /a RR = (C / 1000)    %% 100
set /a CCC=  C %% 1000
endlocal & (
  set "AD_S=%S%"
  set "AD_DD=%DD%"
  set "AD_RR=%RR%"
  set "AD_CCC=%CCC%"
) & exit /b 0
```

---

### 署名
Author: HedgeHog（仕様合意ドラフト） / Reviewer: ChatGPT（提案と整形）
