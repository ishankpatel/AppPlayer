# Serve the built Flutter web bundle on the LAN with SPA fallback.
#
# Usage: powershell -ExecutionPolicy Bypass -File .\serve_web.ps1
# Defaults to port 8088. Pass -Port 9000 to override.

param(
    [int]$Port = 8088
)

$webDir = Join-Path $PSScriptRoot 'build\web'
if (-not (Test-Path $webDir)) {
    Write-Host "ERROR: $webDir not found. Run 'flutter build web --release --pwa-strategy=none --no-wasm-dry-run' first."
    exit 1
}

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "ERROR: Node.js is required for SPA fallback serving."
    exit 1
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' } |
        Where-Object { $_.IPAddress -notmatch '^169\.|^127\.' } |
        Sort-Object @{Expression = { if ($_.PrefixOrigin -eq 'Dhcp') { 0 } else { 1 } } }, InterfaceAlias |
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

$env:STREAMVAULT_WEB_DIR = $webDir
$env:STREAMVAULT_WEB_PORT = "$Port"

& $node.Source (Join-Path $PSScriptRoot 'tools\serve_web.mjs')
