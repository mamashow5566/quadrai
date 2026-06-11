Quadra - Quadra Revival Project
================================

專案歷史與背景 / Project History
---------------------------------

Quadra 是一款極具傳奇色彩的硬核多人連線方塊益智遊戲。它最初由獨立軟體工作室 **Ludus Design**（核心開發者包括 Pierre Phaneuf 與 Remi Veilleux 等人）於 1999 年作為商業共享軟體（Shareware）發表。憑藉著在當年極為領先的流暢網際網路對戰、獨特的重力物理與旋轉機制，Quadra 迅速在獨立遊戲界打響名號，並在 2008 年前後成為許多社群、學校與網咖舉辦連線比賽的首選神作。

隨著商業環境變遷，Ludus Design 於 2000 年 8 月做出了一個慷慨且具遠見的決定：將 Quadra 的原始碼完全以 LGPL 條款開源。此後，專案交由全球開源社群共同維護，並陸續完成了 Linux、macOS 等跨平台移植。然而，隨著原作者步入主流科技巨頭（如 Google、Ubisoft 等）深耕，加上官方版權環境限縮與中央伺服器（Qserv）停機，這款經典作品逐漸淡出了大眾視野，封存於歷史的檔案庫中。

本專案（**Revival Project**）旨在 2026 年重新喚醒這份珍貴的開源記憶。我們將透過現代化的底層驅動（SDL2/SDL3）、建置系統（CMake）以及重構現代化中央伺服器，讓這款曾陪伴無數人度過熱血競技夜晚的經典遊戲，在現代作業系統甚至是網頁端（WebAssembly）再度重現光芒。

---

*Quadra is a legendary hardcore multiplayer puzzle game. Originally released in 1999 as shareware by independent studio **Ludus Design** (core developers: Pierre Phaneuf, Remi Veilleux, and others), it quickly gained fame for its ahead-of-its-time smooth online multiplayer, unique gravity physics, and rotation mechanics. By 2008, it had become a cult classic for LAN competitions in communities, schools, and internet cafes.*

*In August 2000, Ludus Design made the generous and visionary decision to open-source Quadra under the LGPL license. The global open-source community continued its development, porting it to Linux, macOS, and beyond. However, as the original authors moved on to tech giants (Google, Ubisoft, etc.), and with the shutdown of the central server (Qserv), this classic faded from the spotlight.*

*This **Revival Project** aims to rekindle this precious open-source memory in 2026. With modern backends (SDL2/SDL3), a CMake build system, and a rebuilt central server, we intend to bring this timeless competitive gem back to modern operating systems — and even the web (WebAssembly).*

---

