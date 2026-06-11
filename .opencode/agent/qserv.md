# QServ Go 重寫計畫 - V1 (相容模式)

## 目標
重寫 `qserv.pl` 為 Go 服務，保持完全行為相容，支援相同 API 與資料格式。

## 核心功能相容性

### 1. API 請求格式
- 接收 `POST /`，`data` 參數為 `\n` 分隔的命令與參數
- 支援命令：`postgame`, `deletegame`, `postdemo`, `gethighscores`, `getgames`
- 參數格式：`key value` 行，支援巢狀（如 `info/remoteaddr 192.168.1.1`）

### 2. 資料儲存
- **遊戲資料**：`/data/games/<IP:PORT>`，內容為 `Data::Dumper` 格式的序列化 Hash
- **分數資料**：`/data/scores/<SCORE>`，內容為 `Data::Dumper` 格式的序列化 Hash
- 所有檔案以純文字儲存，無二進位格式

### 3. 機制相容
- **遊戲過期**：超過 180 秒未更新的遊戲自動刪除
- **分數清理**：保留最多 100 筆最高分，舊分數自動刪除
- **清理機制**：`get_games` 和 `get_scores` 執行後觸發清理（非同步）

### 4. 響應格式
- 所有回應為 `text/plain`
- `gethighscores`：先輸出 `Ok\n`，再輸出 `highXXX` 開頭的參數
- `getgames`：輸出 `Current games\n`，再輸出遊戲參數（去重邏輯相同）
- 錯誤回應：`Game not found`、`Bad data` 等原字串

## 非功能性要求
- 端口預設：`3456`
- 檔案路徑：`/home/groups/q/qu/quadra/data`（可透過環境變數覆寫）
- 記錄日誌：支援 `DEBUG=1` 環境變數輸出詳細訊息
- 安全檢查：所有使用者輸入必須正規化（`/^[-@\w.:]+$/`）

## 待實現的相容性測試
- 模擬原始 Perl 腳本的請求，驗證輸出完全一致
- 驗證 `Dumper` 序列化格式完全相同（包括空格、換行、引用）
- 確認多執行緒下檔案寫入不衝突（使用 `rename` 原子操作）

## 下一步
- 建立 Go 應用，實作 HTTP handler 與資料處理邏輯
- 寫入測試用例，比對與 Perl 輸出的逐行差異
