# 🚀 快速部署與同步腳本

*[Read this in English](README.md)*

這是一個用於快速將本地端專案檔案同步到遠端伺服器 (如 VPS、寶塔面板伺服器) 的 Bash 腳本。
它支援 **密碼登入** 與 **SSH 金鑰登入**，並使用 `rsync` 確保高效的差異化傳輸。

## 🌟 功能特色

- **雙語提示**：腳本內含中英文雙語註解與終端機輸出。
- **支援多種登入方式**：可使用 `sshpass` 進行密碼自動化登入，或透過 SSH Key 免密碼登入。
- **防呆與依賴檢查**：自動檢測本機端是否安裝了 `sshpass`，以及遠端伺服器是否安裝了 `rsync`。
- **高度客製化**：可自定義要上傳的目標路徑與檔案規則 (支援通配符)。

## 🛠️ 環境需求

### 本機端 (Local)
- 作業系統：macOS / Linux
- 依賴軟體：
  - `rsync` (通常系統已內建)
  - `sshpass` (**僅當您使用密碼登入時才需要**)
    - macOS: `brew install hudochenkov/sshpass/sshpass`
    - Linux: `apt-get install sshpass` 或 `yum install sshpass`

### 遠端伺服器 (Remote)
- 依賴軟體：`rsync` (腳本會自動檢查遠端是否已安裝，若無則會提示並中斷執行)。

## ⚙️ 腳本設定說明

打開 `deploy.sh`，在檔案最上方設定您的連線與路徑資訊：

1. **伺服器連線資訊**
   填寫 `SERVER_USER` (使用者名稱) 與 `SERVER_IP` (您的伺服器 IP)。

2. **認證方式設定**
   - **方式 A：密碼登入**：將密碼填入 `SERVER_PASSWORD`。
   - **方式 B：SSH 金鑰登入**：將 `SERVER_PASSWORD` 留空，並在 `SERVER_SSH_KEY` 填入您的金鑰路徑 (如 `~/.ssh/id_rsa`)。

3. **目標與來源設定**
   - `REMOTE_DIR`：遠端伺服器的目標絕對路徑 (例如您的網站目錄 `/var/www/html/your_project/`)。
   - `TARGET_FILES`：要上傳的本地檔案或資料夾 (如 `dist/*` 或 `build/*`)。

## 🚀 執行方法

請在終端機中進入該腳本所在的目錄，並賦予執行權限後執行：

```bash
chmod +x deploy.sh
./deploy.sh
```

## ⚠️ 注意事項

- 本腳本預設會先 **清空遠端目錄** (`rm -rf ${REMOTE_DIR}/*`) 再進行同步。若您不希望清空遠端檔案，請自行將腳本中的對應段落註解掉。
- 請避免將包含真實密碼或私鑰路徑的 `deploy.sh` 上傳至公開的 GitHub 倉庫中，建議加入 `.gitignore` 以防洩露。