本專案基於 Quadra (https://github.com/quadra-game/quadra) 原始碼，做了以下修改：

- 使用 CMake + Visual Studio 2022 建置系統
- 使用 vcpkg 管理第三方依賴
- 使用 `build.ps1` PowerShell 腳本一鍵建置

環境需求
--------

| 軟體 | 版本需求 | 用途 |
|------|----------|------|
| **Visual Studio 2022** | 17.0+ (Community / Professional / Enterprise) 或 BuildTools | C++ 編譯器 (MSVC) |
| **CMake** | 3.20+ | 跨平台建置系統 |
| **vcpkg** | 最新版 | C/C++ 套件管理 |
| **Git** | 任何版本 | 下載 vcpkg |

### 快速安裝 (winget)

```powershell
# Visual Studio 2022 Community
winget install Microsoft.VisualStudio.2022.Community
# 安裝後需手動加入 C++ 工具：開啟「Visual Studio Installer」> 修改 > 勾選「桌面開發 (C++)」

# Visual Studio 2022 BuildTools (僅編譯工具，無 IDE，較輕量)
winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"

# CMake
winget install Kitware.CMake

# Git
winget install Git.Git
```

### 手動安裝

**Visual Studio 2022**：下載 [Community 版](https://visualstudio.microsoft.com/zh-hant/vs/community/) 安裝時勾選「**使用 C++ 的桌面開發**」工作負載。

**CMake**：下載 [CMake](https://cmake.org/download/)，安裝時勾選「Add CMake to the system PATH」。

### 安裝 vcpkg 及依賴套件

```powershell
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg install sdl2:x64-windows libpng:x64-windows zlib:x64-windows boost-filesystem:x64-windows boost-system:x64-windows
```

建置步驟
--------

### 一鍵建置 (推薦)

從專案根目錄執行 PowerShell：

```powershell
.\build.ps1
```

此腳本會自動偵測環境、檢查缺失的套件並提供安裝提示，依序完成：
1. CMake 配置
2. 編譯 wadder.exe（資源打包工具）
3. 產生 quadra.res（遊戲資源檔）
4. 編譯 quadra.exe（主程式）
5. 封裝可攜版本到 `quadra\portable\`

```powershell
# 其他用法
.\build.ps1 -Help          # 顯示完整說明
.\build.ps1 -Interactive   # 逐步互動模式 (每步驟手動確認)
.\build.ps1 -Step configure # 只執行 CMake 配置
.\build.ps1 -Clean         # 清除後重建
.\build.ps1 -Portable      # 建置後封裝可攜版本
```

### 手動逐步建置

> 適用於需要手動控制或腳本無法執行的情況。

**1. CMake 配置**

```powershell
cd quadra
mkdir build; cd build
cmake .. -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_TOOLCHAIN_FILE="C:\vcpkg\scripts\buildsystems\vcpkg.cmake"
```

> 若 vcpkg 安裝在其他路徑，調整 `CMAKE_TOOLCHAIN_FILE`。

**2. 編譯 wadder**

```powershell
cmake --build . --target wadder --config Release
```

**3. 產生 quadra.res**

```powershell
cmake --build . --target quadra_res --config Release
```

**4. 編譯 quadra**

```powershell
cmake --build . --target quadra --config Release
```

**5. 執行**

```powershell
.\Release\quadra.exe
```

### 可攜版本

```powershell
# 自動封裝 (推薦)
.\build.ps1 -Portable

# 手動封裝
mkdir ..\portable
copy .\Release\quadra.exe ..\portable\
copy .\Release\quadra.res ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\SDL2.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\libpng16.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\z.dll ..\portable\
copy C:\vcpkg\installed\x64-windows\bin\boost_filesystem-vc*-mt-x64-*.dll ..\portable\
```

### 疑難排解

| 問題 | 解決方法 |
|------|----------|
| CMake 找不到 Visual Studio | 安裝 VS 2022 時務必勾選「使用 C++ 的桌面開發」 |
| `_snprintf` 編譯錯誤 | 已修復 Boost 標頭相容性，若仍出現請回報 |
| 缺少 DLL (SDL2.dll 等) | 將 `C:\vcpkg\installed\x64-windows\bin\*.dll` 複製到執行檔目錄 |
| vcpkg 套件版本不符 | 執行 `vcpkg update` 後重新 `vcpkg install` |
| 無法在目標電腦執行 | 安裝 [VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) |

詳情請參閱 `DEVELOPMENT.md`。

檔案結構
--------

```
quadrai/
├── build.ps1              # PowerShell 一鍵建置腳本
├── README.md              # 本檔案
├── README_UPSTREAM.md     # 原作者說明文件
├── DEVELOPMENT.md         # 開發者架構文件
├── .gitignore             # Git 排除規則
├── quadra/
│   ├── CMakeLists.txt     # CMake 建置腳本
│   ├── resources.txt      # 資源檔案清單
│   ├── source/            # C++ 原始碼
│   ├── fonts/             # 點陣字型 (.fnt)
│   ├── images/            # 圖形資源 (.png)
│   ├── sons/              # 音效資源 (.wav)
│   ├── textes/            # 語言字串表 (.txt)
│   ├── demos/             # 展示錄影 (.rec)
│   ├── server/            # Qserv 伺服器腳本
│   ├── stats/             # 遊戲統計工具
│   ├── packages/          # 打包設定檔
│   ├── build/             # 建置暫存（不進版控）
│   └── portable/          # 可攜執行包（不進版控）
```

目標平台：**Windows 10/11 x64**

授權
----

原始專案採用 GNU Lesser General Public License v2.1，詳見 `LICENSE` 及 `README_UPSTREAM.md`。
