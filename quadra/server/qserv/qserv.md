# QServ 規格書 — Go 重寫版 v1.0

> 狀態：**已完成並通過整合測試**（9/9 pass）
> 原始 Perl 腳本：`../qserv.pl`

---

## 一、專案結構

```
quadra/server/qserv/
  main.go             入口點、flag 解析、HTTP 伺服器啟動
  handler.go          請求路由、tweak、5 個命令處理器
  data.go             資料目錄初始化、cleanup registry、遊戲過期/分數清理
  dumper.go           Perl Data::Dumper 序列化（Load / Save）
  test.ps1            整合測試（自動啟動/停止伺服器，9 項測試）
  build_qserv.ps1   編譯打包腳本（產生 portable ZIP）
  qserv_readme.md     維護參考文件
  qserv.md            本規格書
```

---

## 二、API 規格

### 請求格式

```
POST /
Content-Type: application/x-www-form-urlencoded

data=<command>\n<key> <value>\n<key> <value>\n...
```

換行符號為真正換行字元，不帶 `\r`。

### 支援命令

| 命令 | 行為 | 成功回應 |
|------|------|----------|
| `postgame` | 註冊/更新遊戲 | `Game added` 或 `Game updated` |
| `deletegame` | 刪除遊戲 | `Game deleted` |
| `postdemo` | 上傳分數，自動回傳排行榜 | 同 `gethighscores` |
| `gethighscores` | 查詢排行榜 | `Ok\n` + 排名資料 |
| `getgames` | 查詢遊戲列表（含去重） | `Current games\n` + 遊戲資料 |
| 未知命令 | 預設歡迎訊息 | `Hi, I'm the NEW Quadra game server.\n...` |

### 錯誤回應

- `Bad data` — 參數格式錯誤或遺漏必要欄位
- `Game not found` — 欲刪除的遊戲不存在
- 所有回應 Content-Type 為 `text/plain`

---

## 三、請求處理流程

```
parseForm → 取 data 參數 → 按 \n 分割 → 第一行為命令, 其餘為 key value 參數
  → setParam() 建立巢狀 map
  → tweak() 預處理
  → 命令分發
  → if cleanup registry 非空 → 同步執行 cleanup
```

### tweak 預處理

1. `info/remoteaddr` ← 客戶端 IP（去除 port、去除 IPv6 括號 `[]`）
2. `port` ← 預設 `3456`，去除非數字字元，超過 `65535` 回退為 `3456`

### setParam / getParam

- `setParam(params, "a/b/c", "v")` → `{a: {b: {c: "v"}}}`
- `getParam(params, "a/b/c")` → `("v", true)`
- 所有值皆為 `string` 型別

---

## 四、命令詳細行為

### postgame

```
1. 組合 info/remoteaddr : port → gameAddr
2. 安全檢查：isSafePath(gameAddr)  // regex: ^[-\@\w.:]+$
3. 加入 info/lastupdate = Unix timestamp
4. 檢查遊戲檔案是否存在（existed flag）→ 儲存 → 回應 Game added/updated
5. 寫入為 Perl Dumper 格式，使用暫存檔 + os.Rename 原子操作
```

### deletegame

```
1. 組合 info/remoteaddr : port → gameAddr
2. 連續 . 合併為一個 .（regex: \.{2,}）
3. 安全檢查 → 刪除 → 回應 Game deleted 或 Game not found
```

### postdemo

```
1. 取得 score 參數，必須為純數字
2. 寫入為 Perl Dumper 格式至 scores/<score>
3. 呼叫 doGetHighScores() 回傳最新排行榜
```

### gethighscores

```
1. 讀取 scores/ 目錄下所有純數字檔名
2. 依分數降冪排序
3. num 參數控制回傳筆數（預設 5）
4. 輸出：Ok\n → high000/key value → high001/key value → ...
5. 觸發 scores cleanup（移除 >100 筆的舊分數）
```

### getgames

```
1. 讀取 games/ 目錄下所有有效檔案
2. 依 key 排序，並依版本規則去重後輸出
3. 讀取時同步清理過期遊戲（超過 180 秒）
```

#### 去重規則

| 條件 | 去重 key |
|------|---------|
| `quadra_version == "1.1.2"` | `IP:PORT`（但移除 `players` 欄位） |
| 無 `quadra_version` 且無 `qsnoop_version` | Host only（無 port） |
| 其他 | `IP:PORT` |

---

## 五、資料格式

### 儲存位置

```
<datadir>/
  games/
    <IP_PORT>       ← Perl Data::Dumper
  scores/
    <SCORE>         ← Perl Data::Dumper（檔名即分數值）
```

