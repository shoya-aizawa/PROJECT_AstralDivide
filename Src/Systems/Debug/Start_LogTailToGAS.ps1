param(
  [Parameter(Mandatory=$true)][string]$ScriptPath,
  [Parameter(Mandatory=$true)][string]$LogPath,
  [Parameter(Mandatory=$true)][string]$GasUrl,
  [Parameter(Mandatory=$true)][string]$OutputPath,
  [string]$ClientName = "",
  [string]$SessionToken = "",
  [string]$StopFile = "",
  [string]$ErrorPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $ErrorPath) {
  $ErrorPath = "$OutputPath.err"
}

$argList = @(
  '-NoProfile',
  '-ExecutionPolicy', 'Bypass',
  '-File', $ScriptPath,
  '-LogPath', $LogPath,
  '-GasUrl', $GasUrl
)

if ($ClientName) {
  $argList += @('-ClientName', $ClientName)
}
if ($SessionToken) {
  $argList += @('-SessionToken', $SessionToken)
}
if ($StopFile) {
  $argList += @('-StopFile', $StopFile)
}

Start-Process -FilePath 'powershell.exe' `
  -WindowStyle Hidden `
  -ArgumentList $argList `
  -RedirectStandardOutput $OutputPath `
  -RedirectStandardError $ErrorPath | Out-Null
