<#
.SYNOPSIS
    Quadra one-click build script (PowerShell)
.DESCRIPTION
    Auto-detects dev environment (CMake, Visual Studio 2022, vcpkg),
    builds quadra.exe and packages portable version.
    Supports manual step-by-step and interactive mode.
.PARAMETER Help
    Show usage
.PARAMETER Interactive
    Step-by-step interactive mode, confirm each step
.PARAMETER Step
    Run a specific step (configure, wadder, generate_res, quadra, package, all)
    Default: all
.PARAMETER VcpkgRoot
    Manually specify vcpkg root directory
.PARAMETER Clean
    Clean build directory before building
.PARAMETER Portable
    Create portable package after build
.EXAMPLE
    .\build.ps1
    .\build.ps1 -Interactive
    .\build.ps1 -Step configure
    .\build.ps1 -Clean -Portable
#>

param(
    [switch]$Help,
    [switch]$Interactive,
    [string]$Step = "all",
    [string]$VcpkgRoot,
    [switch]$Clean,
    [switch]$Portable
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$QuadraDir = Join-Path $ScriptDir "quadra"
$BuildDir = Join-Path $QuadraDir "build"
$ReleaseDir = Join-Path $BuildDir "Release"
$PortableDir = Join-Path $QuadraDir "portable"

# =============================================================================
# Utility functions
# =============================================================================

function Write-Step { Write-Host "`n========== $args ==========" -ForegroundColor Cyan }
function Write-OK   { Write-Host "  [OK] $args" -ForegroundColor Green }
function Write-INFO { Write-Host "  [INFO] $args" -ForegroundColor Yellow }
function Write-ERR  { Write-Host "  [ERROR] $args" -ForegroundColor Red }
function Write-HINT { Write-Host "  [HINT] $args" -ForegroundColor Magenta }

function Show-Help {
    @"
Quadra Revival Project - Build Script

Usage:
  .\build.ps1                  One-click build (configure + wadder + res + quadra + package)
  .\build.ps1 -Interactive    Interactive step-by-step mode
  .\build.ps1 -Step <step>    Run a specific step
  .\build.ps1 -Clean          Clean and rebuild
  .\build.ps1 -Portable       Build and create portable package

Steps:
  configure     CMake configure only
  wadder        Build wadder.exe only
  generate_res  Generate quadra.res only
  quadra        Build quadra.exe only
  package       Create portable package only
  all           Run all steps (default)

Examples:
  .\build.ps1 -Step wadder
  .\build.ps1 -Clean -Portable

Requirements:
  - Visual Studio 2022 (Community/Professional/Enterprise) or BuildTools
    (with "Desktop development with C++" workload)
  - CMake 3.20+
  - vcpkg + packages: sdl2, libpng, zlib, boost-system, boost-filesystem
"@
}

# =============================================================================
# Environment detection
# =============================================================================

function Find-VisualStudio {
    param([string]$CMakeExe)
    
    Write-INFO "Checking for Visual Studio 2022 C++ tools..."
    
    # Try to find vcvars64.bat directly in known locations
    $knownPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022"
    )
    $found = $false
    foreach ($base in $knownPaths) {
        foreach ($edition in @("Community", "Professional", "Enterprise", "BuildTools")) {
            $vcDir = Join-Path (Join-Path $base $edition) "VC"
            if (Test-Path $vcDir) {
                $vcvars = Get-ChildItem -Path $vcDir -Recurse -Filter "vcvars64.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($vcvars) {
                    Write-OK "Found C++ tools: $($vcvars.FullName)"
                    $found = $true
                    return @{
                        Path        = Join-Path $base $edition
                        Vcvars64    = $vcvars.FullName
                        DisplayName = "Visual Studio 2022 $edition"
                    }
                }
            }
        }
    }
    
    # Fallback: check if cmake can find VS generator
    $genCheck = & $CMakeExe --help 2>&1 | Select-String "Visual Studio 17 2022"
    if ($genCheck) {
        Write-OK "CMake found Visual Studio 2022 generator"
        return @{
            Path        = ""
            Vcvars64    = $null
            DisplayName = "Visual Studio 2022 (detected by CMake)"
        }
    }
    
    Write-ERR "Visual Studio 2022 C++ build tools not found"
    Write-HINT "Please install one of:"
    Write-HINT "  - Visual Studio 2022 Community with 'Desktop development with C++'"
    Write-HINT "  - Visual Studio 2022 BuildTools"
    Write-HINT "Download: https://visualstudio.microsoft.com/downloads/"
    return $null
}

