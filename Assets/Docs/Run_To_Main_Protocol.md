# RunToMain Protocol 設計書

## 概要
`RunToMain Protocol` は、RPGGAME2024 プロジェクトにおける「Run.bat から Main.bat への」正式な起動フローを継ぐためのコミュニケーションプロトコルである。

本プロトコルは主に以下の目的を持つ:

- 安全性高い起動継続ロジック
- エンコーディング(文字コード)の指定
- 成功/失敗時の復帰コードの伝達
- モジュール分割に基づく責務分離

---

## プロトコルサマリ

### [Run.bat]
| セクション | 責務 |
|-----------|--------|
| 起動時最大化 | `@if not "%~0"=="%~dp0.\%~nx0" start /max cmd /c,"%~dp0.\%~nx0" %* & goto :eof` |
| 初期化 | 表示サイズ、Powershell 利用可能性などを検査 |
| 言語選択/エンコード | chcp 値の選択 (65001/437 etc) |
| 起動 | `start /wait /max "running" Main.bat <encoding>` |


### [Main.bat]
| セクション | 責務 |
|-----------|--------|
| 受け取り | `%1` を通してエンコーディングコードを取得 |
| 検証 | 対応していないcodepageならエラー表示、終了 |
| chcp 実行 | `chcp %1 >nul` |
| メインプログラム | UI、セーブデータ選択、シナリオ処理 etc |
| 戻り値の通知 | `exit /b <code>` で Run.bat 側に継達 |

---

## 使用例:
```bat
:: Run.bat
start /wait /max "running" Main.bat 65001
set retcode=%errorlevel%
if %retcode%==2051 echo 新規セーブデータが作成されました
```

```bat
:: Main.bat
if not "%1"=="65001" if not "%1"=="437" (
  call ErrorModule_Show.bat /msg "Unsupported encoding: %1"
  exit /b 1004
)
chcp %1 >nul
```

---

## 導入別名: `R2M-Prot` (もしくは Run→Main Protocol)

なお、本プロトコルは「Run.bat はローンチャー、Main.bat はゲーム本体」として構造化されたフレームワークの基礎であり、未来のもし分割と機能拡張を見込んだ細切なプロトコルである。

