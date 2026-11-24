$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$port = 4173
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)

try {
  $listener.Start()
} catch {
  Write-Host "تعذر تشغيل المعاينة على المنفذ $port. أغلق أي معاينة أخرى وحاول مجدداً."
  exit 1
}

Write-Host "معاينة أثرنا تعمل على http://127.0.0.1:$port"
Write-Host "اترك هذه النافذة مفتوحة. للإيقاف اضغط Ctrl+C."
Start-Process "http://127.0.0.1:$port/"

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".js" = "text/javascript; charset=utf-8"
  ".css" = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg" = "image/svg+xml"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".webp" = "image/webp"
  ".mp3" = "audio/mpeg"
  ".ico" = "image/x-icon"
  ".txt" = "text/plain; charset=utf-8"
  ".webmanifest" = "application/manifest+json"
}

try {
  while ($listener.Server.IsBound) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      while ($null -ne ($header = $reader.ReadLine()) -and $header.Length -gt 0) {}

      $status = "200 OK"
      $filePath = Join-Path $root "index.html"
      if ($requestLine) {
        $parts = $requestLine.Split(" ")
        if ($parts.Length -ge 2 -and $parts[0] -eq "GET") {
          $urlPath = ($parts[1] -split "\?", 2)[0]
          $decodedPath = [System.Uri]::UnescapeDataString($urlPath).TrimStart("/")
          $relativePath = $decodedPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
          $candidate = [System.IO.Path]::GetFullPath((Join-Path $root $relativePath))
          $rootPrefix = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
          if ($candidate -eq $root -or $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            if ([System.IO.Directory]::Exists($candidate)) {
              $candidate = Join-Path $candidate "index.html"
            }
            if ([System.IO.File]::Exists($candidate)) {
              $filePath = $candidate
            }
          } else {
            $status = "403 Forbidden"
            $filePath = $null
          }
        }
      }

      if ($filePath) {
        $body = [System.IO.File]::ReadAllBytes($filePath)
        $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
        $contentType = $mimeTypes[$extension]
        if (-not $contentType) { $contentType = "application/octet-stream" }
      } else {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Forbidden")
        $contentType = "text/plain; charset=utf-8"
      }

      $headers = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`n`r`n"
      $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      $stream.Write($body, 0, $body.Length)
      $stream.Flush()
      $reader.Dispose()
    } catch {
      # Ignore a request that disconnects before its response is complete.
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
