# Astral Divide — 重要ファイルのデジタル署名検証仕様（Signature Protocol v1)

**Project**: PROJECT_AstralDivide / HedgeHogSoft  
**Scope**: バランス/進行に関わる“クリティカルな数値ファイル”の**改ざん検知**  
**Status**: v1.0（Draft）  
**Date**: 2025-08-09 (JST)

---

## 0. 目的と要約
- **チェックサム（ハッシュ）ではなく公開鍵暗号の『デジタル署名』で守る**。ユーザーがファイルを書き換えても**秘密鍵が無ければ再署名できない**ため、強固に改ざんを検出できる。
- 署名は**ビルド/パッケージ時に付与**し、起動時（Run.bat フェーズ）に**検証**する。
- 返却値は **AD_RC v1（`S DD RR CCC`）準拠**。失敗時は**即終了**（Fail-Fast）。

---

## 1. 対象範囲（Sign Targets）
### 1.1 署名対象の定義
- 戦闘/育成/経済バランスに影響しうる**静的データ**：
  - `Src/Data/EnemyData/*.dat`、`Src/Data/ItemData/*.dat`、`Src/Data/PlayerData/*.dat`
  - `Assets/Docs/*` のうちゲームロジックが参照する**定数表/パラメータ表**
  - まとめ済みの大きな `GameData.dat`（アーカイブ）

> 将来的に**動的ダウンロード資産**を導入する場合は、別途**オンライン署名/鍵ローテーション仕様**を策定（v2）。

### 1.2 ターゲット宣言ファイル
- `Config/sign_targets.lst`（UTF-8, 1行1パス, ルートからの相対）
  ```
  Src/Data/EnemyData/core.dat
  Src/Data/ItemData/shop_table.dat
  GameData.dat
  ```

---

## 2. 鍵管理（Key Management）
- アルゴリズム: **RSA 2048bit + SHA-256**（既定）。
- **秘密鍵（private_key.xml）**は**開発PC/CIの秘密ストレージ**に保管し、**リポジトリには絶対に入れない**。
- **公開鍵（public_key.xml）**は配布物に含める。
- **指紋（PUBKEY_SHA256）**を Run 側に**ハードコード**し、起動時に `public_key.xml` のハッシュと**一致検査**して差し替え攻撃を抑止。
- 鍵ローテーション: `KEY_ID` を導入し、許容**複数指紋**（`PUBKEY_ALLOWLIST[]`）を保持（移行期間のみ）。

---

## 3. ビルド時フロー（署名の付与）
### 3.1 PowerShell 例（CI/手元ビルド）
```powershell
# RSA 2048bit の鍵ペア生成（初回のみ）
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider 2048
$priv = $rsa.ToXmlString($true)
$pub  = $rsa.ToXmlString($false)
$priv | Out-File private_key.xml -Encoding ASCII
$pub  | Out-File public_key.xml  -Encoding ASCII
```

```powershell
# 署名（対象ファイルごとに .sig を作成）
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
$rsa.FromXmlString((Get-Content private_key.xml))
Get-Content Config/sign_targets.lst | ForEach-Object {
  $path = $_
  $data = Get-Content $path -Encoding Byte
  $sig  = $rsa.SignData($data, 'SHA256')
  [Convert]::ToBase64String($sig) | Out-File "$path.sig" -Encoding ASCII
}
```

> **配布物に含める**: `public_key.xml` と各 `*.sig`。**含めない**: `private_key.xml`。

---

## 4. ランタイム検証（Run 起動前段）
### 4.1 配置
```
Src/Systems/Security/VerifySignatures.bat
Config/sign_targets.lst
public_key.xml              ← 配布同梱
```

### 4.2 仕様
- **検証順序**: `public_key.xml` → ターゲット列挙 → **各ファイルの .sig を検証**。
- **PS 依存**: PowerShell 5.1+ を必須（`Env_Probe` で事前確認）。
- **検証失敗**: **即終了（Fail-Fast）**。タイトル前に止める。

### 4.3 返却コード（AD_RC v1）
- **OK**: `AD_RC=1-06-90-000`（FLOW / Systems / Other / 000）
- **public_key.xml 不在/読込不可**: `AD_RC=9-06-10-001`（ERR / Systems / I-O / 001）
- **public_key.xml 指紋不一致**: `AD_RC=9-06-30-010`（ERR / Systems / Validation / 010）
- **sign_targets.lst 不在/空**: `AD_RC=9-06-10-011`
- **.sig 不在**: `AD_RC=9-06-10-012`（対象ファイルごとに `CCC` を割当可）
- **署名検証 NG**: `AD_RC=9-06-30-021`
- **PowerShell 非対応**: `AD_RC=9-04-50-010`（ERR / Environment / Compat / 010）

> 具体コードは `rcutil.bat` で生成し、ログには `AD_RC`/`AD_RC_TAG=Security`/`AD_RC_MSG=...` を併記。

