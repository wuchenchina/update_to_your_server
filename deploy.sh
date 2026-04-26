#!/bin/bash
# =========================================================
#  快速部署與同步腳本 / Quick Deployment & Sync Script
# =========================================================

# -----------------
# 1. 伺服器連線資訊 / Server Connection Info
# -----------------
SERVER_USER="root"
SERVER_IP="YOUR_SERVER_IP"  # 替換為您的伺服器 IP / Replace with your server IP (e.g., 192.168.1.1)
SERVER_PORT="22"

# -----------------
# 2. 認證方式設定 (擇一使用) / Authentication Method (Choose one)
# -----------------
# 方式 A：密碼登入 (需確保系統已安裝 sshpass) / Method A: Password Login (requires sshpass installed)
SERVER_PASSWORD=""

# 方式 B：SSH 金鑰登入 (請填寫金鑰絕對路徑，如 "~/.ssh/id_rsa") / Method B: SSH Key Login (absolute path, e.g., "~/.ssh/id_rsa")
# 若 SERVER_PASSWORD 有值，則優先使用密碼登入 / If SERVER_PASSWORD is set, password login takes priority
SERVER_SSH_KEY=""
# -----------------
# 3. 目標與來源設定 / Target and Source Settings
# -----------------
# 您在伺服器上的目標絕對路徑 / Absolute target path on the server (e.g., /var/www/html/your_project/)
REMOTE_DIR="YOUR_REMOTE_DIR"

# 您想要上傳覆蓋的檔案或資料夾 (以空格分隔，支援通配符) / Files or folders to upload and overwrite (e.g., dist/* or src/*)
TARGET_FILES="YOUR_TARGET_FILES"

# =========================================================
# 以下為執行區塊，一般無需修改 / Execution Block, usually no modification needed
# =========================================================
echo -e "\n\033[34m===== 🚀 Start Deployment & Sync =====\033[0m"
echo -e "\033[33mTarget Server:\033[0m ${SERVER_USER}@${SERVER_IP}:${SERVER_PORT}"
echo -e "\033[33mTarget Path:\033[0m ${REMOTE_DIR}"
echo -e "------------------------------------"

# 過濾不需要上傳的檔案 / Filter files that don't need to be uploaded
FINAL_FILES=()
for file in $TARGET_FILES; do
    if [ "$file" != "deploy.sh" ]; then
        FINAL_FILES+=("$file")
    fi
done

# 初始化 SSH 執行命令與 rsync 使用的 ssh / Initialize SSH command and ssh for rsync
SSH_CMD="ssh"
RSYNC_SSH_CMD="ssh"

# 檢查是否使用密碼登入 / Check if password login is used
if [ -n "$SERVER_PASSWORD" ]; then
    if ! command -v sshpass &> /dev/null; then
        echo -e "\n\033[31m❌ Error: Password login is set, but 'sshpass' is not installed.\033[0m"
        echo -e "macOS Install: brew install hudochenkov/sshpass/sshpass"
        echo -e "Linux Install: apt-get install sshpass or yum install sshpass\n"
        exit 1
    fi
    # 若安裝了 sshpass，將指令前綴加上密碼傳遞 / If sshpass is installed, add password prefix to commands
    SSH_CMD="sshpass -p ${SERVER_PASSWORD} ssh"
    RSYNC_SSH_CMD="sshpass -p ${SERVER_PASSWORD} ssh"
fi

# 組裝 SSH 連線參數 / Assemble SSH connection parameters
SSH_OPTS="-p ${SERVER_PORT}"
# 若未設定密碼且有提供金鑰路徑，則使用金鑰登入 / Use key login if password is not set and key path is provided
if [ -z "$SERVER_PASSWORD" ] && [ -n "$SERVER_SSH_KEY" ]; then
    SSH_OPTS="${SSH_OPTS} -i ${SERVER_SSH_KEY}"
fi

# 檢查遠端伺服器是否安裝必要軟體 (如 rsync) / Check if necessary software (like rsync) is installed on the remote server
echo -e "\033[36m🔍 Checking remote server dependencies...\033[0m"
${SSH_CMD} ${SSH_OPTS} "${SERVER_USER}@${SERVER_IP}" "command -v rsync > /dev/null"
if [ $? -ne 0 ]; then
    echo -e "\n\033[31m❌ Error: 'rsync' is not installed on the remote server. Please install it first.\033[0m"
    echo -e "Debian/Ubuntu: apt-get install rsync"
    echo -e "CentOS/RHEL: yum install rsync\n"
    exit 1
fi

# 清空遠端目錄 / Clear original contents in remote directory
echo -e "\033[36m🗑️  Clearing original contents in remote directory...\033[0m"
${SSH_CMD} ${SSH_OPTS} "${SERVER_USER}@${SERVER_IP}" "mkdir -p ${REMOTE_DIR} && rm -rf ${REMOTE_DIR:?}/*"
if [ $? -ne 0 ]; then
    echo -e "\n\033[31m❌ Failed to clear remote directory. Please check connection info and directory permissions.\033[0m\n"
    exit 1
fi

# 執行 rsync 傳輸 / Execute rsync transmission
echo -e "\033[36m📦 Uploading new files...\033[0m"
rsync -avz -e "${RSYNC_SSH_CMD} ${SSH_OPTS}" "${FINAL_FILES[@]}" "${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/"

# 判斷執行結果 / Check execution result
if [ $? -eq 0 ]; then
    echo -e "\n\033[32m✅ Deployment successful! All files synced to ${SERVER_IP}.\033[0m\n"
else
    echo -e "\n\033[31m❌ Deployment failed. Please check connection config, password/key correctness, or server firewall.\033[0m\n"
fi

