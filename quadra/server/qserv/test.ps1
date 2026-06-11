# qserv portable integration test
# Run: .\test.ps1   (auto-starts/stops the portable server)

$ErrorActionPreference = 'Continue'
$port = '34560'
$base = "http://localhost:$port/"
$testData = "$PSScriptRoot/test_data"
$pass = 0
$fail = 0

# --- Kill stale processes ---
Get-Process -Name qserv_x64 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# --- Find exe ---
$exe = "$PSScriptRoot/qserv_x64.exe"
if (-not (Test-Path $exe)) {
    $exe = "$PSScriptRoot/output/qserv_portable/qserv_x64.exe"
}
if (-not (Test-Path $exe)) {
    Write-Error 'qserv_x64.exe not found. Run build_package.ps1 first.'
    exit 1
}
Write-Host "Using: $exe"

# --- Prepare test dir ---
if (Test-Path $testData) { Remove-Item $testData -Recurse -Force }
New-Item -ItemType Directory -Path "$testData/games" -Force | Out-Null
New-Item -ItemType Directory -Path "$testData/scores" -Force | Out-Null

# --- Start server ---
Write-Host 'Starting qserv...'
$proc = Start-Process -FilePath $exe -ArgumentList "--datadir $testData --port $port" -PassThru -WindowStyle Hidden

# Wait for server to be ready (up to 15 seconds)
$ready = $false
1..15 | ForEach-Object {
    Start-Sleep -Seconds 1
    try {
        $null = Invoke-WebRequest -Uri $base -Method POST -Body 'data=hi' -TimeoutSec 2 -ErrorAction Stop
        $ready = $true
    } catch { }
    if ($ready) { return }
}
if (-not $ready) {
    Write-Error 'Server did not start in 15 seconds'
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Host 'Server ready.'

# --- Test helper ---
# qserv expects newlines INSIDE the data value: data=postgame\nkey val\nkey val
# Invoke-WebRequest sends body as application/x-www-form-urlencoded,
# so we replace backtick-n with %0A to keep them as part of the data value.
function test($name, $data, $expect) {
    Write-Host "TEST: $name" -NoNewline
    $encoded = $data -replace "`n", '%0A'
    try {
        $result = Invoke-WebRequest -Uri $base -Method POST -Body "data=$encoded" -TimeoutSec 5 -ErrorAction Stop
        $body = $result.Content
        if ($body -match $expect) {
            Write-Host ' ... PASS' -ForegroundColor Green
            $script:pass++
        } else {
            Write-Host ' ... FAIL' -ForegroundColor Red
            Write-Host "  Expected: $expect" -ForegroundColor Yellow
            Write-Host "  Got:      $body" -ForegroundColor Yellow
            $script:fail++
        }
    } catch {
        Write-Host ' ... FAIL' -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $script:fail++
    }
}

# --- Tests ---
Write-Host ''
Write-Host '=== QServ Integration Tests ===' -ForegroundColor Cyan
Write-Host ''

test 'unknown command'   "unknown"                                                      'Hi,'
test 'postgame new'      "postgame`ninfo/players 2`ninfo/name MyGame`nport 27910"   'Game added'
test 'postgame update'   "postgame`ninfo/players 3`ninfo/name MyGame`nport 27910"   'Game updated'
test 'getgames'          "getgames"                                                   'Current games'
test 'postdemo'          "postdemo`nscore 5000`ninfo/player Alice"                   'Ok'
test 'postdemo score2'   "postdemo`nscore 3000`ninfo/player Bob"                     'Ok'
test 'gethighscores'     "gethighscores"                                              'high000'
test 'deletegame exists' "deletegame`nport 27910"                                     'Game deleted'
test 'deletegame missing' "deletegame`nport 99999"                                    'Game not found'

# --- Teardown ---
Write-Host ''
Write-Host 'Stopping server...'
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
Remove-Item $testData -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=== Results: $pass pass, $fail fail ===" -ForegroundColor Cyan
if ($fail -gt 0) { exit 1 }
