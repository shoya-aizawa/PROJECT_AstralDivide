# Start-LocalWebServer.ps1
param(
    [int]$Port = 8080,
    [string]$Root = (Join-Path $PSScriptRoot 'wwwroot')
)

if (-not (Test-Path $Root)) {
    New-Item -Path $Root -ItemType Directory | Out-Null
    'Hello from PowerShell Web Server!' | Out-File (Join-Path $Root 'index.html') -Encoding UTF8
}

Add-Type -AssemblyName System.Web
$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Listening on $prefix (Ctrl+Cで停止)"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $relativePath = [System.Web.HttpUtility]::UrlDecode($request.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = 'index.html' }

        $filePath = Join-Path $Root $relativePath
        Write-Host "$(Get-Date -Format 'HH:mm:ss') $($request.HttpMethod) $($request.Url)"

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($filePath)
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $bytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $relativePath")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
