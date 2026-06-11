# Quadra 開發文件

## 1. 專案架構

```
quadra/
├── CMakeLists.txt          # CMake 建置系統 (vcpkg 依賴: zlib, libpng, SDL2, Boost)
├── config.h.cmakein        # 版本設定模板 (VERSION_MAJOR/MINOR/PATCHLEVEL)
├── resources.txt           # 資源列表 (供 wadder 打包用)
├── source/                 # 原始碼
│   ├── main.cc/h           # 程式入口 main()
│   ├── quadra.cc/h         # start_game() 初始化流程、方塊繪製
│   ├── overmind.cc/h       # 核心排程器 (Executor/Module 協作式多工)
│   ├── global.cc/h         # 全域常數、buffer、quit 旗標
│   ├── cfgfile.cc/h        # Config 設定檔讀寫
│   ├── command.cc/h        # 命令列參數解析
│   ├── stringtable.cc/h    # 多語系字串表
│   │
│   ├── video.cc/h          # Video 抽象類別 (SDL 視窗/全螢幕)
│   ├── video_dumb.cc/h     # Video_dumb (無頭模式/專用伺服器)
│   ├── bitmap.cc/h         # Bitmap (8-bit 索引色緩衝區)
│   ├── clipable.cc/h       # Clipable 裁剪區域基礎類別
│   ├── sprite.cc/h         # Sprite (含熱點遮罩)、Font/Fontdata
│   ├── palette.cc/h        # Palette 256 色、Remap、Fade
│   ├── color.cc/h          # Color 區塊著色器 (9 種方塊顏色)
│   ├── cursor.cc/h         # Cursor 滑鼠游標
│   │
│   ├── input.cc/h          # Input 鍵盤/滑鼠輸入
│   ├── sound.cc/h          # Sound SDL 音訊後端、Sample
│   ├── sons.cc/h           # Samples 音效集合 (所有遊戲音效)
│   │
│   ├── resmanager.cc/h     # Resmanager 資源管理器 (多層 .res 覆蓋)
│   ├── resfile.cc/h        # Resfile/Resdata (UGS 格式封裝檔)
│   ├── res.cc/h            # Res 體系 (Res_dos/Res_doze/Res_mem)
│   ├── res_name.cc/h       # ResName 資源名稱
│   ├── res_compress.cc/h   # Res_compress 解壓縮包裝器
│   │
│   ├── fonts.cc/h          # Fonts 字型載入管理
│   ├── texte.h             # Textbuf、ST_* 字串表巨集
│   ├── unicode.cc/h        # Unicode 支援
│   │
│   ├── game.cc/h           # Game 遊戲狀態機 (單機/網路/伺服器)
│   ├── canvas.cc/h         # Canvas 玩家畫布 (36x18 網格核心邏輯)
│   ├── bloc.cc/h           # Bloc 方塊 (7 種 x 4 旋轉)
│   ├── score.cc/h          # Score 計分/統計/排序
│   ├── stats.h             # CS/GS 統計結構
│   ├── attack.h            # Attack 攻擊類型定義
│   ├── recording.cc/h      # Recording/Playback 錄影/重播
│   │
│   ├── overmind.cc/h       # Overmind/Executor/Module 排程架構
│   ├── inter.cc/h          # Inter/Zone UI 容器與事件分派
│   ├── pane.cc/h           # Pane 多人遊戲面板體系
│   ├── chat_text.cc/h      # Chat_text 聊天系統
│   ├── zone.cc/h           # Zone 子類別 (遊戲畫布、區塊預覽等)
│   ├── zone_text_clock.cc/h # Zone_text_clock 時鐘
│   ├── listbox.cc/h        # Zone_listbox 捲動選單
│   │
│   ├── menu.cc/h           # 所有選單 Module
│   ├── menu_base.cc/h      # Menu_standard/fadein/quit 基礎類別
│   ├── menu_demo_central.cc/h # 重播中心選單
│   ├── game_menu.cc/h      # 遊戲內選單
│   │
│   ├── net.cc/h            # Net 網路引擎 (TCP+UDP)
│   ├── net_stuff.cc/h      # Net_starter、Quadra_param
│   ├── net_list.cc/h       # Net_list 玩家清單管理
│   ├── net_server.cc/h     # Net_server/Net_client 封包處理
│   ├── multi_player.cc/h   # Multi_player 多人遊戲 Module
│   ├── qserv.cc/h          # Qserv HTTP 遊戲伺服器註冊
│   ├── http_post.cc/h      # HTTP POST 客戶端
│   ├── http_request.cc/h   # HTTP 請求客戶端
│   ├── notify.cc/h         # Observable/Notifyable 觀察者模式
│   ├── packet.cc/h         # Packet 封包基礎類別
│   ├── packets.cc/h        # 所有具體封包類型
│   ├── net_buf.h           # Net_buf 網路緩衝區
│   ├── net_call.h          # Net_callable 回呼介面
│   │
│   ├── buf.cc/h            # Buf 動態位元組緩衝區
│   ├── clock.cc/h          # Clock 時間格式化
│   ├── crypt.cc/h          # 加密工具
│   ├── dict.cc/h           # Dict 鍵值字典
│   ├── error.cc/h          # msgbox/skelton_msgbox 除錯輸出
│   ├── id.cc/h             # Identifyable 唯一 ID
│   ├── image_png.cc/h      # PNG 載入
│   ├── misc.cc/h           # Fade_in/out、Wait_event/time
│   ├── player.cc/h         # Player 本地玩家資料
│   ├── random.cc/h         # Random LCG 偽隨機數
│   ├── highscores.cc/h     # 高分記錄
│   ├── update.cc/h         # AutoUpdater 自動更新檢查
│   ├── url.cc/h            # URL 編碼
│   ├── version.h           # 版本號常量
│   ├── types.h             # 平台相容巨集
│   └── wadder.cc           # 資源打包工具
│
├── textes/                 # 語言文字檔
├── images/                 # PNG 圖形資源
├── sons/                   # WAV 音效資源
├── fonts/                  # 字型資源
├── demos/                  # 示範錄影
└── overlay/                # 覆蓋圖層
```

