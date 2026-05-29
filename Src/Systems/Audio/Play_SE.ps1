param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

try {
    $resolvedPath = (Resolve-Path $Path).ProviderPath
    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $resolvedPath
    $player.PlaySync()
} catch {
    # Fail silently to not disrupt game execution if sound fails
}