function Find-CMake {
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    if (-not $cmake) {
        $paths = @(
            "C:\Program Files\CMake\bin\cmake.exe",
            "${env:ProgramFiles(x86)}\CMake\bin\cmake.exe"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Write-OK "Found CMake: $p"
                return $p
            }
        }
        Write-ERR "CMake not found. Please install CMake 3.20+"
        Write-HINT "winget install Kitware.CMake"
        Write-HINT "Or download: https://cmake.org/download/"
        return $null
    }
    Write-OK "Found CMake: $($cmake.Source)"
    return "cmake"
}

function Find-Vcpkg {
    if ($VcpkgRoot) {
        if (Test-Path (Join-Path $VcpkgRoot "vcpkg.exe")) {
            return $VcpkgRoot
        }
        Write-ERR "Invalid vcpkg path: $VcpkgRoot"
        return $null
    }

    $searchPaths = @(
        "C:\vcpkg",
        "C:\Dev\vcpkg",
        "$env:USERPROFILE\vcpkg",
        "${env:ProgramFiles}\vcpkg"
    )

    foreach ($p in $searchPaths) {
        $exe = Join-Path $p "vcpkg.exe"
        if (Test-Path $exe) {
            Write-OK "Found vcpkg: $p"
            return $p
        }
    }

    Write-ERR "vcpkg not found"
    Write-HINT "Install vcpkg:"
    Write-HINT "  cd C:\"
    Write-HINT "  git clone https://github.com/microsoft/vcpkg.git"
    Write-HINT "  cd vcpkg"
    Write-HINT "  .\bootstrap-vcpkg.bat"
    return $null
}

function Check-VcpkgPackages {
    param([string]$VcpkgRoot)

    $toolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"
    if (-not (Test-Path $toolchain)) {
        Write-ERR "vcpkg toolchain not found: $toolchain"
        Write-HINT "Run bootstrap-vcpkg.bat first"
        return $false
    }

    $required = @("sdl2", "libpng", "zlib", "boost-system", "boost-filesystem")
    $missing = @()
    $installedDir = Join-Path $VcpkgRoot "installed\x64-windows"

    if (-not (Test-Path $installedDir)) {
        Write-ERR "vcpkg packages not installed (missing x64-windows triplet)"
        Write-HINT "Run: cd $VcpkgRoot; .\vcpkg install sdl2:x64-windows libpng:x64-windows zlib:x64-windows boost-system:x64-windows boost-filesystem:x64-windows"
        return $false
    }

    $includeDir = Join-Path $installedDir "include"
    $libDir = Join-Path $installedDir "lib"

    foreach ($pkg in $required) {
        $found = $false
        if ($pkg -eq "sdl2") {
            $found = Test-Path (Join-Path $includeDir "SDL2\SDL.h")
        } elseif ($pkg -eq "libpng") {
            $found = Test-Path (Join-Path $includeDir "png.h")
        } elseif ($pkg -eq "zlib") {
            $found = Test-Path (Join-Path $includeDir "zlib.h")
        } elseif ($pkg -eq "boost-system") {
            $found = Test-Path (Join-Path $includeDir "boost\system.hpp")
        } elseif ($pkg -eq "boost-filesystem") {
            $found = Test-Path (Join-Path $includeDir "boost\filesystem.hpp")
        }

        if ($found) {
            Write-OK "vcpkg package: $pkg"
        } else {
            $missing += $pkg
        }
    }

    if ($missing.Count -gt 0) {
        Write-ERR "Missing vcpkg packages: $($missing -join ', ')"
        Write-HINT "Run: cd $VcpkgRoot; .\vcpkg install $($missing -join ' ') --triplet x64-windows"
        return $false
    }

    return $true
}

# =============================================================================
# Build steps
# =============================================================================

