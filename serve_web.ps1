# Serve the built web bundle on the LAN so you can open it from your iPhone,
# laptop, anything else on the same WiFi.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\serve_web.ps1
# Defaults to port 8088. Pass -Port 9000 to override.

param(
    [int]$Port = 8088
)

$webDir = Join-Path $PSScriptRoot 'build\web'
if (-not (Test-Path $webDir)) {
    Write-Host "ERROR: $webDir not found. Run 'flutter build web --release' first."
    exit 1
}

# Find a usable Python.
$python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
if (-not $python) {
    Write-Host "ERROR: python3 not on PATH. Install from python.org or use Windows Store."
    exit 1
}

# Show the LAN URLs.
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' } |
        Where-Object { $_.IPAddress -notmatch '^169\.|^127\.' } |
        Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "  StreamVault web running at:" -ForegroundColor Yellow
Write-Host "    http://localhost:$Port"
if ($ip) { Write-Host "    http://${ip}:${Port}   (open this on your iPhone)" }
Write-Host ""
Write-Host "  Add to iOS Home Screen for full-screen PWA:"
Write-Host "    Safari -> Share -> Add to Home Screen"
Write-Host ""
Write-Host "  Press Ctrl+C to stop."
Write-Host ""

Set-Location $webDir
& $python.Source -m http.server $Port --bind 0.0.0.0
