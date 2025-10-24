# ================================================
# Astral Divide Chat Server (PowerShell版)
# ================================================
Add-Type -AssemblyName System.Net
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:8080/")   # ポート8080で待受
$listener.Start()
Write-Host "Chat server started on http://localhost:8080/"

# 簡易データ格納（メモリ上）
$ChatLogs = @()

while ($true) {
    $context = $listener.GetContext()
    $req  = $context.Request
    $resp = $context.Response
    $writer = New-Object IO.StreamWriter($resp.OutputStream)

    try {
        if ($req.HttpMethod -eq "POST") {
            # POST → チャット送信
            $body = New-Object IO.StreamReader($req.InputStream, $req.ContentEncoding)
            $raw  = $body.ReadToEnd()
            $params = @{ }
            foreach ($part in $raw -split "&") {
                $kv = $part -split "="
                if ($kv.Length -eq 2) {
                    $params[$kv[0]] = [uri]::UnescapeDataString($kv[1])
                }
            }

            $name    = $params["name"]   # "anonymous"
            $room    = $params["room"]   # "lobby"
            $message = $params["message"]

            if (-not [string]::IsNullOrWhiteSpace($message)) {
                $log = [PSCustomObject]@{
                    ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    room= $room
                    name= $name
                    msg = $message
                }
                $ChatLogs += $log
                $writer.WriteLine("OK")
                $resp.StatusCode = 200
            } else {
                $writer.WriteLine("EMPTY")
                $resp.StatusCode = 400
            }
        }
        elseif ($req.HttpMethod -eq "GET") {
            # GET → チャット取得 (room指定)
            $room = $req.QueryString["room"]
            if ([string]::IsNullOrWhiteSpace($room)) {
                $writer.WriteLine("[ERROR] Room ID is required.")
                $resp.StatusCode = 400
            } else {
                $lines = $ChatLogs | Where-Object { $_.room -eq $room } | Select-Object -Last 30
                if ($lines.Count -eq 0) {
                    $writer.WriteLine("[NO MESSAGE]")
                } else {
                    foreach ($line in $lines) {
                        $writer.WriteLine("[{0}] [{1}] - {2}" -f $line.ts, $line.name, $line.msg)
                    }
                }
                $resp.StatusCode = 200
            }
        }
        else {
            $writer.WriteLine("Unsupported method")
            $resp.StatusCode = 405
        }
    }
    catch {
        $writer.WriteLine("ERR: $_")
        $resp.StatusCode = 500
    }
    finally {
        $writer.Flush()
        $resp.Close()
    }
}