function Invoke-Configure {
    param([string]$CMakeExe, [string]$VcpkgRoot, [hashtable]$VS)

    Write-Step "CMake Configure"

    $toolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"

    if (-not (Test-Path $QuadraDir)) {
        Write-ERR "quadra directory not found: $QuadraDir"
        return $false
    }

    if ($Clean -and (Test-Path $BuildDir)) {
        Write-INFO "Cleaning build directory..."
        Remove-Item -Recurse -Force $BuildDir
    }

    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir | Out-Null
    }

    Write-INFO "Source : $QuadraDir"
    Write-INFO "Build  : $BuildDir"
    Write-INFO "vcpkg  : $toolchain"

    # Use cmd to avoid PS 5.1 stderr coloring issue
    $cmakeCmd = "`"$CMakeExe`" -S `"$QuadraDir`" -B `"$BuildDir`" -G `"Visual Studio 17 2022`" -A x64 `"-DCMAKE_TOOLCHAIN_FILE=$toolchain`""
    cmd /c "$cmakeCmd 2>&1"

    if ($LASTEXITCODE -ne 0) {
        Write-ERR "CMake configure failed"
        Write-HINT "Common causes:"
        Write-HINT "  1. VS 2022 missing C++ workload - open VS Installer to modify"
        Write-HINT "  2. vcpkg packages not installed - see check above"
        Write-HINT "  3. Firewall/antivirus interference"
        return $false
    }
    Write-OK "CMake configure complete"
    return $true
}

function Invoke-BuildWadder {
    param([string]$CMakeExe)

    Write-Step "Building wadder.exe (resource packer)"

    & $CMakeExe --build $BuildDir --target wadder --config Release 2>&1 | ForEach-Object {
        if ($_ -match "error C\d+") {
            Write-Host $_ -ForegroundColor Red
        } else {
            Write-Host $_
        }
    }

    if ($LASTEXITCODE -ne 0) {
        Write-ERR "wadder.exe build failed"
        return $false
    }
    Write-OK "wadder.exe build complete"
    return $true
}

function Invoke-GenerateRes {
    param([string]$CMakeExe, [string]$VcpkgRoot)

    Write-Step "Generating quadra.res (game resource file)"

    $wadderExe = Join-Path $ReleaseDir "wadder.exe"
    if (-not (Test-Path $wadderExe)) {
        Write-ERR "wadder.exe not found. Run wadder step first."
        return $false
    }

    # Copy required DLLs for wadder
    $vcpkgBin = Join-Path $VcpkgRoot "installed\x64-windows\bin"
    @("SDL2.dll") | ForEach-Object {
        $src = Join-Path $vcpkgBin $_
        if (Test-Path $src) {
            $dest = Join-Path $ReleaseDir $_
            if (-not (Test-Path $dest)) {
                Copy-Item $src $ReleaseDir -ErrorAction SilentlyContinue
            }
        }
    }
    Get-ChildItem (Join-Path $vcpkgBin "boost_filesystem-vc*-mt-x64-*.dll") -ErrorAction SilentlyContinue | ForEach-Object {
        $dest = Join-Path $ReleaseDir $_.Name
        if (-not (Test-Path $dest)) {
            Copy-Item $_.FullName $ReleaseDir -ErrorAction SilentlyContinue
        }
    }

    & $CMakeExe --build $BuildDir --target quadra_res --config Release 2>&1 | ForEach-Object {
        Write-Host $_
    }

    if ($LASTEXITCODE -ne 0) {
        Write-ERR "quadra.res generation failed"
        return $false
    }

    $resFile = Join-Path $ReleaseDir "quadra.res"
    if (Test-Path $resFile) {
        Write-OK "quadra.res generated ($((Get-Item $resFile).Length) bytes)"
    } elseif (Test-Path (Join-Path $BuildDir "quadra.res")) {
        Write-OK "quadra.res generated (in build root)"
    }
    return $true
}

function Invoke-BuildQuadra {
    param([string]$CMakeExe)

    Write-Step "Building quadra.exe"

    & $CMakeExe --build $BuildDir --target quadra --config Release 2>&1 | ForEach-Object {
        if ($_ -match "error C\d+") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "quadra.vcxproj ->") {
            Write-Host $_ -ForegroundColor Green
        } else {
            Write-Host $_
        }
    }

    if ($LASTEXITCODE -ne 0) {
        Write-ERR "quadra.exe build failed"
        return $false
    }

    $quadraExe = Join-Path $ReleaseDir "quadra.exe"
    if (Test-Path $quadraExe) {
        Write-OK "quadra.exe build complete ($((Get-Item $quadraExe).Length) bytes)"
    } else {
        Write-ERR "quadra.exe not found after build"
        return $false
    }
    return $true
}

