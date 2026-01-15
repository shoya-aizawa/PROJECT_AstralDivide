# LogWatcher.ps1
param(
  [Parameter(Mandatory=$true)][string]$GasUrl,
  [Parameter(Mandatory=$false)][string]$AdminKey = "admin"
)

Write-Host "=== Remote Log Watcher v0.1 ==="

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$since = 0
$lastHb = Get-Date 0

function Sanitize([string]$s) {
  if ($null -eq $s) { return "" }
  $s = $s -replace "`r", "\r"
  $s = $s -replace "`n", "\n"
  $s = $s -replace "`t", "    "
  return $s
}

function Post-Form([hashtable]$body) {
  Invoke-RestMethod -Uri $GasUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded; charset=utf-8"
}

function Get-Json([string]$url) {
  Invoke-RestMethod -Uri $url -Method GET
}

Write-Host "GAS url: $GasUrl"
if (-not $AdminKey) {
  Write-Host "[WARN] AdminKey is empty. Approve/Deny and heartbeat will fail." -ForegroundColor Yellow
}

while ($true) {
  try {
    $now = Get-Date

    # 1) Admin heartbeat
    if ($AdminKey -and ($now - $lastHb).TotalSeconds -ge 8) {
      Post-Form @{ action="admin_heartbeat"; admin_key=$AdminKey } | Out-Null
      $lastHb = $now
    }

    # 2) Obtain connection request - Approve/Reject
    if ($AdminKey) {
      $pending = Get-Json ($GasUrl + "?action=get_pending")
      if ($pending.ok -and $pending.pending.Count -gt 0) {
        foreach ($p in $pending.pending) {
          $rid = [string]$p.req_id
          $uid = [string]$p.user_id
          $hst = [string]$p.host

          Write-Host ""
          Write-Host ("ID:{0} is requesting permission to connect host={1}" -f $uid, $hst) -ForegroundColor Yellow
          $ans = Read-Host "Approve? (Y/N)"

          if ($ans -match '^[Yy]') {
            $r = Post-Form @{ action="approve"; admin_key=$AdminKey; req_id=$rid }
            if ($r.ok) { Write-Host "[OK] approved." -ForegroundColor Cyan }
            else { Write-Host ("[ERR] approve failed: {0}" -f $r.reason) -ForegroundColor Red }
          } else {
            $r = Post-Form @{ action="deny"; admin_key=$AdminKey; req_id=$rid }
            if ($r.ok) { Write-Host "[OK] denied." -ForegroundColor DarkYellow }
            else { Write-Host ("[ERR] deny failed: {0}" -f $r.reason) -ForegroundColor Red }
          }
        }
      }
    }

    # 3) Log acquisition (compatible with since API without action)
    $uri = $GasUrl + "?since=$since"
    $obj = Get-Json $uri

    foreach ($log in $obj.logs) {
      $msg = Sanitize ([string]$log.message)
      Write-Host -ForegroundColor Green $msg
      if ([int]$log.row -gt $since) { $since = [int]$log.row }
    }

  } catch {
    Write-Host ("Error in watcher: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }

  Start-Sleep -Seconds 1
}
