# RCS — Return Code System (Protocol & Implementation Spec) v0.2  
**Project:** PROJECT_AstralDivide / HedgeHogSoft  
**Doc type:** Design Spec (.md)  
**Status:** Draft (adoptable)  
**Date:** 2025-10-22 (JST)

---

## 0) 目的 (Why RCS?)
旧RECS/AD_RCの“生数値比較・人力発行・分散ログ”をやめ、**安全・可読・一元管理**の戻り値/エラー運用を実現する。  
RCSは **8桁コードの標準化＋ユーティリティ（RCS_Util.bat）＋定数定義（RCS_Const.bat）** を中核に、Run/Main/各モジュールから同じ作法で発行・判定・記録できる基盤を提供する。

---

## 1) コード体系 (8桁：`SDDRRCCC`)
- **S (1桁 / State)**: 1=FLOW（正常続約） / 8=CANCEL（ユーザ中断） / 9=ERROR（異常）  
- **DD (2桁 / Domain)**: 処理領域（例：01=Menu, 02=Save, 03=Display, 04=Env, 05=Audio, 06=Systems, 07=Network, 08=Story, 09=Debug）  
- **RR (2桁 / Reason)**: 原因カテゴリ（例：01=Selection, 10=I/O, 11=Parse, 12=Encode, 20=Network, 30=Validation, 50=Compat, 90=Other）  
- **CCC (3桁 / Case)**: 個別番号（001–999）

> 例：`90210004` = ERROR / Save / I/O / ケース4  
> 例：`10101001` = FLOW / Menu / Selection / ケース1

---

## 2) 必須コンポーネント
### 2.1 `RCS_Util.bat`（実装済み v0.2）
**役割**: コード生成・分解・整形出力・ログ追記・コンテキスト（発行元）推定  
**コマンド**:
- `-build  S DD RR CCC` → `%ERRORLEVEL%`にコード返却
- `-decode <CODE>` → `rcs_s rcs_dd rcs_rr rcs_ccc`を環境変数に展開
- `-return S DD RR CCC "Message"`→ 画面出力＋ログ追記＋コード返却（FLOW）
- `-throw  S DD RR CCC "Message"`→ 画面出力＋ログ追記＋コード返却（ERROR）
- `-pretty <CODE>` → 人間可読1行出力
- `-trace  <LEVEL> "Message"` → ログ追記（INFO/OK/WARN/ERR）

**設計ポイント**:
- `-ctx` 省略可: 未指定なら**呼び出し元パスを自動推定**(`%~dp0`)。`PROJECT_ROOT`あれば相対化  
- **ASCII固定**: Context行の接頭辞は常に`>`  
- **ログ先切替**: `RCS_LOG_DIR`（なければ `PROJECT_LOG_DIR`、それもなければ `.ログ`）  
- **自己再引用安定化**: `SELF_PATH=%~f0`を先頭固定  
- **比較原則**: `if errorlevel`禁止。`-decode`→`if "%rcs_s%"=="1"`で判定

### 2.2 `RCS_Const.bat`（旧ReturnCodeConst相当 / 作成予定）
**目的**: S/DD/RRの定数を集中定義し、魔法数を排除  
例:
```bat
@echo off
set RC_S_FLOW=1
set RC_S_CANCEL=8
set RC_S_ERR=9
set RC_D_MENU=01
set RC_D_SAVE=02
set RC_R_SELECT=01
set RC_R_IO=10
exit /b 0
```

---

## 3) 呼び出し例
```bat
call RCS_Util.bat -return %RC_S_FLOW% %RC_D_MENU% %RC_R_SELECT% 001 "MainMenu:NewGame"
call RCS_Util.bat -throw  %RC_S_ERR%  %RC_D_SAVE% %RC_R_IO%     004 "Save missing"
call RCS_Util.bat -decode %errorlevel%
if "%rcs_s%"=="1" (rem OK) else (rem FAIL)
call RCS_Util.bat -pretty %errorlevel%
call RCS_Util.bat -trace INFO "Run start"
```

---

## 4) Context
自動推定(`%~dp0`)。PROJECT_ROOTあれば相対化。
```
[ERR] rc=90210004 ERROR 02 10 004 "Save missing"
> Context: Src\Systems\SaveSys\
```

---

## 5) ログ
- 追記先: `RCS_LOG_DIR`>「PROJECT_LOG_DIR」>「.\Logs」  
- 命名: `rcs_YYYY-MM-DD_HH-mm-ss.log`
- 出力: `-trace` / `-return` / `-throw`
- 将来: 統一ログ基盤と連携可

---

## 6) R2Mへの組み込み
- Run.batは各ステージ後に`-decode`で`S==1`判定み続行  
- Main.batはstart起動（非待機）、終了原因はWatchdogで判定  
- Watchdog_HostはRunからcall  
- `<10,000,000`はSystems/Otherでラップ

---

## 7) マイグレーションガイド
1. `_return`→`-return`
2. 数値比較撤帰
3. AD_RC変数排除→rcs_  
4. echoログ→-trace
5. ctx自動

---

## 8) Run.bat例
```bat
call LaunchGuard.bat "%PROJECT_ROOT%"
call RCS_Util.bat -decode %errorlevel%
if not "%rcs_s%"=="1" goto :Fail
```

---

## 9) 今後の作業予定
- RCS_Const.batの自動生成 (Excel/CSV→bat)
- `-inspect`でJSON風出力
- `-format ascii|utf8`切替
- `RCS_SILENT=1`で静音モード
- 名称辞書追加
- Watchdog連携とIPC対応

---

Author: HedgeHog (Owner) / Editor: ChatGPT

