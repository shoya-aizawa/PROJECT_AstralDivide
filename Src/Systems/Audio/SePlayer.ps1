param(
    [Parameter(Mandatory=$true)]
    [string]$QueueFile,
    [Parameter(Mandatory=$true)]
    [string]$PidFile
)

$ErrorActionPreference = "SilentlyContinue"

try {
    Add-Type -AssemblyName PresentationCore
} catch {
    exit 1
}

$players = New-Object System.Collections.ArrayList
$offset = 0

try {
    [System.IO.File]::WriteAllText($PidFile, [string]$PID)

    function Start-Sound {
        param(
            [string]$SoundPath,
            [int]$Volume
        )

        if (-not (Test-Path -LiteralPath $SoundPath)) {
            return
        }

        $boundedVolume = [Math]::Max(0, [Math]::Min(100, $Volume))
        $player = New-Object System.Windows.Media.MediaPlayer
        $uri = New-Object System.Uri($SoundPath)

        $player.Open($uri)
        $player.Volume = $boundedVolume / 100.0
        $player.Play()

        $null = $players.Add([pscustomobject]@{
            Player = $player
            TimeoutAt = [DateTime]::UtcNow.AddSeconds(15)
        })
    }

    while ($true) {
        if (Test-Path -LiteralPath $QueueFile) {
            $rawText = [System.IO.File]::ReadAllText($QueueFile)
            if ($rawText.Length -lt $offset) {
                $offset = 0
            }
            if ($rawText.Length -gt $offset) {
                $chunk = $rawText.Substring($offset)
                $offset = $rawText.Length
                $lines = $chunk -split "`r?`n" | Where-Object { $_ }

                foreach ($line in $lines) {
                    if ($line -eq "SHUTDOWN") {
                        throw "ShutdownRequested"
                    }

                    $parts = $line -split "\|", 2
                    if ($parts.Length -ne 2) {
                        continue
                    }

                    $vol = 100
                    $null = [int]::TryParse($parts[0], [ref]$vol)
                    Start-Sound -SoundPath $parts[1] -Volume $vol
                }
            }
        }

        for ($i = $players.Count - 1; $i -ge 0; $i--) {
            $entry = $players[$i]
            $player = $entry.Player
            $remove = $false

            try {
                if ($player.Source -eq $null) {
                    $remove = $true
                } elseif ($player.NaturalDuration.HasTimeSpan -and $player.Position -ge $player.NaturalDuration.TimeSpan) {
                    $remove = $true
                } elseif ([DateTime]::UtcNow -ge $entry.TimeoutAt) {
                    $remove = $true
                }
            } catch {
                $remove = $true
            }

            if ($remove) {
                try { $player.Stop() } catch {}
                try { $player.Close() } catch {}
                $players.RemoveAt($i)
            }
        }

        Start-Sleep -Milliseconds 25
    }
} catch {
} finally {
    for ($i = $players.Count - 1; $i -ge 0; $i--) {
        try { $players[$i].Player.Stop() } catch {}
        try { $players[$i].Player.Close() } catch {}
    }
    if (Test-Path -LiteralPath $PidFile) {
        Remove-Item -LiteralPath $PidFile -Force -ErrorAction SilentlyContinue
    }
}
