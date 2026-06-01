param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [int]$Volume = 100
)

try {
    Add-Type -AssemblyName PresentationCore

    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $boundedVolume = [Math]::Max(0, [Math]::Min(100, $Volume))

    $player = New-Object System.Windows.Media.MediaPlayer
    $uri = New-Object System.Uri($resolvedPath)

    $player.Open($uri)
    $player.Volume = $boundedVolume / 100.0
    $player.Play()

    $timeoutAt = [DateTime]::UtcNow.AddSeconds(10)
    while (-not $player.NaturalDuration.HasTimeSpan -and [DateTime]::UtcNow -lt $timeoutAt) {
        Start-Sleep -Milliseconds 20
    }

    if ($player.NaturalDuration.HasTimeSpan) {
        while ($player.Position -lt $player.NaturalDuration.TimeSpan) {
            Start-Sleep -Milliseconds 20
        }
    } else {
        Start-Sleep -Milliseconds 750
    }

    $player.Stop()
    $player.Close()
} catch {
    # Fail silently to avoid interrupting the game loop when SE playback fails.
}
