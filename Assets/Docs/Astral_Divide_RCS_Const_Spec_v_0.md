# Astral Divide RCS Const Specification (v0.1a)

**Project:** PROJECT_AstralDivide / HedgeHogSoft  
**Module:** `RCS_Const.bat`  
**Version:** v0.1a (for RCS_Util v0.3a)  
**Date:** 2025-10-22  
**Author:** 愛澤翔也 (HedgeHog)  

---

## 1. 目的と範囲

`RCS_Const.bat` は、Astral Divide の **Return Code System（RCS）** における  
「定数定義レイヤ」を担うバッチモジュールである。

本モジュールは、`RCS_Util.bat`によるコード生成（`-build`, `-return`, `-throw` 等）を補完し、  
各**区分（S）・ドメイン（DD）・理由（RR）**を定義済みのシンボルとして一元管理する。

---

## 2. 位置づけと依存関係

```
Src/
└─ Systems/
   └─ Debug/
      ├─ RCS_Const.bat   ← 本モジュール（定数定義）
      └─ RCS_Util.bat    ← コード生成・ログ出力機構（v0.3a）
```

依存関係:  
`RCS_Util.bat` → `RCS_Const.bat`  
（ConstはUtilの前提条件として呼び出される）

---

## 3. 命名規約とポリシー

| 種別 | 命名規則 | 例 | 備考 |
|------|-----------|----|------|
| 通常変数 | スネークケース | `session_id`, `return_code` | 通常モジュール向け |
| 定数 | 全大文字＋アンダースコア | `RCS_S_FLOW`, `RCS_D_SYS` | **本ファイル対象** |
| デバッグ変数 | 全大文字 | `RC_LAST`, `RCS_EXIT` | ログ・診断用 |

- **すべての定数は `RCS_` プレフィックス**を持つ。  
- `setlocal` 有効下でも**上位スコープに反映可能なように `endlocal & (...)` 形式を許可**。  
- `echo` は禁止（読み込み時にコンソール出力しない）。

---

## 4. 定数定義モデル

RCSコードは `S-DD-RR-CCC` 形式（例：`1-06-10-001`）。  
このうち `S`, `DD`, `RR` を本モジュールで定義する。

### 4.1 区分（S）
| 名称 | 値 | 意味 |
|------|---:|------|
| `RCS_S_FLOW`   | `1` | 正常フロー（完了・選択・処理継続） |
| `RCS_S_CANCEL` | `8` | ユーザ中断・戻る・キャンセル |
| `RCS_S_ERR`    | `9` | エラー・異常終了（要修復） |
| `RCS_S_INFO`   | `2` | 情報系（将来拡張） |
| `RCS_S_WARN`   | `3` | 警告・非致命（将来拡張） |

---

### 4.2 ドメイン（DD）
| 名称 | 値 | 対象領域 |
|------|---:|----------|
| `RCS_D_MENU`   | `01` | タイトル/メインメニュー |
| `RCS_D_SAVE`   | `02` | セーブ/ロード関連 |
| `RCS_D_DISPLAY`| `03` | 画面描画/テンプレート |
| `RCS_D_ENV`    | `04` | 環境・コードページ・画面情報 |
| `RCS_D_AUDIO`  | `05` | BGM/SE 再生関連 |
| `RCS_D_SYS`    | `06` | 初期化・プロセス・起動系 |
| `RCS_D_NET`    | `07` | 通信/GAS/HTTP |
| `RCS_D_STORY`  | `08` | シナリオ/テキスト資源 |
| `RCS_D_DEBUG`  | `09` | デバッグ・インターセプト |

---

### 4.3 理由（RR）
| 名称 | 値 | 内容 |
|------|---:|------|
| `RCS_R_SELECT` | `01` | 選択/決定/入力系 |
| `RCS_R_IO`     | `10` | ファイル入出力/権限系 |
| `RCS_R_PARSE`  | `11` | 構文解析/読み込み失敗 |
| `RCS_R_ENC`    | `12` | エンコード/文字コード/JSON |
| `RCS_R_NET`    | `20` | 通信・接続タイムアウト |
| `RCS_R_VALID`  | `30` | 検証・事前条件不成立 |
| `RCS_R_COMPAT` | `50` | バージョン/互換性不一致 |
| `RCS_R_OTHER`  | `90` | その他分類不能 |