> Windows 上 `:` 在檔名中非法 → 自動轉換為 `_`，輸出時還原。

### Perl Data::Dumper 格式範例

```perl
$VAR1 = {
  'info' => {
    'remoteaddr' => '127.0.0.1',
    'lastupdate' => 1234567890,
    'name' => 'MyGame'
  },
  'port' => '27910',
  'players' => '2'
};
```

### 序列化實作

| 函式 | 說明 |
|------|------|
| `SaveAsPerlDumper(destPath, data)` | 寫入暫存檔 → `os.Rename` 原子移動 |
| `LoadPerlDumper(filePath, &dest)` | 狀態機轉換單引號為雙引號 → 去尾逗號 → `json.Unmarshal` |

**已知限制**：`LoadPerlDumper` 不支援值內嵌單引號（如 `O'Connor`），生產環境舊資料若含此類值需升級 parser。

---

## 六、清理機制

### Registry 模式

```go
cleanupRegistry["games"] = cleanupGames
cleanupRegistry["scores"] = cleanupScores
```

- 每個請求結束後，遍歷 registry 執行所有 cleanup 函式
- `getgames` 執行後刪除 `"games"` 登錄（避免重複清理）
- `gethighscores` / `postdemo` 執行後刪除 `"scores"` 登錄
- 若命令未觸發上述兩者，則在回應送出後執行所有剩餘 cleanup

### 遊戲過期

- 超過 180 秒未更新 → 刪除（以檔案 `ModTime` 判斷）

### 分數清理

- 保留分數最高 100 筆 → 其餘刪除

---

## 七、組態

### 命令列參數（優先）

```
--datadir <path>    資料目錄路徑
--port <port>       監聽端口（預設 3456）
--debug <0|1>       除錯模式
```

### 環境變數（備用）

```
QUADRA_DATADIR    資料目錄（優先級低於 --datadir）
DEBUG             設為任意值啟用 debug（若 --debug=0）
```

### 預設值

| 平台 | datadir |
|------|---------|
| Windows | `C:\quadra\data` |
| Linux | `/home/groups/q/qu/quadra/data` |

---

## 八、跨平台處理

| 項目 | 實作方式 |
|------|----------|
| 路徑建構 | 統一 `filepath.Join()` |
| Windows `:` 檔名 | `sanitizeGameAddr()` → `_`，輸出時 `unsanitizeGameAddr()` 還原 |
| IPv6 `[::1]` | `tweak()` 去除括號 |
| 暫存檔命名 | `qserv_<pid>_<rand>.tmp`（避免同名碰撞） |
| 行尾 | 讀寫統一 `\n` |

---

## 九、實作歷程（已解決的 Bug）

| # | 問題 | 修正 |
|---|------|------|
| 1 | POST body 內換行被 form parser 分割 | 換行 URL 編碼為 `%0A` |
| 2 | 雙層暫存檔同名碰撞（SaveAsPerlDumper + doPostGame 都用 os.Getpid()） | 暫存檔加入亂數後綴 |
| 3 | Windows 檔名不允許 `:` | `sanitizeGameAddr` / `unsanitizeGameAddr` |
| 4 | IPv6 loopback `[::1]` 觸發 safeRegex 拒絕 | `tweak` 去除括號 |
| 5 | Perl Dumper 單引號 JSON 無法解析 | 狀態機轉雙引號 |
| 6 | Perl Dumper 尾逗號 JSON 非法 | `removeTrailingCommas` |
| 7 | Game added/updated 判斷時機錯誤 | 改為寫入**前**檢查（與 Perl `-e` 一致） |
| 8 | PowerShell 單引號不解析 `` `n `` | 測試資料改用雙引號字串 |
| 9 | build_qserv.ps1 here-string 巢狀雙引號解析失敗 | 改用陣列 `-join` 組合 |

---

## 十、測試

```powershell
.\test.ps1
```

涵蓋 9 項測試（使用獨立 port 34560 與暫存資料目錄）：

| # | 測試 | 驗證點 |
|---|------|--------|
| 1 | 未知命令 | 預設歡迎訊息 |
| 2 | postgame 新遊戲 | `Game added` |
| 3 | postgame 更新 | `Game updated` |
| 4 | getgames | `Current games` |
| 5 | postdemo | `Ok`（含排行榜） |
| 6 | postdemo 第二筆 | `Ok` |
| 7 | gethighscores | `high000` |
| 8 | deletegame 存在 | `Game deleted` |
| 9 | deletegame 不存在 | `Game not found` |