---

## 2. 程式進入點與初始化流程

### 2.1 main() → start_game()

```
main()
  ├── SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)
  ├── atexit(delete_obj)
  ├── 擷取 exe_directory (移除檔名與結尾路徑分隔符)
  ├── 解析命令列參數 → Command::add()
  └── return start_game()

start_game()
  ├── 解析特殊旗標 (--113, --debug)
  ├── init_directory()           # 設定 quadradir (Win: APPDATA, Unix: ~/.quadra)
  ├── 資源載入:
  │   ├── resmanager->loadresfile("quadra.res")        # 主要資源
  │   ├── resmanager->loadresfile("quadra%i%i%i.res")  # 版本特化資源
  │   └── resmanager->loadresfile(patch/theme)         # 可選主題覆蓋
  ├── config.read()              # 讀取使用者設定檔
  ├── Stringtable(language)      # 載入多語系字串
  ├── 解析 demo/錄影/視訊/音訊旗標
  ├── init_stuff():
  │   ├── Video::New(640, 480, "Quadra")     # 視窗建立
  │   ├── fonts.init()                        # 字型載入
  │   ├── Input::New()                        # 輸入初始化
  │   ├── Sound::New()                        # 音訊初始化
  │   ├── Chat_text、Net_starter              # 聊天/網路背景執行緒
  │   ├── 載入所有 Samples (音效)             # sons.*
  │   └── Cursor、fteam[8] (隊伍字型)        # 游標/隊伍著色字型
  ├── [非 --novideo] AutoUpdater::start()
  ├── 建立 Executor 堆疊:
  │   ├── Menu_intro()           # 開場動畫
  │   ├── [--server] Game() + Menu_startserver()
  │   ├── [--connect] Menu_startconnect()
  │   └── [--play] Demo_multi_player()
  ├── main_loop(menu)            # 進入主遊戲迴圈
  └── deinit_stuff()             # 清理
```

---

## 3. 核心系統詳解

### 3.1 Executor/Module 架構 (協作式多工)

整個遊戲基於堆疊式協作多工，而非傳統的遊戲狀態機：

