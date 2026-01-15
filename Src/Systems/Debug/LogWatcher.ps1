# LogWatcher.ps1
param(
  [Parameter(Mandatory=$true)][string]$GasUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$since = 0

function Sanitize([string]$s) {
  if ($null -eq $s) { return "" }
  # 改行/タブ/ESCざっくり無害化（表示ズレ防止）
  $s = $s -replace "`e\[[0-9;]*[A-Za-z]", ""
  $s = $s -replace "`e", ""
  $s = $s -replace "`r", "\r"
  $s = $s -replace "`n", "\n"
  $s = $s -replace "`t", "    "
  return $s
}

Write-Host "Starting log watcher from $GasUrl"

while ($true) {
  try {
    $uri = $GasUrl + "?since=$since"
    $res = Invoke-WebRequest -Uri $uri -Method GET
    if ($res.StatusCode -ne 200) {
      Write-Host "HTTP Error: $($res.StatusCode)"
      Start-Sleep -Seconds 1
      continue
    }

    $obj = Invoke-RestMethod -Uri $uri -Method GET

    foreach ($log in $obj.logs) {
      $msg = Sanitize ([string]$log.message)
      Write-Host -ForegroundColor Green $msg
      # since を進める（行番号で確実）
      if ([int]$log.row -gt $since) { $since = [int]$log.row }
    }

  } catch {
    Write-Host "Error in watcher: $($_.Exception.Message)"
  }

  Start-Sleep -Seconds 1
}
