# BGMPlayer.psm1
# BGM 再生用モジュール

$script:wmp = New-Object -ComObject WMPlayer.OCX

function Invoke-BGM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,                      # 再生ファイル
        [ValidateSet('play','repeat','stop')][string]$Mode='play',# 再生オプション
        [ValidateRange(0,100)][int]$Volume = 50                   # 音量 (0-100)
    )

    switch ($Mode) {
        'play' {
            $script:wmp.settings.setMode('loop', $false)
            $script:wmp.URL = $Path
            $script:wmp.settings.volume = $Volume
            $script:wmp.controls.play()
        }
        'repeat' {
            $script:wmp.settings.setMode('loop', $true)
            $script:wmp.URL = $Path
            $script:wmp.settings.volume = $Volume
            $script:wmp.controls.play()
        }
        'stop' {
            $script:wmp.controls.stop()
        }
    }
}