function Invoke-PackagePortable {
    param([string]$VcpkgRoot)

    Write-Step "Creating portable package"

    $quadraExe = Join-Path $ReleaseDir "quadra.exe"
    if (-not (Test-Path $quadraExe)) {
        Write-ERR "quadra.exe not found. Build first."
        return $false
    }

    $resFile = Join-Path $ReleaseDir "quadra.res"
    if (-not (Test-Path $resFile)) {
        $resFile = Join-Path $BuildDir "quadra.res"
        if (-not (Test-Path $resFile)) {
            Write-ERR "quadra.res not found"
            return $false
        }
    }

    if (-not (Test-Path $PortableDir)) {
        New-Item -ItemType Directory -Path $PortableDir | Out-Null
    }

    # Copy executable and resources
    Copy-Item $quadraExe $PortableDir -Force
    Copy-Item $resFile $PortableDir -Force
    Write-OK "Copied quadra.exe + quadra.res"

    # Copy vcpkg DLLs
    $vcpkgBin = Join-Path $VcpkgRoot "installed\x64-windows\bin"
    $dlls = @("SDL2.dll", "libpng16.dll", "z.dll")
    Get-ChildItem (Join-Path $vcpkgBin "boost_filesystem-vc*-mt-x64-*.dll") -ErrorAction SilentlyContinue | ForEach-Object {
        $dlls += $_.Name
    }

    foreach ($dll in $dlls) {
        $src = Join-Path $vcpkgBin $dll
        if (Test-Path $src) {
            Copy-Item $src $PortableDir -Force
            Write-OK "Copied $dll"
        } else {
            Write-INFO "$dll not found (skipped)"
        }
    }

    Write-OK "Portable package created: $PortableDir"
    Write-HINT "You can copy portable\ to any Windows 10/11 x64 machine"
    Write-HINT "If VC++ runtime is missing: https://aka.ms/vs/17/release/vc_redist.x64.exe"
    return $true
}

# =============================================================================
# Main
# =============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "`n  Quadra Revival Project - Build Script`n" -ForegroundColor Cyan

# 1. Environment detection
Write-Step "Environment Detection"

$CMake = Find-CMake
if (-not $CMake) { exit 1 }

$VcpkgDetected = Find-Vcpkg
if (-not $VcpkgDetected) { exit 1 }

if (-not (Check-VcpkgPackages -VcpkgRoot $VcpkgDetected)) {
    exit 1
}

$VS = Find-VisualStudio $CMake
if (-not $VS) { exit 1 }

Write-OK "Environment check passed"

# Parse steps
$steps = @()
switch ($Step.ToLower()) {
    "all"          { $steps = @("configure", "wadder", "generate_res", "quadra", "package") }
    "configure"    { $steps = @("configure") }
    "wadder"       { $steps = @("wadder") }
    "generate_res" { $steps = @("generate_res") }
    "quadra"       { $steps = @("quadra") }
    "package"      { $steps = @("package") }
    default        {
        Write-ERR "Invalid step: '$Step'"
        Show-Help
        exit 1
    }
}

if (-not $Portable) {
    $steps = $steps | Where-Object { $_ -ne "package" }
}

# 2. Execute steps
foreach ($s in $steps) {
    if ($Interactive) {
        $choice = Read-Host "`nExecute step '$s'? (Y/n)"
        if ($choice -eq "n" -or $choice -eq "N") { continue }
    }

    $result = $false
    switch ($s) {
        "configure"    { $result = Invoke-Configure -CMakeExe $CMake -VcpkgRoot $VcpkgDetected -VS $VS }
        "wadder"       { $result = Invoke-BuildWadder -CMakeExe $CMake }
        "generate_res" { $result = Invoke-GenerateRes -CMakeExe $CMake -VcpkgRoot $VcpkgDetected }
        "quadra"       { $result = Invoke-BuildQuadra -CMakeExe $CMake }
        "package"      { $result = Invoke-PackagePortable -VcpkgRoot $VcpkgDetected }
    }

    if (-not $result) {
        Write-ERR "Step '$s' failed. Build aborted."
        exit 1
    }
}

# 3. Done
Write-Host @"

========================================
  Build complete!
  Executable: $QuadraDir\portable\quadra.exe
  Run: .\quadra\portable\quadra.exe
========================================
"@ -ForegroundColor Green