```
Overmind (全域單例 overmind)
  └── vector<Executor*> execs

Executor
  └── vector<Module*> modules   (堆疊，頂端為當前活躍 Module)
      ├── Module::init()          (首次呼叫)
      ├── Module::step()          (後續每次呼叫)
      └── 完成後自動移除，繼續下一個

Module (所有遊戲狀態的基礎類別)
  ├── call(module)   → 在自身堆疊頂端加入新 Module
  ├── exec(module)   → 替換自身為新 Module
  └── ret()          → 標記完成，回到呼叫者
```

**Menu** 繼承 Module + Inter，`step()` 回傳被點擊的 `Zone*`。

### 3.2 視訊系統 (Video)

```
Video (抽象基礎類別)
├── Video_bitmap* vb      # 主畫面緩衝區 (640x480)
├── Palette pal           # 256 色調色盤
├── framecount            # 幀計數器
├── need_paint            # 髒污旗標
├── end_frame()           # 翻轉顯示
└── Video::New() 工廠:
    ├── 真實 SDL 視訊 (視窗/全螢幕)
    └── Video_dumb (無頭/專用伺服器)
```

**Video_bitmap** 提供低階繪製原語：`hline()`, `vline()`, `put_pel()`, `put_bitmap()`, `put_sprite()`, `rect()`, `box()`.

**Palette** 256 色管理，**Fade** 平滑調色盤過渡，**Remap** 色彩重映射。

**Color** 方塊著色器：`color[9]` 九種方塊主色，`Color::shade(n)` 從亮到暗共 8 階明暗。

### 3.3 輸入系統 (Input)

```
Input::New() 工廠
├── keys[SDL_NUM_SCANCODES]    # 每鍵 2 位元: PRESSED(1) + RELEASED(2)
├── mouse.button[4]            # 滑鼠按鈕狀態
├── mouse.wheel                # 滾輪偏移
├── key_buf[MAXKEY]            # 文字輸入緩衝區
└── check() → 每幀輪詢 SDL 事件
```

### 3.4 音訊系統 (Sound)

```
Sound (SDL 音訊後端)
└── audio_callback() → 混音、格式化後輸出

Sample (載入 Res_doze(res_XXX_wav))
└── play(vol, pan, freq)

Samples (sons.h): 所有遊戲音效集合
├── UI: click, point, fadein, fadeout
├── 方塊: depose(1-4), flash
├── 遊戲: levelup, bonus1, pause, start
├── 聊天: msg, potato_get, potato_rid
└── 倒數: minute~one (10個)
```

### 3.5 資源管理系統 (Resmanager)

```
Resmanager (全域單例 resmanager)
├── vector<Resfile*> files          # 按載入順序的多層 .res 檔案
├── loadresfile(fname) → 載入 .res 封裝檔
│   └── Resfile::thaw() → 解析 UGS 格式
│       └── Resdata 鏈結串列 (name + size + data)
├── get(resname, &data) → 反向搜尋 (後載入優先)
└── 覆蓋機制: 後載入的同名資源替換先載入的

Res 階層 (存取資源的方式):
├── Res_doze(name) → 從 Resmanager 載入
├── Res_dos(file)  → 直接檔案讀取
└── Res_compress   → 解壓縮封裝 (用於 demo 回放)
```

**wadder** 工具：從 `resources.txt` 清單建立 `.res` 封裝檔。

### 3.6 字型系統 (Fonts)

```
Fonts (全域單例 fonts)
├── fonts.normal      # 比例字型
└── fonts.courrier    # 等寬字型

Fontdata (原始字型資料)
├── Sprite* glyph[256]      # 每個字元一個精靈
├── pre_width[256]          # 預計算字元寬度
└── width(str) → 字串像素寬度

Font (著色字型)
├── 建構: Font(Fontdata, palette, 目標色)
├── colorize() → 重新著色
├── draw(str, bitmap, x, y) → 繪製文字
└── fteam[8] → 8 種隊伍顏色的著色字型
```

### 3.7 設定檔系統 (Config)

