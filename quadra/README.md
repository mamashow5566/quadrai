Quadra - 基於 Ludus Design 原始專案的本地建置版本
=====================================================

本專案基於 Quadra (https://github.com/quadra-game/quadra) 原始碼，做了以下修改：

- 移除語言選單中的簡體/繁體中文選項，僅保留 English / French
- 使用 CMake + Visual Studio 2022 建置系統
- 使用 vcpkg 管理第三方依賴

環境需求
--------

- Windows 10/11 x64
- Visual Studio 2022 (Community 版即可)
- CMake 3.20+
- [vcpkg](https://github.com/microsoft/vcpkg) (安裝於 `C:\Users\${USERNAME}\vcpkg` 或自訂路徑)

透過 vcpkg 安裝的依賴套件：

```
vcpkg install sdl2:x64-windows sdl2-ttf:x64-windows libpng:x64-windows zlib:x64-windows boost-filesystem:x64-windows boost-system:x64-windows
```

建置步驟
--------

**1. 設定 CMake**

從 `quadra/` 目錄執行（根據你的 vcpkg 路徑調整 `CMAKE_PREFIX_PATH`）：

```powershell
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_PREFIX_PATH="C:\Users\$env:USERNAME\vcpkg\installed\x64-windows"
```

**2. 編譯**

```powershell
cmake --build . --config Release
```

這會先產生 `wadder.exe`（資源打包工具），再用它打包 `quadra.res`，最後編譯出 `quadra.exe`。

**3. 執行**

將必要的 DLL 複製到執行檔所在目錄，或將 vcpkg 的 `bin` 目錄加入 `PATH`：

```powershell
# 從 vcpkg 複製 DLL（一次性）
copy C:\Users\$env:USERNAME\vcpkg\installed\x64-windows\bin\SDL2.dll .\Release\
copy C:\Users\$env:USERNAME\vcpkg\installed\x64-windows\bin\libpng16.dll .\Release\
copy C:\Users\$env:USERNAME\vcpkg\installed\x64-windows\bin\z.dll .\Release\
copy C:\Users\$env:USERNAME\vcpkg\installed\x64-windows\bin\boost_filesystem-vc143-mt-x64-1_91.dll .\Release\
```

切換到 Release 目錄並執行：

```powershell
cd Release
.\quadra.exe
```

`quadra.res` 資源檔會自動產生於 `build/` 目錄下，quadra.exe 會在執行時從所在目錄尋找該檔案。

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
