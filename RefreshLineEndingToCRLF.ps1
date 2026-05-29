# Refresh all *.bat files under the current directory recursively
# Enforce CRLF line endings while keeping UTF-8 encoding

Get-ChildItem -Recurse -Filter *.bat | ForEach-Object {
    $filePath = $_.FullName
    # Skip any script containing the refresher name to avoid file lock issues or unnecessary processing
    if ($filePath -like "*RefreshLineEndingToCRLF*") { return }
    
    if ((Test-Path $filePath -PathType Leaf) -eq $false) { return }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    if ($bytes.Length -eq 0) { return }
    
    # Detect UTF-8 BOM (0xEF, 0xBB, 0xBF -> 239, 187, 191)
    $hasBom = $false
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $hasBom = $true
    }
    
    $encoding = if ($hasBom) { [System.Text.Encoding]::UTF8 } else { New-Object System.Text.UTF8Encoding($false) }
    $text = [System.IO.File]::ReadAllText($filePath, $encoding)
    
    # Normalize LF (\n) to CRLF (\r\n) only where CR is missing
    $normalized = $text -replace "(?<!`r)`n", "`r`n"
    
    if ($text -ne $normalized) {
        [System.IO.File]::WriteAllText($filePath, $normalized, $encoding)
        Write-Host "[REFRESHED] $filePath"
    }
}
