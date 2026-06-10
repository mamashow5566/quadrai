@echo off
setlocal enabledelayedexpansion

REM ============================================
REM  Quadra one-click build script
REM  Requires: Visual Studio 2022, CMake, vcpkg
REM ============================================

REM -- Auto-detect vcpkg --
set "VCPKG="
if exist "C:\vcpkg\installed\x64-windows" (
    set "VCPKG=C:\vcpkg"
) else if exist "C:\Dev\vcpkg\installed\x64-windows" (
    set "VCPKG=C:\Dev\vcpkg"
) else if exist "C:\Users\%USERNAME%\vcpkg\installed\x64-windows" (
    set "VCPKG=C:\Users\%USERNAME%\vcpkg"
)
if "%VCPKG%"=="" (
    echo [ERROR] vcpkg not found. Please set VCPKG variable in this script.
    pause
    exit /b 1
)
echo [INFO] vcpkg: %VCPKG%

REM -- Enter quadra directory --
cd /d "%~dp0quadra"
if %errorlevel% neq 0 (
    echo [ERROR] quadra directory not found. Place this script at the repo root.
    pause
    exit /b 1
)

REM -- Prepare build directory --
if not exist "build" mkdir build
cd build

REM -- CMake configure --
echo [INFO] Running CMake configure...
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="%VCPKG%\installed\x64-windows"
if %errorlevel% neq 0 (
    echo [ERROR] CMake configure failed
    pause
    exit /b 1
)

REM -- Build wadder (resource packer) --
echo [INFO] Building wadder.exe...
cmake --build . --target wadder --config Release
if %errorlevel% neq 0 (
    echo [ERROR] wadder build failed
    pause
    exit /b 1
)

REM -- Copy DLLs for wadder --
copy /Y "%VCPKG%\installed\x64-windows\bin\SDL2.dll" ".\Release\" >nul 2>nul
copy /Y "%VCPKG%\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll" ".\Release\" >nul 2>nul

REM -- Generate quadra.res --
echo [INFO] Generating quadra.res...
if exist ".\quadra.res" del ".\quadra.res"
".\Release\wadder.exe" ..\ .\quadra.res ..\resources.txt
if %errorlevel% neq 0 (
    echo [ERROR] quadra.res generation failed
    pause
    exit /b 1
)

REM -- Build quadra --
echo [INFO] Building quadra.exe...
cmake --build . --target quadra --config Release
if %errorlevel% neq 0 (
    echo [ERROR] quadra build failed
    pause
    exit /b 1
)

REM -- Create portable package --
echo [INFO] Creating portable package...
if not exist "..\portable" mkdir "..\portable"
copy /Y ".\Release\quadra.exe"       "..\portable\" >nul
copy /Y ".\quadra.res"               "..\portable\" >nul
copy /Y "%VCPKG%\installed\x64-windows\bin\SDL2.dll"                              "..\portable\" >nul
copy /Y "%VCPKG%\installed\x64-windows\bin\libpng16.dll"                           "..\portable\" >nul
copy /Y "%VCPKG%\installed\x64-windows\bin\z.dll"                                  "..\portable\" >nul
copy /Y "%VCPKG%\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll" "..\portable\" >nul

echo.
echo ========================================
echo   Build complete!
echo   Executable: quadra\portable\quadra.exe
echo ========================================
echo.
endlocal
pause