```
Config (全域單例 config)
├── info:     語言、通訊埠、更新率、書籤伺服器
├── player[3]: 名稱、顏色、按鍵綁定、陰影、平滑、重複率
├── player2[3]: 障礙、密碼、連續模式、擴展按鍵
├── info2:    代理設定
├── info3:    自動更新設定
├── read()   → 二進位反序列化
├── write()  → 二進位序列化
└── default_config() → 預設值
```

---

## 4. 遊戲邏輯

### 4.1 Game 狀態機

```
Game (extend GS)
├── 遊戲模式: single / network / server
├── 特殊模式: survivor / hot_potato / blind / fullblind
├── 遊戲狀態: paused / terminated / delay_start
├── 結束條件: END_FRAG / END_TIME / END_POINTS / END_LINES
├── 攻擊設定: normal_attack / clean_attack / potato_attack
├── 其他: level_up / combo_min / boring_rules / auto_restart
├── 方法:
│   ├── restart()           # 重新開始回合
│   ├── check_potato()      # 熱馬鈴薯邏輯
│   ├── sendgameinfo()      # Qserv 更新
│   └── endgame()           # 結束遊戲

Game_params (遊戲參數)
└── set_preset(): FFA / SURVIVOR / PEACE / BLIND / FULLBLIND / HOT_POTATO / SINGLE
```

### 4.2 Canvas 玩家畫布 (核心遊戲邏輯)

```
Canvas (extend CS, 36列 x 18行)
├── 網格陣列:
│   ├── occupied[36][18]   # 已被方塊佔據?
│   ├── block[36][18]      # 方塊顏色/類型
│   ├── blinded[36][18]    # 被致盲?
│   ├── bflash[36][18]     # 消除動畫倒數
│   └── dirted[36][18]     # 髒污旗標 (重繪用)
├── 方塊狀態:
│   ├── bloc               # 當前落下中方塊
│   ├── next/next2/next3   # 預覽方塊佇列
│   └── bon[20]            # 待處理攻擊行佇列 (環形緩衝)
├── 核心方法:
│   ├── collide()          # 碰撞檢測
│   ├── calc_shadow()      # 落下預覽陰影
│   ├── give_line()        # 套用攻擊行 (附孔洞)
│   ├── step_bflash()      # 消除行閃爍+塌陷動畫
│   ├── calc_speed()       # 依等級計算落下速度
│   ├── set_next()         # 推進方塊佇列
│   ├── init_block()       # 初始化新方塊 (檢測死亡)
│   ├── blit_back()        # 繪製遊戲網格背景
│   ├── blit_bloc()        # 繪製落下中方塊+陰影
│   ├── blit_flash()       # 繪製消除閃爍
│   └── send_p_moves()     # 發送玩家操作 (網路)
├── 輸入處理:
│   ├── check_key(i)       # 檢查按鍵 (含重複率)
│   └── clear_key(i)       # 清除按鍵旗標
├── 多人對戰:
│   ├── potato_lines       # 熱馬鈴薯計數
│   ├── handicap           # 障礙系統
│   ├── moves (clientmoves)# 位元壓縮操作記錄
│   └── attacks[]          # 攻擊來源追蹤
└── 狀態: idle(0=忙碌/1=遊戲中/2=死亡/3=離開)
```

### 4.3 Bloc 方塊

```
Bloc (Tetris 方塊)
├── 7 種類型 (0=Cube ~ 6)
├── 每種 4 個旋轉
├── 靜態 4D 陣列: bloc[7][4][4][4] = [類型][旋轉][y][x]
├── 每個格子值 0-8 (0=空, 1-8=顏色)
├── draw(b, tx, ty)        # 繪製 (18x18 著色方格)
└── small_draw(b, tx, ty)  # 小型繪製 (預覽用)
```

### 4.4 Score 計分系統

```
Score
├── player_team[MAXPLAYERS]   # 玩家→隊伍對應
├── team_stats[MAXTEAMS]      # 每隊 CS 統計
├── stats[MAXPLAYERS]         # 每位玩家 CS 統計
├── team_order[] / order[]    # 排序後的排名
└── sort(type) → 依 CS::Stat_type 排序

CS (Canvas Stats) 統計類型 (~70項):
├── 消除: CLEAR00~CLEAR20 (1~21行消除)
├── 死亡/擊殺: DEATH, FRAG
├── 總行/分數: LINESTOT, SCORE
├── 效能: PPM (每分鐘方塊), BPM
├── 回合: ROUND_WINS, SUICIDES
└── 連擊計數: COMBO00~COMBO20
```