---

## 5. 推奨運用と呼び出し例

### 5.1 読み込み
```bat
call "%project_root%\Src\Systems\Debug\RCS_Const.bat"
```

### 5.2 利用例
```bat
:: 新規ゲーム開始（正常フロー）
call rcs_util -return %RCS_S_FLOW% %RCS_D_MENU% %RCS_R_SELECT% 001 "MainMenu:NewGame"

:: セーブデータ欠損（エラー）
call rcs_util -throw %RCS_S_ERR% %RCS_D_SAVE% %RCS_R_IO% 004 "Save missing" "slot=2;path=%save_dir%\slot2.sav"
```

### 5.3 結果ログ
```
[2025-10-22 13:40:01.125] [OK] MainMenu NewGame RC=10101001
[2025-10-22 13:40:02.452] [ERR] SaveData I/O  RC=90210004 slot=2;path=...
```

---

## 6. 設計方針詳細

| ポリシー項目 | 内容 |
|---------------|------|
| **静音ロード** | Const読込時は何も出力しない（echo禁止） |
| **上位互換** | RECS v1の定義群を継承・命名をRCS規格化 |
| **展開形式** | `set`命令を連続で列挙し、関数・条件分岐を持たない |
| **範囲** | `S/DD/RR` のみ定義（CCCは利用側で自由） |
| **モジュール化** | RCS_Util.bat以外からの直接利用も許可（他Systems共用） |
| **整合性維持** | RCS_Utilの`-decode`出力と一致するよう整数値固定 |

---

## 7. 拡張計画（v0.2 以降）

| バージョン | 機能候補 |
|-------------|-----------|
| v0.2 | 定義群に `RCS_DOMAIN_NAME_MAP` / `RCS_REASON_NAME_MAP` を追加し、人間可読化 |
| v0.3 | `rcs_util -name domain <DD>` による動的解決に統合 |
| v0.4 | **Codex連携**：自動定数生成・エラー辞書同期 |
| v1.0 | JSONエクスポート機能（`Const → Codex`）による全システム整合性保証 |

---

## 8. ヘッダー定義例（実装参考）

```bat
@echo off
rem ===========================================================
rem  Astral Divide Return Code System Const (v0.1a)
rem  by HedgeHogSoft / PROJECT_AstralDivide
rem  Dependency: RCS_Util v0.3a+
rem ===========================================================

:: 区分 (Section)
set RCS_S_FLOW=1
set RCS_S_CANCEL=8
set RCS_S_ERR=9
set RCS_S_INFO=2
set RCS_S_WARN=3

:: ドメイン (Domain)
set RCS_D_MENU=01
set RCS_D_SAVE=02
set RCS_D_DISPLAY=03
set RCS_D_ENV=04
set RCS_D_AUDIO=05
set RCS_D_SYS=06
set RCS_D_NET=07
set RCS_D_STORY=08
set RCS_D_DEBUG=09

:: 理由 (Reason)
set RCS_R_SELECT=01
set RCS_R_IO=10
set RCS_R_PARSE=11
set RCS_R_ENC=12
set RCS_R_NET=20
set RCS_R_VALID=30
set RCS_R_COMPAT=50
set RCS_R_OTHER=90

exit /b 0
```

---

## 9. 最終指針

> **Philosophy:**  
> _“Define once, use everywhere.”_  
>  
> RCS_Const.bat は Astral Divide の全プロセスに共通する**数値辞書**であり、  
> その役割は「秩序」と「一貫性」の維持にある。  
> どのモジュールもこのファイルを参照することで、  
> 返却コードの意味・形式が統一されることを保証する。

---

**End of Document – RCS_Const Specification v0.1a**

