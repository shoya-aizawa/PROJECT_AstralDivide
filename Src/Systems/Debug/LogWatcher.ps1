# LogWatcher.ps1 (Admin Console) - session_id (Plan B) integrated
param(
  [Parameter(Mandatory=$true)][string]$GasUrl,
  [Parameter(Mandatory=$true)][string]$AdminKey
)

# アドミン識別子
$adminId = "$env:USERNAME@$env:COMPUTERNAME"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

function Post-Form([hashtable]$body) {
  Invoke-RestMethod -Uri $GasUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded; charset=utf-8"
}
function Get-Json([string]$url) {
  Invoke-RestMethod -Uri $url -Method GET
}

function Sanitize([string]$s) {
  if ($null -eq $s) { return "" }
  $s = $s -replace "`r", "\r"
  $s = $s -replace "`n", "\n"
  $s = $s -replace "`t", "    "
  return $s
}

Write-Host "Starting remote log watcher [ADMIN]..."
Write-Host "GAS URL: $GasUrl"
Write-Host ""

# --- start session (Plan B) ---
try {
  $ss = Post-Form @{ action="start_session"; admin_key=$AdminKey }
  if (-not $ss.ok) { throw "start_session failed: $($ss.reason)" }
  $sessionId = [string]$ss.session_id
  if (-not $sessionId) { throw "start_session returned empty session_id" }
  Write-Host ("[SESSION] {0}" -f $sessionId) -ForegroundColor Cyan
  Write-Host ""
} catch {
  Write-Host ("[ERR] failed to start session: {0}" -f $_.Exception.Message) -ForegroundColor Red
  Read-Host "Press Enter to exit..."
  exit 1
}

# --- helper to build URLs with session_id ---
function Build-LogsUrl([int]$sinceValue) {
  return ($GasUrl + "?since=$sinceValue&session_id=" + [uri]::EscapeDataString($sessionId))
}

# --- 起動時UI（ALL / NEW） ---
Write-Host "Select view mode:"
Write-Host "  [1] New logs only (tail from now)  [default]"
Write-Host "  [2] All logs (from beginning)"
$sel = Read-Host "Enter 1 or 2"
$modeAll = ($sel -eq "2")

$since = 0
if ($modeAll) {
  $since = 0
  Write-Host "[MODE] ALL logs"
} else {
  # NEW only: jump to lastRow (we still pass session_id for consistent behavior)
  $bootstrap = Get-Json (Build-LogsUrl 999999999)
  $since = [int]$bootstrap.lastRow
  Write-Host "[MODE] NEW only (start since=$since)"
}
Write-Host ""
Write-Host "Commands: press '``' then type command. (help)"
Write-Host ""

# --- admin heartbeat ---
$lastHb = Get-Date 0
$hbSec = 8

function Cmd-Help {
  Write-Host ""
  Write-Host "help"
  Write-Host "mode new | mode all"
  Write-Host "pending"
  Write-Host "approve <req_id>"
  Write-Host "deny <req_id>"
  Write-Host "clients"
  Write-Host "kick <user_id>"
  Write-Host "quit"
  Write-Host ""
}

function Cmd-Mode([string]$m) {
  if ($m -eq "all") {
    $script:since = 0
    Write-Host "[MODE] ALL logs"
    return
  }
  if ($m -eq "new") {
    $bootstrap = Get-Json (Build-LogsUrl 999999999)
    $script:since = [int]$bootstrap.lastRow
    Write-Host "[MODE] NEW only (start since=$since)"
    return
  }
  Write-Host "[ERR] mode must be 'new' or 'all'" -ForegroundColor Red
}

function Cmd-Pending {
  $p = Get-Json ($GasUrl + "?action=get_pending")
  if (-not $p.ok -or $p.pending.Count -eq 0) { Write-Host "(no pending)"; return }

  foreach ($x in $p.pending) {
    # session_id も表示（案Bなので重要）
    $sid = ""
    if ($x.PSObject.Properties.Name -contains "session_id") { $sid = [string]$x.session_id }
    Write-Host ("req_id={0} user={1} host={2} session={3}" -f $x.req_id, $x.user_id, $x.host, $sid)
  }
}

