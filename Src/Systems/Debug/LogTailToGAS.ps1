# LogTailToGAS.ps1 (Client)
param(
  [Parameter(Mandatory=$true)][string]$LogPath,
  [Parameter(Mandatory=$true)][string]$GasUrl,
  [string]$ClientName = "",
  [string]$SessionToken = "",
  [int]$BatchLines = 30,
  [int]$FlushMs = 250,
  [int]$PollSeconds = 2,
  [int]$IdleSleepMs = 120,
  [string]$StopFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

function ConvertTo-Sha256Hex([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $hash = $sha.ComputeHash($bytes)
  ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
}
function Invoke-FormRequest([hashtable]$body) {
  Invoke-RestMethod -Uri $GasUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded; charset=utf-8"
}
function Get-Json([string]$url) {
  Invoke-RestMethod -Uri $url -Method GET
}
function Test-StopRequested {
  if (-not $StopFile) { return $false }
  return (Test-Path -LiteralPath $StopFile)
}

if (-not (Test-Path -LiteralPath $LogPath)) {
  throw "Log file not found: $LogPath"
}

$hostId = if ($ClientName.Trim()) { $ClientName.Trim() } else { "$env:USERNAME@$env:COMPUTERNAME" }

Write-Host "=== Remote Tail Client ==="
Write-Host "Host: $hostId"
Write-Host "Log : $LogPath"
Write-Host ""

$token = ""
if ($SessionToken.Trim()) {
  $token = $SessionToken.Trim()
  Write-Host "[OK] pre-approved token provided. tail starts immediately." -ForegroundColor Green
} else {
  $userId = Read-Host "User ID"
  $pass   = Read-Host "Password" -AsSecureString
  $passPlain = [Runtime.InteropServices.Marshal]::PtrToStringUni([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
  $passHash  = ConvertTo-Sha256Hex $passPlain

  Write-Host "[*] requesting join..."

  $req = Invoke-FormRequest @{
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
}

# ---- streaming ----
$buffer = New-Object System.Collections.Generic.List[string]
$lastFlush = [DateTime]::UtcNow

function Clear-LogBuffer {
  if ($buffer.Count -le 0) { return }

  # snapshot -> clear（送信中に追記されても壊れない）
  $toSend = $buffer.ToArray()
  $buffer.Clear()

  try {
    $batchJson = ConvertTo-Json -InputObject @($toSend) -Compress
    $r = Invoke-FormRequest @{
      action        = "post_log_batch"
      session_token = $token
      logs_json     = $batchJson
    }

    if ($r -and $r.ok -eq $false -and $r.reason -eq "BAD_SESSION") {
      Write-Host "[DENY] session revoked/expired (kicked). exiting..." -ForegroundColor Red
      exit 2
    }

    if ($r -and $r.ok -eq $false -and $r.reason -eq "UNKNOWN_ACTION") {
      foreach ($line in $toSend) {
        $legacy = Invoke-FormRequest @{
          action        = "post_log"
          session_token = $token
          log           = $line
        }

        if ($legacy -and $legacy.ok -eq $false -and $legacy.reason -eq "BAD_SESSION") {
          Write-Host "[DENY] session revoked/expired (kicked). exiting..." -ForegroundColor Red
          exit 2
        }
      }
    }

    $script:lastFlush = [DateTime]::UtcNow
  } catch {
    # 失敗時は戻す（ただし肥大防止）
    foreach ($line in $toSend) { $buffer.Add($line) }
    if ($buffer.Count -gt 2000) { $buffer.RemoveRange(0, $buffer.Count - 2000) }
    Write-Host ("[ERR] send failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }
}

Write-Host "[*] streaming..." -ForegroundColor DarkCyan

# Get-Content -Wait だと「新規行が来ないとFlush判定が走らない」問題が出るので、
# StreamReaderで自前ループ（一定間隔でFlush判定できる）
$fs = [System.IO.File]::Open($LogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$sr = New-Object System.IO.StreamReader($fs)
$fileInfo = New-Object System.IO.FileInfo($LogPath)

try {
  # 末尾に移動（Tail 0 相当）
  $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null

  while ($true) {
    if (Test-StopRequested) {
      Write-Host "[OK] stop signal detected. exiting streamer." -ForegroundColor DarkGray
      break
    }

    $line = $sr.ReadLine()

    if ($null -ne $line) {
      $buffer.Add($line)

      if ($buffer.Count -ge $BatchLines) {
        Clear-LogBuffer
      }
      continue
    }

    # EOF reached. Check if file size increased.
    $fileInfo.Refresh()
    if ($fs.Position -lt $fileInfo.Length) {
      # Clear internal buffer to allow reading newly appended content
      $sr.DiscardBufferedData()
      continue
    }

    # If no new content, run Flush check
    $now = [DateTime]::UtcNow
    if ($buffer.Count -gt 0 -and ($now - $lastFlush).TotalMilliseconds -ge $FlushMs) {
      Clear-LogBuffer
    }

    Start-Sleep -Milliseconds $IdleSleepMs
  }
}
finally {
  try { Clear-LogBuffer } catch {}
  $sr.Close()
  $fs.Close()
}
