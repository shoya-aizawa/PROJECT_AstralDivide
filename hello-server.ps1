Add-Type -AssemblyName System.Net

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:8080/")
$listener.Start()
Write-Host "Simple server on 8080"

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $res = $ctx.Response
    $msg = "Hello World"
    $bytes = [Text.Encoding]::UTF8.GetBytes($msg)

    $res.StatusCode = 200
    $res.KeepAlive = $false
    $res.ContentType = "text/plain; charset=utf-8"
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes,0,$bytes.Length)
    $res.Close()

    Write-Host "Handled one request"
}
