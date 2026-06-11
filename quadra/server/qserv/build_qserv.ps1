# Read version from qserv_release.txt
$version = '0.0.0'
if (Test-Path "$PSScriptRoot/qserv_release.txt") {
    $firstLine = Get-Content "$PSScriptRoot/qserv_release.txt" -First 1
    if ($firstLine -match '^\d+\.\d+\.\d+') {
        $version = $matches[0]
    }
}
$outputDir = './output'
$buildOutput = 'qserv_x64.exe'
$packageName = 'qserv_portable'

# Clean
if (Test-Path $outputDir) {
    Remove-Item $outputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Build
Write-Host 'Building Windows x64 executable...'
$env:CGO_ENABLED = 0
go build -ldflags='-s -w' -o "$outputDir/$buildOutput" .

if ($LASTEXITCODE -ne 0) {
    Write-Error 'Build failed!'
    exit 1
}

# Create portable structure
Write-Host 'Creating portable structure...'
$packageDir = "$outputDir/$packageName"
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copy exe
Copy-Item "$outputDir/$buildOutput" $packageDir

# Copy release info
if (Test-Path "$PSScriptRoot/qserv_release.txt") {
    Copy-Item "$PSScriptRoot/qserv_release.txt" $packageDir
}

# Create data dirs
New-Item -ItemType Directory -Path "$packageDir/data/games" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir/data/scores" -Force | Out-Null

# Create start.bat
$lines = @(
    '@echo off',
    'taskkill /f /im qserv_x64.exe 2>nul',
    '.\qserv_x64.exe --datadir ".\data"',
    'pause'
)
$lines -join "`r`n" | Set-Content -Path "$packageDir/start.bat" -Encoding ASCII

# Create README
$readme = @(
    '# Quadra Server Portable v' + $version,
    '',
    '1. Double-click start.bat to start server (port 3456)',
    '2. Data stored in ./data/',
    '',
    'Version: ' + $version + ' (see qserv_release.txt for changes)',
    '',
    'Options:',
    '  --datadir PATH   Custom data directory',
    '  --port NUMBER    Custom port'
)
$readme -join "`r`n" | Set-Content -Path "$packageDir/README.txt" -Encoding UTF8

# Create ZIP
Write-Host 'Creating ZIP package...'
Compress-Archive -Path "$packageDir/*" -DestinationPath "$outputDir/$packageName.zip" -Force

Write-Host "Done: $outputDir/$packageName.zip  (v$version)"
