$version = '1.0.0'
$outputDir = './output'
$buildOutput = 'qserv_x64.exe'
$packageName = "qserv_portable_$version"

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

# Create data dirs
New-Item -ItemType Directory -Path "$packageDir/data/games" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir/data/scores" -Force | Out-Null

# Create start.bat
$lines = @(
    '@echo off',
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
    'Options:',
    '  --datadir PATH   Custom data directory',
    '  --port NUMBER    Custom port'
)
$readme -join "`r`n" | Set-Content -Path "$packageDir/README.txt" -Encoding UTF8

# Create ZIP
Write-Host 'Creating ZIP package...'
Compress-Archive -Path "$packageDir/*" -DestinationPath "$outputDir/$packageName.zip" -Force

Write-Host "Done: $outputDir/$packageName.zip"