---

## 5. 網路多人遊戲

### 5.1 架構總覽

```
Net (全域單例 net)
├── TCP: 連線管理、封包收發
├── UDP: 伺服器發現、遊戲列表
├── Net_connection 抽象層
│   └── Net_connection_tcp (實際 TCP 連線)
├── callback: addwatch(id, callable) 封包分派
├── 伺服器: start_server(), accept(), dispatch()
└── 客戶端: start_client(), connected()

Net_list (玩家清單)
├── Canvas* list[MAXPLAYERS]   # 8 個玩家槽位
├── Net_list_stepper (背景執行緒)
│   └── step_all() → 依序處理:
│       ├── Canvas::step()
│       ├── check_drop()         # 處理離線
│       ├── check_gone()         # 移除超時玩家
│       ├── check_first_frag()   # 生存者模式
│       ├── check_end_game()     # 遊戲結束
│       └── check_potato()       # 熱馬鈴薯
└── send() → 發送攻擊行
```

### 5.2 遊戲建立流程

```
伺服器端                           客戶端
────────                          ──────
Game(&params)                     
├── Net_server                    
├── Net_client                    
└── 暫停等待玩家加入                 
                                   Menu_startconnect(addr)
                                   ├── Net_client
                                   └── 發送 Packet_wantjoin
                                        │
Net_server::wantjoin() ←───────────────┘
├── 驗證
├── 發送 Packet_gameserver ──────────→ Net_client::net_call()
│                                        ├── 建立 Canvas[]
│                                        └── 發送 Packet_serverrandom
└── 遊戲開始
```

### 5.3 遊戲內封包流程

```
客戶端輸入 → Canvas::send_p_moves()
  → Packet_clientmoves → net->sendtcp()
    → 伺服器: Net_server::clientmoves()
      → 記錄操作 → step_all() → 計算攻擊
        → Net_list::send() → Packet_lines
          → 廣播給所有客戶端
            → Canvas::give_line() → 加入 bon[] 攻擊佇列
```

### 5.4 Qserv 伺服器註冊（遊戲大廳）

#### 架構

```
Host 機                   Qserv 機               Client 機
───────                  ────────                ────────
Host 開遊戲               qserv_x64.exe           TCP/IP Internet
監聽 :27910 (遊戲port)    監聽 :3456 (HTTP)       → Refresh
  │                          │                       │
  ├── POST postgame ────→   寫入 games/IP_PORT       │
  │                          │                       │
  │                          │  ←── POST getgames ───┤
  │                          │    回傳 Current games │
  │                          │                       │
  │  ←──────── TCP 直連 ──────────────────────── Join ──┤
  │     (對戰不經 qserv)                             │
```

#### Port 分離

| Port | 用途 | 協定 | 方向 |
|------|------|------|------|
| `3456` | qserv HTTP API | TCP | 入站 |
| `27910` | Quadra 遊戲託管 | TCP | 入站 |

> **重要**：兩個 port 必須不同，否則 Quadra Host 和 qserv 會搶同一個 port。

#### qserv HTTP API

```
POST /
Content-Type: application/x-www-form-urlencoded
Body: data=<cmd>\n<key> <value>\n...

命令：
  postgame       註冊/更新遊戲 (info/name, port, info/players...)
  deletegame     刪除遊戲
  getgames       查詢遊戲列表
  postdemo       上傳分數 (score, info/player, rec...)
  gethighscores  查詢排行榜 (num)
```

回應格式：`text/plain`，第一行為狀態（`Ok`、`Game added`、`Current games`...），其餘為 `key value` 行。

#### Quadra Client → Qserv 連線設定

| 設定項 | 位置 | 說明 |
|--------|------|------|
| `config.info.game_server_address` | Options → Advanced → Game server address | 使用者自訂 qserv 位址 |
| `config.info3.default_game_server_address` | 自動更新取得 | 動態預設值 |
| `config.info.port_number` | Options → Advanced → Port | **遊戲託管** port（非 qserv port） |

