# Quadrai - Quadra Revival Project

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

本專案基於 Quadra (https://github.com/quadra-game/quadra) 原始碼，主要變更：

- **Qserv 伺服器** — 以 Go 重寫，支援 Windows/Linux，含存取日誌與整合測試
- **自動公網 IP 偵測** — Host 端開遊戲時自動取得 NAT 對外 IP，確保遠端玩家能連線
- **遊戲託管 port 分離** — 預設 27910（避免與 qserv port 3456 衝突）
- **連線 timeout** — HTTP 連線 10 秒 connect timeout + 15 秒 receive timeout
- **關閉外部連線** — 停用 GoogleCode 自動更新、LudusDesign 連結、GitHub 版本提示
- **CMake + vcpkg + PowerShell 一鍵建置**

---

## 下載

從 [Releases](https://github.com/mamashow5566/quadrai/releases) 下載最新的 `quadra_portable.zip`，解壓縮後執行 `quadra.exe` 即可。

> 若提示缺少 VC++ Runtime，請安裝 [vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe)

---

## 多人連線設定

### Qserv 伺服器

Quadra 預設連線至 `quadra.bearmeta.io:3456`。若需自架伺服器：

```powershell
cd quadra\server\qserv
.\build_qserv.ps1          # 編譯 + 打包
.\output\qserv_portable\start.bat   # 啟動
```

### Client 端設定

1. 啟動 Quadra → **Options → Advanced**
2. **Game server address**：qserv 伺服器 IP 或域名（如 `quadra.bearmeta.io`）
3. **Port**：遊戲託管 port（預設 27910）

### 開 Host（需 Port Forwarding）

1. Multi Player → TCP/IP Internet → **Host a new game**
2. **Public: Yes**（必須勾選）
3. 路由器 forward port `27910` 到 Host 電腦

### 加入遊戲

1. Multi Player → TCP/IP Internet → **Refresh**
2. 點選遊戲 → **Join**
3. 兩邊 Ready 後，Host 按 **Pause/Break** 鍵開始倒數

> 詳細遊戲規則請參閱 [GAMEPLAY.md](GAMEPLAY.md)

---

## 環境需求

| 軟體 | 版本 | 用途 |
|------|------|------|
| Visual Studio 2022 | 17.0+ | C++ 編譯器 |
| CMake | 3.20+ | 建置系統 |
| vcpkg | 最新版 | 套件管理 |
| Go | 1.21+ | qserv 伺服器編譯 |

### 快速安裝

```powershell
# Visual Studio 2022 BuildTools
winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"

# CMake
winget install Kitware.CMake

# vcpkg
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg install sdl2:x64-windows libpng:x64-windows zlib:x64-windows boost-filesystem:x64-windows boost-system:x64-windows
```

---

## 建置

### Quadra 遊戲端

```powershell
.\build_quadra.ps1
```

產出：
- `quadra\portable\` — 可攜資料夾
- `quadra_portable.zip` — 發布用壓縮檔

### Qserv 伺服器

```powershell
cd quadra\server\qserv
.\build_qserv.ps1
```

產出：`output\qserv_portable.zip`

### 疑難排解

| 問題 | 解法 |
|------|------|
| CMake 找不到 VS | 安裝 VS 2022 時勾選「使用 C++ 的桌面開發」 |
| 缺少 DLL | 安裝 [vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe) |
| qserv 連不上 | 確認 port 3456 防火牆允許、無其他程序佔用 |
| 遊戲列表看不到 Host | Host 需勾選 Public: Yes、router 需 forward port 27910 |

---

## 檔案結構

```
quadrai/
├── build_quadra.ps1         # Quadra 一鍵建置
├── README.md                # 本檔案
├── GAMEPLAY.md              # 遊戲操作規則
├── DEVELOPMENT.md           # 開發者架構文件
├── .gitignore
├── quadra/
│   ├── CMakeLists.txt
│   ├── source/              # C++ 原始碼
│   ├── server/qserv/        # Qserv Go 伺服器
│   │   ├── build_qserv.ps1  # qserv 一鍵編譯打包
│   │   ├── test_qserv.ps1   # 整合測試 (10 pass)
│   │   └── qserv_release.txt # 版本資訊
│   ├── fonts/ images/ sons/ textes/ demos/
│   └── portable/            # 可攜執行包（不進版控）
```

---

## 授權

原始專案採用 GNU Lesser General Public License v2.1，詳見 `LICENSE` 及 `README_UPSTREAM.md`。
