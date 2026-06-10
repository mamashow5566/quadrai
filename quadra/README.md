Quadra - 基於 Ludus Design 原始專案的本地建置版本
=====================================================

本專案基於 Quadra (https://github.com/quadra-game/quadra) 原始碼，做了以下修改：

- 移除語言選單中的簡體/繁體中文選項，僅保留 English / French
- 使用 CMake + Visual Studio 2022 建置系統
- 使用 vcpkg 管理第三方依賴

環境需求
--------

### 安裝 Visual Studio 2022

下載 [Visual Studio 2022 Community](https://visualstudio.microsoft.com/zh-hant/vs/community/) 並安裝。
安裝時請勾選「**使用 C++ 的桌面開發**」工作負載。

### 安裝 CMake

下載 [CMake](https://cmake.org/download/)（建議 3.20 以上版本），安裝時選擇「Add CMake to the system PATH」。

### 安裝 vcpkg

```powershell
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
```

### 透過 vcpkg 安裝依賴套件

```powershell
cd C:\vcpkg
.\vcpkg install sdl2:x64-windows libpng:x64-windows zlib:x64-windows boost-filesystem:x64-windows boost-system:x64-windows
```

建置步驟
--------

> 以下命令在 PowerShell 7+ 中執行。

**1. 設定 CMake**

從專案根目錄（`quadra/`）執行：

```powershell
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_PREFIX_PATH="C:\vcpkg\installed\x64-windows"
```

> 如果 vcpkg 安裝在其他路徑，請調整 `CMAKE_PREFIX_PATH`。

**2. 編譯主程式**

```powershell
cmake --build . --config Release
```

這一步會依序：
- 編譯 `wadder.exe`（資源打包工具）
- 執行 wadder 產生 `quadra.res`（遊戲資源檔）
- 編譯 `quadra.exe`

**3. 執行**

```powershell
cd Release
.\quadra.exe
```

如果提示缺少 DLL，將 vcpkg 的 DLL 複製到 Release 目錄：

```powershell
copy C:\vcpkg\installed\x64-windows\bin\SDL2.dll .\Release\
copy C:\vcpkg\installed\x64-windows\bin\libpng16.dll .\Release\
copy C:\vcpkg\installed\x64-windows\bin\z.dll .\Release\
copy C:\vcpkg\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll .\Release\
```

Portable 版本建置
-----------------

Portable 版本可將所有依賴打包到單一目錄，無需安裝任何執行環境即可執行。

**1. 先完成上述建置步驟**（確保 `build\Release\quadra.exe` 已產生）。

**2. 手動產生 quadra.res**（如果編譯時未自動產生）：

```powershell
cd build
.\Release\wadder.exe ..\ .\quadra.res ..\resources.txt
```

> wadder.exe 需要 SDL2.dll 和 boost_filesystem DLL，可先複製到 `build\Release\` 下。

**3. 建立 portable 目錄並複製所有必要檔案**：

```powershell
mkdir ..\portable
copy .\Release\quadra.exe ..\portable\
copy .\quadra.res ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\SDL2.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\libpng16.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\z.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll ..\portable\
```

**4. 執行 portable 版本**：

```powershell
cd ..\portable
.\quadra.exe
```

`portable\` 目錄可複製到任何 Windows 10/11 x64 電腦上直接執行。若目標電腦沒有 VC++ 執行階段，需一併安裝 [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)。

檔案結構
--------

```
quadra/
├── README.md              # 本檔案
├── README_UPSTREAM.md     # 原作者說明文件
├── CMakeLists.txt         # CMake 建置腳本
├── resources.txt          # 資源檔案清單
├── source/                # C++ 原始碼
├── fonts/                 # 點陣字型 (.fnt)
├── images/                # 圖形資源 (.png)
├── sons/                  # 音效資源 (.wav)
├── textes/                # 語言字串表 (.txt)
├── demos/                 # 展示錄影 (.rec)
├── server/                # Qserv 伺服器腳本
├── stats/                 # 遊戲統計工具
├── packages/              # 打包設定檔
└── portable/              # 已編譯好的可攜版本（不進版控）
```

授權
----

原始專案採用 GNU Lesser General Public License v2.1，詳見 `LICENSE` 及 `README_UPSTREAM.md`。
