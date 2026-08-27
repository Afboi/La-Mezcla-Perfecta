Param(
    [int]$Port = 3000
)

function Has-Command($name) { return (Get-Command $name -ErrorAction SilentlyContinue) -ne $null }

if (-not (Has-Command 'bun')) {
    Write-Host "bun not found in PATH. Attempting automatic install..."
    if (Has-Command 'winget') {
        Write-Host "Trying: winget install bun"
        try {
            winget install bun -e --accept-package-agreements --accept-source-agreements -h
        } catch {
            Write-Host "winget install failed. Please install bun manually from https://bun.sh or use WSL."
            exit 1
        }
    } elseif (Has-Command 'scoop') {
        Write-Host "Trying: scoop install bun"
        try {
            scoop install bun
        } catch {
            Write-Host "scoop install failed. Please install bun manually from https://bun.sh or use WSL."
            exit 1
        }
    } else {
        Write-Host "No package manager detected. Please install Bun from https://bun.sh or run this in WSL."
        exit 1
    }
}

$env:PORT = $Port
$base = "http://localhost:$Port"

# Stop any previous instance already listening on this port before starting a new one
$existingConn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    foreach ($conn in $existingConn) {
        $existingPid = $conn.OwningProcess
        Write-Host "Found existing server on port $Port (PID $existingPid). Stopping it..."
        Stop-Process -Id $existingPid -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 500
}

Write-Host "Starting Bun server (background)..."
$proc = Start-Process -FilePath "bun" -ArgumentList "server.js" -PassThru

Write-Host "Waiting for server to become available at $base"
for ($i = 0; $i -lt 50; $i++) {
    try {
        Invoke-WebRequest -Uri $base -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop | Out-Null
        break
    } catch {
        Start-Sleep -Milliseconds 200
    }
}

Write-Host "Opening controller and view in default browser..."
Start-Process "$base/controller.html"
Start-Process "$base/index.html"

Write-Host "Server running (PID: $($proc.Id)). Press Ctrl+C to stop."
try {
    Wait-Process -Id $proc.Id
} finally {
    Write-Host "Stopping Bun (PID: $($proc.Id))..."
    Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
}
