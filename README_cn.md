# 🚀 快速部署與同步腳本

![快速部署與同步腳本橫幅](nav.png)

*[Read this in English](README.md)*

這是一個用於快速將本地端專案檔案同步到遠端伺服器 (如 VPS、寶塔面板伺服器) 的 Bash 腳本。
它使用 `rsync` 確保高效的差異化傳輸，預設採用 **SSH 金鑰登入**，並保留密碼登入支援。

## 🌟 功能特色

- **雙語提示**：腳本內含中英文雙語註解與終端機輸出。
- **支援多種登入方式**：預設使用 SSH Key，也可使用 `sshpass` 進行密碼自動化登入。
- **防呆與依賴檢查**：部署前會檢查本機端與遠端伺服器所需命令。
- **可選完整覆蓋**：預設不清空遠端目錄，需要時可明確開啟。
- **更可靠的失敗處理**：設定檢查、依賴檢查、SSH 或 `rsync` 失敗時會以非零狀態結束。
- **高度客製化**：可自定義要上傳的目標路徑與檔案規則。

## 🛠️ 環境需求

### 本機端 (Local)
- 作業系統：macOS / Linux
- 依賴軟體：
  - `bash`
  - `ssh`
  - `rsync`
  - `sshpass` (**僅當您使用密碼登入時才需要**)
    - macOS: `brew install hudochenkov/sshpass/sshpass`
    - Linux: `apt-get install sshpass` 或 `yum install sshpass`

### 遠端伺服器 (Remote)
- 必要依賴：
  - `rsync`
  - `mkdir`
- 當 `FULL_OVERWRITE_REMOTE_DIR=true` 時額外需要：
  - `find`
  - `rm`

腳本會自動檢查這些依賴。若缺少必要命令，會提示安裝方式並中斷執行。

## ⚙️ 腳本設定說明

打開 `deploy.sh`，在檔案最上方設定您的連線與路徑資訊：

1. **伺服器連線資訊**
   填寫 `SERVER_USER`、`SERVER_IP` 與 `SERVER_PORT`。

2. **認證方式設定**
   - **SSH 金鑰登入 (預設)**：保持 `AUTH_METHOD="key"`。`SERVER_SSH_KEY` 留空時會使用 SSH 預設身份或 `ssh-agent`；也可以填寫指定金鑰的絕對路徑。
   - **密碼登入**：設定 `AUTH_METHOD="password"` 並填寫 `SERVER_PASSWORD`。此模式需要安裝 `sshpass`。

3. **目標與來源設定**
   - `REMOTE_DIR`：遠端伺服器的目標絕對路徑 (例如您的網站目錄 `/var/www/html/your_project/`)。
   - `TARGET_FILES`：要上傳的本地檔案或資料夾。此設定是 Bash 陣列，例如：

```bash
TARGET_FILES=(dist/* public/ "config/app.json")
```

4. **遠端清理設定**
   - `FULL_OVERWRITE_REMOTE_DIR=false` 為預設值。腳本會在需要時建立遠端目錄，但不會刪除既有檔案。
   - 只有當您希望上傳前先清空遠端目錄時，才將 `FULL_OVERWRITE_REMOTE_DIR` 設為 `true`。

## 🚀 執行方法

請在終端機中進入該腳本所在的目錄，並賦予執行權限後執行：

```bash
chmod +x deploy.sh
./deploy.sh
```

## ⚠️ 注意事項

- 本腳本預設 **不會清空遠端目錄**。完整覆蓋需要透過 `FULL_OVERWRITE_REMOTE_DIR=true` 明確開啟。
- `REMOTE_DIR` 必須是絕對路徑，且不能是 `/`，也不能是 `/root`、`/home`、`/var`、`/usr` 等高風險系統目錄。
- 密碼登入仍受支援，但日常部署建議使用 SSH 金鑰。
- 請避免將包含真實密碼或私鑰路徑的 `deploy.sh` 上傳至公開的 GitHub 倉庫中，建議加入 `.gitignore` 以防洩露。
