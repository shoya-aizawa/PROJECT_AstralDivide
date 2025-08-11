```mermaid
flowchart TB
  subgraph Platform[Windows 10/11 & Console]
    CMD[cmd.exe / conhost.exe]
    PS[PowerShell]
  end

  subgraph App[PROJECT_AstralDivide]
    subgraph Boot[起動/ランチャ]
      ADB[AstralDivide.bat]
      RUN[Src/Main/Run.bat]
    end

    subgraph Core[ゲーム本体]
      MAIN[Src/Main/Main.bat]

      subgraph Systems[Src/Systems/]
        subgraph Env[Environment]
          SETPATH[SettingPath.bat]
          LOADENV[LoadEnv.bat]
          SETLANG[SetupLanguage.bat]
          SCREEN[ScreenEnvironmentDetection.bat]
          SETSTO[SetupStorageWizard.bat]
        end

        subgraph Disp[Display]
          MMOD[Display/Modules/\nTypeWriter_v2.3.bat\nRenderMarkup_v2.3.bat\nRenderControl_v2.3.bat\nRenderScene.bat]
          MTPL[Display/Templates/\nMainMenuDisplay.txt 他]
          BOOTD[BootCompleteDisplay.bat]
          MENU[MainMenuModule.bat]
        end

        subgraph SaveSys[SaveSys]
          SAVEDET[SaveDataDetectSystem.bat]
          SAVESEL[SaveDataSelector.bat]
        end

        subgraph Audio[Audio]
          BGMPS1[Play_BGM.ps1]
          BGMBAT[Play_BGM.bat]
        end

        subgraph Debug[Debug]
          PICK[InteractivePicker.bat]
          ANSI[Show_ANSI_Colors.bat]
        end
        INIT[InitializeModule.bat]
      end

      subgraph Story[Src/Stories/]
        Scenes[Scenes/\n00_NewGame: EnterYourName.bat, NewGame.bat ...]
        Texts[TextAssets/\n00_NewGame: *.txt ...]
      end
    end

    subgraph Assets[Assets/]
      Docs[Docs/*.md\n(仕様・世界観・プロトコル)]
      Images[Images/*.png *.ico *.bmp]
      Sounds[Sounds/*.wav]
    end

    Tools[Tools/\ncmdwiz.exe, cmdgfx*.exe, cmdbkg.exe, Insertbmp.exe]
  end

  %% 依存線
  ADB --> RUN
  RUN --> MAIN

  MAIN --> SETPATH
  MAIN --> INIT
  MAIN --> MENU
  MENU --> SAVESEL
  SAVESEL --> SAVEDET

  MAIN --> MMOD
  MAIN --> MTPL
  MAIN --> BOOTD
  MAIN --> BGMPS1

  MAIN --> Scenes
  Scenes --> Texts

  SETPATH --> Assets
  SETPATH --> Tools

  SCREEN -->|検出結果 .env| LOADENV
  RUN -->|profile.env| LOADENV
  SETLANG -->|profile.env| LOADENV

  Tools -.外部ユーティリティ.-> Disp
  PS --> BGMPS1
  CMD --> App
```