優先順序：
1. 使用者自訂 `game_server_address`（如 `172.28.0.66` 或 `quadra.bearmeta.io`）
2. 自動更新的 `default_game_server_address`
3. 程式內 fallback：`quadra.bearmeta.io:3456`

> 格式可只填 IP/主機名，不帶 port 時自動用 `3456`。

#### Host 遊戲註冊流程

```
1. Host 畫面設定 Public: Yes
2. Create_game_end::init() → sendgameinfo(true) → POST deletegame (清舊紀錄)
3. Net_list::step() 計時器 → sendgameinfo(false) → POST postgame (刊登)
4. 定時重送 postgame 續命 (< 180 秒)
5. Host 關閉 → sendgameinfo(true) → POST deletegame
```

> Qserv 會在 `getgames` 時自動清除超過 180 秒未更新的遊戲。

#### Client 查詢遊戲列表

```
1. TCP/IP Internet → Refresh
2. Menu_multi_internet → Qserv::create_req() → POST getgames
3. 解析回應 "Current games\nIP:PORT/key value..."
4. 顯示遊戲名稱與玩家數
```

#### 去重規則 (getgames)

| 條件 | 去重 Key |
|------|---------|
| `quadra_version == "1.1.2"` | `IP:PORT`（移除 `players` 欄位） |
| 無 `quadra_version` 且無 `qsnoop_version` | Host only（不含 port） |
| 其他 | `IP:PORT` |

#### HTTP 連線機制

- TCP socket 為 non-blocking，透過 `select()` 輪詢
- 連線 timeout：10 秒（`CONNECT_TIMEOUT`）
- 接收 timeout：15 秒（`RECEIVE_TIMEOUT`）
- `Http_request::done()` 逾時自動中斷
- 支援 HTTP Redirect（永久轉址）
- 支援 HTTP Proxy（`config.info2.proxy_address`）

#### qserv 伺服器 (Go 實作)

```
quadra/server/qserv/
  main.go            HTTP 伺服器，--port --datadir --logfile --debug
  handler.go         請求路由 + 5 個命令處理器
  data.go            資料目錄、cleanup registry
  dumper.go          Perl Data::Dumper 序列化
  log.go             存取日誌初始化、[REQ]/[RES]/[ERR]/[DATA] 格式記錄
  go.mod             Go module 定義
  build_qserv.ps1    一鍵編譯打包腳本
  test_qserv.ps1     整合測試（10/10 pass）
  qserv.md           詳細規格書
  qserv_readme.md    維護參考文件
  qserv_release.txt  版本號碼與 changelog
```

詳細 API 規格見 `quadra/server/qserv/qserv.md`。

- 遊戲資料：`<datadir>/games/<IP_PORT>`（Perl Dumper 格式）
- 分數資料：`<datadir>/scores/<SCORE>`（Perl Dumper 格式）
- Windows 上 `:` 自動轉為 `_` 以避免檔名問題
- 啟動時顯示本機 IP 位址，方便 client 設定

#### 分數同步流程

```
1. High Scores → Sync
2. 有本地紀錄 → POST postdemo（上傳自己的 demo）
   無本地紀錄 → POST gethighscores（純查詢）
3. 解析 high000/... high001/... 的 key value
4. 儲存為全域分數檔案
```

#### 除錯檢查清單

| 問題 | 檢查 |
|------|------|
| Host 開遊戲但列表看不到 | qserv log 是否有 `postgame`？Public 是否 Yes？ |
| Client Refresh 無反應 | Game server address 是否正確？Port 是否 3456？ |
| curl localhost OK 但遠端不行 | 防火牆是否允許 port 3456 入站？ |
| 兩個 qserv 搶 port | `taskkill /f /im qserv_x64.exe` 後重啟 |
| 遊戲託管 port 和 qserv port 衝突 | Quadra port 設為 27910（非 3456） |

---

## 6. UI 系統

### 6.1 Inter/Zones 架構