function Cmd-Approve([string]$rid) {
  if (-not $rid) { Write-Host "[ERR] approve needs req_id" -ForegroundColor Red; return }
  $r = Post-Form @{ action="approve"; admin_key=$AdminKey; req_id=$rid }
  if ($r.ok) { Write-Host "[OK] approved" -ForegroundColor Cyan } else { Write-Host ("[ERR] {0}" -f $r.reason) -ForegroundColor Red }
}

function Cmd-Deny([string]$rid) {
  if (-not $rid) { Write-Host "[ERR] deny needs req_id" -ForegroundColor Red; return }
  $r = Post-Form @{ action="deny"; admin_key=$AdminKey; req_id=$rid }
  if ($r.ok) { Write-Host "[OK] denied" -ForegroundColor DarkYellow } else { Write-Host ("[ERR] {0}" -f $r.reason) -ForegroundColor Red }
}

function Cmd-Clients {
  $c = Get-Json ($GasUrl + "?action=list_clients")
  if (-not $c.ok -or $c.clients.Count -eq 0) { Write-Host "(no clients)"; return }

  foreach ($x in $c.clients) {
    $sid = ""
    if ($x.PSObject.Properties.Name -contains "session_id") { $sid = [string]$x.session_id }
    Write-Host ("user={0} host={1} exp={2} session={3}" -f $x.user_id, $x.host, $x.expires_ms, $sid)
  }
}

function Cmd-Kick([string]$uid) {
  if (-not $uid) { Write-Host "[ERR] kick needs user_id" -ForegroundColor Red; return }
  $r = Post-Form @{ action="revoke"; admin_key=$AdminKey; user_id=$uid }
  if ($r.ok) { Write-Host "[OK] kicked" -ForegroundColor Cyan } else { Write-Host ("[ERR] {0}" -f $r.reason) -ForegroundColor Red }
}

$quit = $false

while (-not $quit) {
  try {
    # heartbeat
    $now = Get-Date
    if (($now - $lastHb).TotalSeconds -ge $hbSec) {
      Post-Form @{ action="admin_heartbeat"; admin_key=$AdminKey } | Out-Null
      $lastHb = $now
    }

    # pending auto-approve prompt
    $pending = Get-Json ($GasUrl + "?action=get_pending")
    if ($pending.ok -and $pending.pending.Count -gt 0) {
      foreach ($p in $pending.pending) {
        $rid = [string]$p.req_id
        $uid = [string]$p.user_id
        $hst = [string]$p.host
        $sid = ""
        if ($p.PSObject.Properties.Name -contains "session_id") { $sid = [string]$p.session_id }

        Write-Host ""
        Write-Host ("ID:{0} is requesting permission to connect host={1} session={2}" -f $uid, $hst, $sid) -ForegroundColor Yellow
        $ans = Read-Host "Approve? (Y/N)"

        if ($ans -match '^[Yy]') { Cmd-Approve $rid }
        else { Cmd-Deny $rid }
      }
    }

    # command mode ('`')
    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true)
      if ($k.KeyChar -eq '`') {
        $cmd = Read-Host "cmd"
        $parts = $cmd.Trim().Split(" ", 2, [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($parts.Count -eq 0) { continue }
        $op = $parts[0].ToLowerInvariant()
        $arg = if ($parts.Count -ge 2) { $parts[1].Trim() } else { "" }

        switch ($op) {
          "help"    { Cmd-Help }
          "mode"    { Cmd-Mode $arg }
          "pending" { Cmd-Pending }
          "approve" { Cmd-Approve $arg }
          "deny"    { Cmd-Deny $arg }
          "clients" { Cmd-Clients }
          "kick"    { Cmd-Kick $arg }
          "quit"    {
            try {
                Post-Form @{
                    action    = "end_session"
                    admin_key = $AdminKey
                    admin     = $adminId 
                } | Out-Null
            } catch {}
            $quit = $true
          }
          default   { Write-Host "[ERR] unknown cmd. type 'help'" -ForegroundColor Red }
        }
      }
    }

    # logs (session filtered)
    $obj = Get-Json (Build-LogsUrl $since)
    foreach ($log in $obj.logs) {
      $msg = Sanitize ([string]$log.message)
      Write-Host -ForegroundColor Green $msg
      if ([int]$log.row -gt $since) { $since = [int]$log.row }
    }

  } catch {
    Write-Host ("[ERR] {0}" -f $_.Exception.Message) -ForegroundColor Red
  }

  Start-Sleep -Milliseconds 200
}
