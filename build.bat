@echo off
REM ============================================
REM  Quadra 一鍵編譯腳本
REM  需求: Visual Studio 2022, CMake, vcpkg
REM ============================================
setlocal enabledelayedexpansion

REM -- 自動偵測 vcpkg 路徑 --
set "VCPKG_DIR="
if exist "C:\vcpkg\installed\x64-windows" (
    set "VCPKG_DIR=C:\vcpkg"
) else if exist "C:\Dev\vcpkg\installed\x64-windows" (
    set "VCPKG_DIR=C:\Dev\vcpkg"
) else if exist "C:\Users\%USERNAME%\vcpkg\installed\x64-windows" (
    set "VCPKG_DIR=C:\Users\%USERNAME%\vcpkg"
)
if "%VCPKG_DIR%"=="" (
    echo [ERROR] 找不到 vcpkg，請修改腳本中的 VCPKG_DIR 變數
    pause
    exit /b 1
)
echo [INFO] 使用 vcpkg: %VCPKG_DIR%

REM -- 切換到 quadra 目錄 --
cd /d "%~dp0quadra"
if %errorlevel% neq 0 (
    echo [ERROR] 找不到 quadra 目錄，請確認腳本放在專案根目錄
    pause
    exit /b 1
)

REM -- 建立 build 目錄 --
if not exist "build" mkdir build
cd build

REM -- CMake 設定 --
echo [INFO] 執行 CMake 設定...
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="%VCPKG_DIR%\installed\x64-windows"
if %errorlevel% neq 0 (
    echo [ERROR] CMake 設定失敗
    pause
    exit /b 1
)

REM -- 編譯 wadder（資源打包工具）--
echo [INFO] 編譯 wadder.exe...
cmake --build . --target wadder --config Release
if %errorlevel% neq 0 (
    echo [ERROR] wadder 編譯失敗
    pause
    exit /b 1
)

REM -- 複製 DLL 給 wadder 使用 --
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\SDL2.dll" ".\Release\" >nul 2>nul
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll" ".\Release\" >nul 2>nul

REM -- 手動產生 quadra.res --
echo [INFO] 產生 quadra.res...
if exist ".\quadra.res" del ".\quadra.res"
".\Release\wadder.exe" "..\" ".\quadra.res" "..\resources.txt"
if %errorlevel% neq 0 (
    echo [ERROR] quadra.res 產生失敗
    pause
    exit /b 1
)

REM -- 編譯 quadra --
echo [INFO] 編譯 quadra.exe...
cmake --build . --target quadra --config Release
if %errorlevel% neq 0 (
    echo [ERROR] quadra 編譯失敗
    pause
    exit /b 1
)

REM -- 產生 Portable 版本 --
echo [INFO] 建立 portable 版本...
if not exist "..\portable" mkdir "..\portable"
copy /Y ".\Release\quadra.exe"       "..\portable\" >nul
copy /Y ".\quadra.res"               "..\portable\" >nul
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\SDL2.dll"                                "..\portable\" >nul
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\libpng16.dll"                             "..\portable\" >nul
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\z.dll"                                    "..\portable\" >nul
copy /Y "%VCPKG_DIR%\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll"   "..\portable\" >nul

echo.
echo ========================================
echo   編譯完成！
echo   執行檔: quadra\portable\quadra.exe
echo ========================================
echo.
endlocal
pause
