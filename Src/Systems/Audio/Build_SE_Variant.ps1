param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    [Parameter(Mandatory=$true)]
    [int]$Volume
)

$ErrorActionPreference = "Stop"

function Read-Int24Le {
    param([byte[]]$Bytes, [int]$Offset)
    $value = $Bytes[$Offset] -bor ($Bytes[$Offset + 1] -shl 8) -bor ($Bytes[$Offset + 2] -shl 16)
    if ($value -band 0x800000) {
        $value = $value -bor (-bnot 0xFFFFFF)
    }
    return [int]$value
}

function Write-Int24Le {
    param([byte[]]$Bytes, [int]$Offset, [int]$Value)
    $Bytes[$Offset] = [byte]($Value -band 0xFF)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xFF)
    $Bytes[$Offset + 2] = [byte](($Value -shr 16) -band 0xFF)
}

try {
    $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).ProviderPath
    $targetVolume = [Math]::Max(0, [Math]::Min(100, $Volume))
    if ($targetVolume -ge 100) {
        $gain = 1.0
    } else {
        # Keep low-volume UI sounds clearly audible while preserving obvious step differences.
        $gainMap = @{
            90 = 0.86
            80 = 0.74
            70 = 0.63
            60 = 0.53
            50 = 0.44
            40 = 0.36
            30 = 0.29
            20 = 0.23
            10 = 0.18
        }
        if ($gainMap.ContainsKey($targetVolume)) {
            $gain = [double]$gainMap[$targetVolume]
        } else {
            $gain = [Math]::Pow(($targetVolume / 100.0), 0.75)
        }
    }

    $bytes = [System.IO.File]::ReadAllBytes($resolvedSource)
    if ($bytes.Length -lt 44) { throw "WAV_TOO_SMALL" }

    $riff = [Text.Encoding]::ASCII.GetString($bytes, 0, 4)
    $wave = [Text.Encoding]::ASCII.GetString($bytes, 8, 4)
    if ($riff -ne "RIFF" -or $wave -ne "WAVE") { throw "NOT_WAV" }

    $offset = 12
    $audioFormat = $null
    $bitsPerSample = $null
    $dataOffset = $null
    $dataSize = $null

    while ($offset + 8 -le $bytes.Length) {
        $chunkId = [Text.Encoding]::ASCII.GetString($bytes, $offset, 4)
        $chunkSize = [BitConverter]::ToInt32($bytes, $offset + 4)
        $chunkData = $offset + 8

        if ($chunkId -eq "fmt ") {
            $audioFormat = [BitConverter]::ToInt16($bytes, $chunkData)
            $bitsPerSample = [BitConverter]::ToInt16($bytes, $chunkData + 14)
        } elseif ($chunkId -eq "data") {
            $dataOffset = $chunkData
            $dataSize = $chunkSize
            break
        }

        $offset = $chunkData + $chunkSize
        if (($chunkSize % 2) -eq 1) { $offset++ }
    }

    if ($null -eq $audioFormat -or $null -eq $bitsPerSample -or $null -eq $dataOffset -or $null -eq $dataSize) {
        throw "WAV_PARSE_FAILED"
    }

    switch ($audioFormat) {
        1 {
            switch ($bitsPerSample) {
                8 {
                    for ($i = $dataOffset; $i -lt ($dataOffset + $dataSize); $i++) {
                        $sample = [int]$bytes[$i] - 128
                        $scaled = [Math]::Round($sample * $gain)
                        $clamped = [Math]::Max(-128, [Math]::Min(127, $scaled))
                        $bytes[$i] = [byte]($clamped + 128)
                    }
                }
                16 {
                    for ($i = $dataOffset; $i -lt ($dataOffset + $dataSize); $i += 2) {
                        $sample = [BitConverter]::ToInt16($bytes, $i)
                        $scaled = [Math]::Round($sample * $gain)
                        $clamped = [Math]::Max([int][Int16]::MinValue, [Math]::Min([int][Int16]::MaxValue, $scaled))
                        $outBytes = [BitConverter]::GetBytes([int16]$clamped)
                        $bytes[$i] = $outBytes[0]
                        $bytes[$i + 1] = $outBytes[1]
                    }
                }
                24 {
                    for ($i = $dataOffset; $i -lt ($dataOffset + $dataSize); $i += 3) {
                        $sample = Read-Int24Le -Bytes $bytes -Offset $i
                        $scaled = [Math]::Round($sample * $gain)
                        $clamped = [Math]::Max(-8388608, [Math]::Min(8388607, $scaled))
                        Write-Int24Le -Bytes $bytes -Offset $i -Value $clamped
                    }
                }
                32 {
                    for ($i = $dataOffset; $i -lt ($dataOffset + $dataSize); $i += 4) {
                        $sample = [BitConverter]::ToInt32($bytes, $i)
                        $scaled = [Math]::Round($sample * $gain)
                        $clamped = [Math]::Max([int64][Int32]::MinValue, [Math]::Min([int64][Int32]::MaxValue, [int64]$scaled))
                        $outBytes = [BitConverter]::GetBytes([int]$clamped)
                        [Array]::Copy($outBytes, 0, $bytes, $i, 4)
                    }
                }
                default { throw "UNSUPPORTED_PCM_BITS_$bitsPerSample" }
            }
        }
        3 {
            if ($bitsPerSample -ne 32) { throw "UNSUPPORTED_FLOAT_BITS_$bitsPerSample" }
            for ($i = $dataOffset; $i -lt ($dataOffset + $dataSize); $i += 4) {
                $sample = [BitConverter]::ToSingle($bytes, $i)
                $scaled = [Math]::Max(-1.0, [Math]::Min(1.0, $sample * $gain))
                $outBytes = [BitConverter]::GetBytes([single]$scaled)
                [Array]::Copy($outBytes, 0, $bytes, $i, 4)
            }
        }
        default { throw "UNSUPPORTED_AUDIO_FORMAT_$audioFormat" }
    }

    $targetDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
    exit 0
} catch {
    exit 1
}
