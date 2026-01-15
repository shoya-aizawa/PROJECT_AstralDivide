# LogTailToGAS.ps1 (fixed)
param(
  [Parameter(Mandatory=$true)][string]$LogPath,
  [Parameter(Mandatory=$true)][string]$GasUrl,
  [string]$ClientName = "",
  [int]$BatchLines = 30,
  [int]$FlushMs = 600,
  [int]$PollSeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

function To-Sha256Hex([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $hash = $sha.ComputeHash($bytes)
  ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Post-Form([hashtable]$body) {
  Invoke-RestMethod -Uri $GasUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded; charset=utf-8"
}
function Get-Json([string]$url) {
  Invoke-RestMethod -Uri $url -Method GET
}

if (-not (Test-Path -LiteralPath $LogPath)) {
  throw "Log file not found: $LogPath"
}

$hostId = if ($ClientName.Trim()) { $ClientName.Trim() } else { "$env:USERNAME@$env:COMPUTERNAME" }

Write-Host "=== Remote Tail Client ==="
Write-Host "Host: $hostId"
Write-Host "Log : $LogPath"
Write-Host ""

$userId = Read-Host "User ID"
$pass   = Read-Host "Password" -AsSecureString
$passPlain = [Runtime.InteropServices.Marshal]::PtrToStringUni([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
$passHash  = To-Sha256Hex $passPlain

Write-Host "[*] requesting join..."

$req = Post-Form @{
  action    = "request_join"
  user_id   = $userId
  pass_hash = $passHash
  host      = $hostId
}

if (-not $req.ok) {
  Write-Host ("[DENY] {0}" -f $req.reason) -ForegroundColor Red
  Read-Host "Press Enter to exit..."
  exit 1
}

$reqId = [string]$req.req_id
Write-Host "[OK] request sent. waiting approval..." -ForegroundColor Cyan

$token = ""
while ($true) {
  Start-Sleep -Seconds $PollSeconds
  $st = Get-Json ($GasUrl + "?action=join_status&req_id=" + [uri]::EscapeDataString($reqId))
  if (-not $st.ok) { continue }

  if ($st.status -eq "DENIED") {
    Write-Host "[DENY] request denied by admin." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
  }
  if ($st.status -eq "APPROVED" -and $st.session_token) {
    $token = [string]$st.session_token
    Write-Host "[OK] approved. tail starts." -ForegroundColor Green
    break
  }
}

# ---- streaming ----
$buffer = New-Object System.Collections.Generic.List[string]
$lastFlush = [DateTime]::UtcNow

function Flush-Buffer {
  if ($buffer.Count -le 0) { return }

  # 送信対象をスナップショット化してからクリア（送信中に追加されても破綻しない）
  $toSend = $buffer.ToArray()
  $buffer.Clear()

  try {
    foreach ($line in $toSend) {
      Post-Form @{
        action        = "post_log"
        session_token = $token
        log           = $line
      } | Out-Null
    }
    $script:lastFlush = [DateTime]::UtcNow
  } catch {
    # 失敗時は戻して再送可能に（ただし肥大を防ぐ）
    foreach ($line in $toSend) { $buffer.Add($line) }
    if ($buffer.Count -gt 2000) { $buffer.RemoveRange(0, $buffer.Count - 2000) }
    Write-Host ("[ERR] send failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }
}

Write-Host "[*] streaming..." -ForegroundColor DarkCyan

# ここが肝：-Wait を ReadLine でブロックさせず、短いタイムアウトで回す
$fs = [System.IO.File]::Open($LogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$sr = New-Object System.IO.StreamReader($fs)

try {
  # ファイル末尾までシーク（-Tail 0 相当）
  $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null

  while ($true) {
    # 1行読めるなら読む（読めないなら $null）
    $line = $sr.ReadLine()

    if ($null -ne $line) {
      $buffer.Add($line)

      # 行数でFlush
      if ($buffer.Count -ge $BatchLines) {
        Flush-Buffer
      }
      continue
    }

    # 行が無い（= 新規追記待ち）ので、時間でFlush判定してから少し待つ
    $now = [DateTime]::UtcNow
    if ($buffer.Count -gt 0 -and ($now - $lastFlush).TotalMilliseconds -ge $FlushMs) {
      Flush-Buffer
    }

    Start-Sleep -Milliseconds 200
  }
}
finally {
  try { Flush-Buffer } catch {}
  $sr.Close()
  $fs.Close()
}