```
Inter (UI 容器 / 事件分派器)
├── vector<Zone*> zone         # 所有 UI 元素
├── process() 每幀處理:
│   ├── 鍵盤導航 (Tab/方向鍵切換焦點)
│   ├── 滑鼠懸停/點擊檢測
│   └── Zone::process() (計時器/動畫)
├── draw_zone() 每幀繪製:
│   ├── 繪製所有髒污/啟用的 Zone
│   ├── 繪製鍵盤焦點矩形
│   └── 繪製 stay_on_top 圖層
└── first_zone 分隔「繼承」與「新增」區域

Zone (基礎 UI 元素)
├── 屬性: 位置、大小、髒污、可聚焦、啟用
├── 虛擬方法:
│   ├── draw()      # 繪製
│   ├── in()        # 座標檢測
│   ├── clicked()   # 點擊處理
│   ├── process()   # 每幀處理
│   └── entered()/leaved()  # 懸停變化
├── Zone_sprite       # 精靈圖片
├── Zone_bitmap       # 點陣圖
├── Zone_text         # 文字
├── Zone_text_button  # 3D 斜面按鈕
├── Zone_text_input   # 文字輸入框
├── Zone_panel        # 邊框容器 (含內部 Video_bitmap)
├── Zone_listbox      # 捲動選單
└── Zone_canvas       # 遊戲畫布
```

### 6.2 Pane 面板體系

遊戲內多人 UI 使用 Pane 面板系統：

```
Pane (繼承 Zone)
├── Pane_option         # 主選項面板
├── Pane_singleplayer   # 簡化單人面板
├── Pane_close          # 自動關閉面板
├── Pane_selectscheme   # 關卡選擇
├── Pane_playerinfo     # 玩家列表 (含自動觀看)
├── Pane_server         # 管理員控制
├── Pane_scoreboard     # 分數顯示
├── Pane_chat           # 聊天面板
├── Pane_blockinfo      # 對手方塊資訊
├── Pane_comboinfo      # 連擊狀態
├── Pane_playerstartup  # 遊戲前設定
├── Pane_playerjoin     # 加入手續
├── Pane_startgame      # 開始遊戲
└── Pane_startwatch     # 觀戰模式
```

### 6.3 Chat_text 聊天系統

```
Chat_text
├── 22 行聊天訊息 (CHAT_NBLINE)
├── 每行: 文字 + 隊伍顏色
├── add_text(team, text) → 捲動加入
├── net_call(p) → 處理 Packet_servermsg
└── message() 全域函數 → 發送聊天訊息
```

---

## 7. 主遊戲迴圈

```
main_loop(Executor& menu)
├── overmind.start(&menu)            # 註冊選單執行器
└── while (!menu.done):
    ├── last = SDL_GetTicks()
    ├── [固定 10ms 遊戲步進]:
    │   while (acc >= 10):
    │       overmind.step()          # *** 核心步進 ***
    │       framecount++
    │       acc -= 10
    ├── input->check()               # 輪詢輸入事件
    ├── if (ecran && !video_is_dumb):
    │     ecran->draw_zone()         # 繪製髒污區域
    ├── video->end_frame()           # 翻轉顯示
    ├── [除錯: F8/F9/F10 速度控制]
    └── acc += delta (限制避免死亡螺旋)
```

**Overmind::step()** 迭代所有 Executor。每個 `Executor::step()` 呼叫頂層 Module 的 `init()`（僅首次）和 `step()`（後續每次）。

### 渲染管線

```
ecran->draw_zone()
├── 遍歷所有髒污 Zone
│   └── Zone::draw() 例如:
│       Zone_canvas::draw()
│       ├── canvas->blit_back()     # 網格背景
│       ├── canvas->blit_bloc()     # 落下方塊+陰影
│       └── canvas->blit_flash()    # 消除閃爍
│       → 寫入 pan (Video_bitmap)
│       → 寫入 video->vb (主畫面緩衝區)
└── video->end_frame()
    └── SDL_RenderPresent
```

---

## 8. Canvas 遊戲步進 (每 tick)

```
Canvas::step() (由 Net_list_stepper::step_all() 驅動)
├── 處理 bon[] 待攻擊行
├── 處理方塊落下 (重力 = speed)
├── 處理玩家輸入 (Packet_clientmoves 或本地)
├── 碰撞檢測與方塊放置
├── 行消除檢測與計分
├── 攻擊生成 (發送給其他玩家)
├── 升級邏輯
├── 死亡檢測
└── 標記髒污區域供重繪
```

