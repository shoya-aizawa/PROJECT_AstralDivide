# CmdgfxInputBridge.ps1
# Reassembles fragmented cmdgfx_input records and forwards only complete events.

[Console]::InputEncoding = [System.Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8

$eventPattern = [regex]'KEY_EVENT\s+\d+\s+DOWN\s+\d+\s+VALUE\s+\d+\s+MOUSE_EVENT\s+\d+\s+X\s+\d+\s+Y\s+\d+\s+LEFT\s+\d+\s+RIGHT\s+\d+\s+LEFT_DOUBLE\s+\d+\s+RIGHT_DOUBLE\s+\d+\s+WHEEL\s+\d+'
$noEventPattern = [regex]'^NO_EVENT\s+0\b'
$keyStartPattern = [regex]'KEY_EVENT\s+\d+\s+DOWN'
$buffer = ''
$bridgeLogPath = $env:CMDGFX_BRIDGE_LOG
$stopSignalPath = $env:ROOM_BRIDGE_STOP
$reader = [Console]::In

function Write-BridgeLog {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($bridgeLogPath)) { return }
    try {
        Add-Content -LiteralPath $bridgeLogPath -Value $Text -Encoding UTF8
    } catch {
    }
}

function Normalize-EventBuffer {
    param([string]$Text)

    if ($null -eq $Text) { return '' }
    if ($Text.Length -eq 0) { return '' }

    return (($Text -replace '[\r\n]+', '') -replace '\s+', ' ').Trim()
}

while ($true) {
    if (-not [string]::IsNullOrWhiteSpace($stopSignalPath) -and (Test-Path -LiteralPath $stopSignalPath)) {
        Write-BridgeLog ("{0} | STOP_SIGNAL" -f (Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'))
        break
    }

    $readTask = $reader.ReadLineAsync()
    while (-not $readTask.Wait(15)) {
        if (-not [string]::IsNullOrWhiteSpace($stopSignalPath) -and (Test-Path -LiteralPath $stopSignalPath)) {
            Write-BridgeLog ("{0} | STOP_SIGNAL" -f (Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'))
            break 2
        }
    }

    $line = $readTask.Result
    if ($null -eq $line) {
        break
    }

    $chunk = $line
    if ($chunk.Length -eq 0) {
        continue
    }

    $normalizedChunk = Normalize-EventBuffer $chunk

    if ($noEventPattern.IsMatch($normalizedChunk)) {
        continue
    }

    if ($keyStartPattern.IsMatch($normalizedChunk)) {
        $buffer = $chunk
    } elseif ($buffer.Length -gt 0) {
        $buffer = "$buffer$chunk"
    } else {
        continue
    }

    $normalizedBuffer = Normalize-EventBuffer $buffer
    $match = $eventPattern.Match($normalizedBuffer)
    if ($match.Success) {
        Write-BridgeLog ("{0} | {1}" -f (Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'), $match.Value)
        [Console]::Out.WriteLine($match.Value)
        [Console]::Out.Flush()
        $buffer = ''
        continue
    }

    if ($buffer.Length -gt 512) {
        $restart = $buffer.LastIndexOf('KEY_EVENT', [System.StringComparison]::Ordinal)
        if ($restart -ge 0) {
            $buffer = $buffer.Substring($restart)
        } else {
            $buffer = ''
        }
    }
}
