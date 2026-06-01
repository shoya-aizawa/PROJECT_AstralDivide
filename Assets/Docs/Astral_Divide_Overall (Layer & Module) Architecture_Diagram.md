# Astral Divide Overall Layer & Module Architecture Diagram

**Project:** PROJECT_AstralDivide  
**Status:** Stable / Updated  
**Date:** 2026-05-31  

```mermaid
flowchart TB
  subgraph Platform[Windows 10/11 CMD Environment]
    CMD[cmd.exe / conhost.exe]
    PS[PowerShell 5.1+]
  end

  subgraph App[PROJECT_AstralDivide]
    subgraph Boot[1. 起動・ランチャレイヤ]
      ADB[AstralDivide.bat\n- Launch Token設定\n- ルートパス確定]
      RUN[Src/Main/Run.bat\n- モード解析\n- ブートストラップ]
      SPLASH[Src/Systems/Launcher/Splash.bat\n- 同期ブートアニメ\n- 環境/プロファイル確定]
    end

    subgraph Core[2. ゲームコアレイヤ]
      MAIN[Src/Main/Main.bat\n- メインステートループ\n- シーン遷移]

      subgraph Systems[Src/Systems/ - 基盤システムモジュール]
        subgraph Env[Environment - 環境定義]
          SETPATH[SettingPath.bat\n- サイレントパス構築]
          LOADENV[LoadEnv.bat\n- サイレントプロファイルロード]
          SCREEN[ScreenEnvironmentDetection.bat\n- 解像度・VT有効化]
        end

        subgraph Disp[Display - 画面描画]
          MMOD[Display/Modules/\nTypeWriter_v2.3.bat\nRenderMarkup_v2.3.bat\nRenderControl_v2.3.bat\nRenderScene.bat]
          MTPL[Display/Templates/\nMainMenuDisplay.txt 他]
          BOOTD[BootCompleteDisplay.bat]
          MENU[MainMenuModule.bat]
        end

        subgraph SaveSys[SaveSys - セーブ管理]
          SAVEDET[SaveDataDetectSystem.bat]
          SAVESEL[SaveDataSelector.bat]
        end

        subgraph Audio[Audio - 音響制御]
          BGMPS1[Play_BGM.ps1]
          BGMBAT[Play_BGM.bat]
        end

        subgraph Debug[Debug / RCS / Surveillance - 監査・監視・デバッグ]
          RCSU[RCS_Util.bat v0.4\n- グローバル変数 rcs_code 伝搬\n- サイレントログ記録]
          RCSC[RCS_Const.bat v0.1a\n- 8桁定数定義]
          WD[Watchdog_Host.bat\n- HUD死活監視]
          TAIL[LogTailToGAS.ps1\n- GASリモート転送]
        end
        INIT[InitializeModule.bat]
      end

      subgraph Story[Src/Stories/ - シナリオテキスト]
        Scenes[Scenes/\n00_NewGame: EnterYourName.bat, NewGame.bat ...]
        Texts[TextAssets/\n00_NewGame: *.txt ...]
      end
    end

    subgraph Assets[Assets/ - 静的リソース]
      Docs[(仕様・世界観・プロトコル)]
      Images[Images/*.png *.ico *.bmp]
      Sounds[Sounds/*.wav]
    end

    Tools[Tools/\ncmdwiz.exe, cmdgfx*.exe, cmdbkg.exe, Insertbmp.exe]
  end

  %% 依存・実行線
  ADB -->|GAME_LAUNCHER=1| RUN
  RUN -->|call| SPLASH
  SPLASH -.->|profile.env 生成| LOADENV
  
  %% Splash終了後のサイレントロードと親スコープエクスポート
  RUN -->|call SILENT| LOADENV
  RUN -->|call SILENT| SETPATH
  
  RUN -->|1. EXEC MODE| MAIN
  
  %% Watchdog / Remote Log Streamer
  RUN -->|2. call 同期監視| WD
  RUN -.->|3. start /b 非同期| TAIL
  TAIL -->|tail log| PS
  PS -->|Post to WebApp| GAS((Google Apps Script))

  MAIN --> SETPATH
  MAIN --> INIT
  MAIN --> MENU
  MENU --> SAVESEL
  SAVESEL --> SAVEDET

  MAIN --> MMOD
  MAIN --> MTPL
  MAIN --> BOOTD
  
  %% RCS依存
  App -.->|RCSログ / 戻り値統一| RCSU
  RCSU -->|依存| RCSC

  MAIN --> Scenes
  Scenes --> Texts

  SETPATH --> Assets
  SETPATH --> Tools

  Tools -.-> Disp
  PS --> BGMPS1
  CMD --> App
```

---

## 4. 主なアーキテクチャの変更点

- **RCS (Return Code System) 基盤の統合**:
  `RCS_Util.bat` v0.4 および `RCS_Const.bat` が `Debug` モジュールに統合され、ゲーム内のすべての戻り値判定、サイレントログ・エラーログ記録を一元管理しています。
- **Watchdog の同期 call 常駐**:
  通常起動時、`Run.bat` は `Main.bat` を非同期起動した直後、`Watchdog_Host.bat` を `call` で同期実行し、ゲーム本体プロセスの死活監視 HUD を常駐させます。
- **リモートログ転送 (`LogTailToGAS.ps1`)**:
  `-mode remote` 起動時、セッションログファイルから GAS への転送を担う `LogTailToGAS.ps1` が PowerShell を介してバックグラウンドで非同期実行される流れを追加しました。
- **Splash から親スコープへのサイレントロード**:
  `Splash.bat` が初期化を終えた後、`LoadEnv.bat` および `SettingPath.bat` をサイレントに `Run.bat` の親コンソールに呼び出すことで、二重ログを抑止しながら環境変数をエクスポートする構成に進化しています。