### 4.4 擬似実装（VerifySignatures.bat）
```bat
@echo off & setlocal EnableDelayedExpansion
set "ROOT=%~dp0..\..\..\" & set "CFG=%ROOT%Config" & set "SEC=%~dp0"
set "PUB=%ROOT%public_key.xml" & set "LST=%ROOT%Config\sign_targets.lst"

rem -- 1) PowerShell 有無
powershell -NoLogo -c "$PSVersionTable.PSVersion.Major" >nul 2>&1 || (
  call rcutil.bat RETURN ERR ENV COMPAT 010 Security "PowerShell missing" & exit /b %errorlevel%
)

rem -- 2) 公開鍵ファイル & 指紋照合
if not exist "%PUB%" (
  call rcutil.bat RETURN ERR SYS IO 001 Security "pubkey missing" & exit /b %errorlevel%
)
for /f %%H in ('powershell -NoLogo -c "(Get-FileHash '%PUB%' -Algorithm SHA256).Hash"') do set "PUBHASH=%%H"
call rcutil.bat EXPECT_PUBKEY %PUBHASH% || (
  call rcutil.bat RETURN ERR SYS VALID 010 Security "pubkey fingerprint mismatch" & exit /b %errorlevel%
)

rem -- 3) ターゲット列挙
if not exist "%LST%" (
  call rcutil.bat RETURN ERR SYS IO 011 Security "targets list missing" & exit /b %errorlevel%
)
for /f "usebackq delims=" %%P in ("%LST%") do (
  if "%%~P"=="" (rem skip) else (
    set "FILE=%ROOT%%%~P"
    set "SIG=%ROOT%%%~P.sig"
    if not exist "!FILE!" (
      call rcutil.bat TRACE WARN SYS IO 012 Security "target missing: %%P" & goto :continue
    )
    if not exist "!SIG!" (
      call rcutil.bat RETURN ERR SYS IO 012 Security "sig missing: %%P" & exit /b %errorlevel%
    )
    powershell -NoLogo -c "^$rsa=New-Object System.Security.Cryptography.RSACryptoServiceProvider; ^
      ^$rsa.PersistKeyInCsp=$false; ^
      ^$rsa.FromXmlString((Get-Content '%PUB%')); ^
      ^$d=Get-Content '%ROOT%%%~P' -Encoding Byte; ^
      ^$s=[Convert]::FromBase64String((Get-Content '%ROOT%%%~P.sig')); ^
      if(-not ^$rsa.VerifyData(^$d,'SHA256',^$s)){exit 1}else{exit 0}" || (
        call rcutil.bat RETURN ERR SYS VALID 021 Security "sig verify NG: %%P" & exit /b %errorlevel%
      )
  )
  :continue
)

call rcutil.bat RETURN FLOW SYS OTHER 000 Security "all signatures OK" & exit /b %errorlevel%
```

> `rcutil.bat` は `RETURN <S> <DD> <RR> <CCC> <TAG> <MSG>` のような薄ラッパーを想定（詳細は標準書参照）。`EXPECT_PUBKEY` は Run 側に埋めた**許容指紋リスト**との照合ヘルパ。

---

## 5. Run への統合ポイント
- **Run.bat フロー**
  1) LaunchGuard → Bootstrap → Env_Probe（PowerShell 有無もここで）
  2) **VerifySignatures.bat**（ここで Fail-Fast）
  3) GameStart（Main 起動）
- **Main 側**は署名検証結果を再チェックしない（Run で止め切る）。

---

## 6. セキュリティ設計（脅威と対策）
### 6.1 脅威モデル
- **ファイル改ざん**（数値/表の書換え）
- **署名偽造**（.sig を新しく作る）
- **公開鍵差し替え**（`public_key.xml` を自作鍵に置換）
- **ACK/INTERCEPT を使った迂回**（dev専用機構の悪用）

### 6.2 対策まとめ
- 改ざん → **秘密鍵で署名**、ランタイムで Verify。  
- 署名偽造 → **秘密鍵は配布しない**、CIでのみ保有。  
- 公開鍵差し替え → **ハードコードされた指紋**で**一致検査**。  
- INTERCEPT 迂回 → **release では `PATCH/DEMO_INPUT/ABORT` 無効**、`.caps` がない限り `SHOW_HINT` も拒否。

### 6.3 運用
- 秘密鍵の**オフライン保管**、ローテーション時は `KEY_ID` と複数指紋許容。
- `Logs/security.ndjson` へ**二重記録**（検証結果・失敗理由・対象ファイル）。
- 失敗時は **ユーザー向けメッセージ**も表示（簡潔に：再インストール/破損可能性/問い合わせ先）。

---

## 7. パフォーマンス/可用性
- 署名検証は**起動時1回**。`mtime` キャッシュ（`Config/sign_cache.env`）を用い、
  `GameData.dat` など大きなファイルは**変更時のみ再検証**（ハッシュ値と時刻で早期スキップ）。
- PowerShell 不在時は **ERR で停止**（release）。開発時は `ALLOW_INSECURE_DEV=1` で**一時回避**可（ログ警告）。

---

## 8. 将来拡張（v2 候補）
- **マニフェスト方式**：`sign_manifest.json` に `{path, sig, key_id}` を列挙し、ファイル数が多い場合の配布簡略化。
- **複数アルゴリズム**：`RSA-3072` / `ECDSA P-256` 切替。
- **タイムスタンプ**：署名時刻の保存と**期限チェック**（リプレイ攻撃対策強化）。
- **オンライン鍵配布**：配布後に公開鍵の差し替えが必要になった場合の**セキュア更新**手順。

---

## 付録A：OpenSSL 派生手順（任意）
```bash
# 参考：OpenSSL での鍵生成/署名
openssl genrsa -out private_key.pem 2048
openssl rsa -in private_key.pem -pubout -out public_key.pem
# 署名（SHA-256）
openssl dgst -sha256 -sign private_key.pem -out GameData.sig GameData.dat
# 検証
openssl dgst -sha256 -verify public_key.pem -signature GameData.sig GameData.dat
```

---

## 付録B：UI 文言（失敗時）
- **JP**: 「ゲームの整合性チェックに失敗しました。再インストールをお試しください。改善しない場合はサポートへご連絡ください。」
- **EN**: "Integrity check failed. Please reinstall the game. If the issue persists, contact support."

---

**この仕様は AD_RC v1 に準拠**し、Run.bat の初期化シーケンスへ統合する。署名対象の見直し・鍵ローテーション・PS依存の緩和は今後の運用で適宜更新すること。