---

## 9. 全域單例總覽

| 變數 | 類型 | 用途 |
|------|------|------|
| `overmind` | `Overmind` | 全域排程器 |
| `ecran` | `Inter*` | 當前活躍 UI 畫面 |
| `video` | `Video*` | 視訊子系統 |
| `input` | `Input*` | 輸入子系統 |
| `sound` | `Sound*` | 音訊子系統 |
| `resmanager` | `Resmanager*` | 資源管理器 |
| `config` | `Config` | 使用者設定 |
| `stringtable` | `Stringtable*` | 多語系字串 |
| `command` | `Command` | 命令列解析 |
| `chat_text` | `Chat_text*` | 聊天緩衝 |
| `net_starter` | `Net_starter*` | 網路背景執行緒 |
| `net` | `Net*` | 網路引擎 |
| `game` | `Game*` | 當前遊戲狀態 |
| `fonts` | `Fonts` | 字型 |
| `sons` | `Samples` | 音效集合 |
| `cursor` | `Cursor*` | 滑鼠游標 |
| `recording` | `Recording*` | 錄影 |
| `playback` | `Playback*` | 重播 |
| `color[9]` | `Color*[9]` | 方塊調色盤 |
| `fteam[8]` | `Font*[8]` | 隊伍字型 |
| `quadradir` | `char[1024]` | 使用者資料目錄 |
| `quitting` | `bool` | 全域退出旗標 |

---

## 10. 建置與執行

> 快速建置請使用 `build_quadra.ps1`，詳情參閱 `README.md`。

### 10.1 Windows (vcpkg)

```powershell
# 安裝相依套件
vcpkg install zlib:x64-windows libpng:x64-windows sdl2:x64-windows boost-system:x64-windows boost-filesystem:x64-windows

# 一般建置
cmake -B build -S quadra -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake"
cmake --build build --config Release

# Portable 發行版 (綑綁所有 DLL)
cmake -B build -S quadra -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" -DPORTABLE_BUILD=ON
cmake --build build --config Release --target portable

# 執行
.\build\Release\quadra.exe
```

### 10.2 macOS (Homebrew)

```bash
# 安裝相依套件
brew install sdl2 zlib libpng boost

# 一般建置
cmake -B build -S quadra
cmake --build build --config Release

# macOS App Bundle
cmake -B build -S quadra -DENABLE_APP_BUNDLE=ON
cmake --build build --config Release

# 執行
./build/Release/quadra
# 或 App Bundle:
open build/Release/quadra.app
```

### 10.3 Linux (apt)

```bash
# 安裝相依套件
sudo apt install libsdl2-dev zlib1g-dev libpng-dev libboost-system-dev libboost-filesystem-dev

# 建置
cmake -B build -S quadra
cmake --build build --config Release

# 執行
./build/Release/quadra
```

### 命令列參數

| 參數 | 說明 |
|------|------|
| `--debug` | 啟用除錯輸出 |
| `--novideo` | 無頭模式 |
| `--nosound` | 無音訊 |
| `--fullscreen` | 全螢幕 |
| `--dedicated` | 專用伺服器 |
| `--server` | 啟動伺服器 |
| `--connect <addr>` | 連線到伺服器 |
| `--play <demo>` | 播放錄影 |
| `--verify <demo>` | 驗證錄影 |
| `--english` / `--french` | 語言選擇 |
| `--patch <file>` | 載入主題覆蓋 |
| `--exec <script>` | 執行腳本 |

### macOS 注意事項

1. **SDL2 Framework**：若使用 Homebrew 安裝的 SDL2，CMake 會自動找到。若使用 framework 版本，需設定 `-DSDL2_DIR=/Library/Frameworks/SDL2.framework`
2. **App Bundle**：設定 `-DENABLE_APP_BUNDLE=ON` 時會建立 `.app`，並自動使用 `SDL_GetBasePath()` 定位資源
3. **程式碼簽署**：若執行時遇到安全性警告，需執行：
   ```bash
   sudo xattr -dr com.apple.quarantine quadra.app
   ```
