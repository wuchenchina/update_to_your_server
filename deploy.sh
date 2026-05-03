#!/bin/bash
set -Eeuo pipefail

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
# 預設使用 SSH 金鑰登入；如需密碼登入，請將 AUTH_METHOD 改為 "password"
# Default to SSH key login. Set AUTH_METHOD to "password" if password login is required.
AUTH_METHOD="key"

# 方式 A：SSH 金鑰登入 / Method A: SSH Key Login
# 留空時使用 SSH 預設金鑰或 ssh-agent；也可填寫指定金鑰絕對路徑。
# Leave empty to use default SSH identities or ssh-agent, or set an absolute key path.
SERVER_SSH_KEY=""

# 方式 B：密碼登入 (需確保系統已安裝 sshpass) / Method B: Password Login (requires sshpass installed)
SERVER_PASSWORD=""

# -----------------
# 3. 目標與來源設定 / Target and Source Settings
# -----------------
# 您在伺服器上的目標絕對路徑 / Absolute target path on the server (e.g., /var/www/html/your_project/)
REMOTE_DIR="YOUR_REMOTE_DIR"

# 您想要上傳覆蓋的檔案或資料夾 (支援通配符) / Files or folders to upload and overwrite (e.g., dist/* or src/*)
# 若路徑包含空格，請使用引號，例如：TARGET_FILES=("dist folder/" "config/app.json")
TARGET_FILES=(YOUR_TARGET_FILES)

# 是否在上傳前清空遠端目錄 / Whether to clear remote directory before upload
# 預設關閉，避免 rsync 失敗時留下空目錄。需要完全覆蓋時改為 true。
FULL_OVERWRITE_REMOTE_DIR=false

# =========================================================
# 以下為執行區塊，一般無需修改 / Execution Block, usually no modification needed
# =========================================================
fail() {
    echo -e "\n\033[31m❌ Error: $*\033[0m\n" >&2
    exit 1
}

validate_config() {
    [[ -n "$SERVER_USER" ]] || fail "SERVER_USER is empty."
    [[ -n "$SERVER_IP" && "$SERVER_IP" != "YOUR_SERVER_IP" ]] || fail "SERVER_IP is not configured."
    [[ "$SERVER_PORT" =~ ^[0-9]+$ ]] || fail "SERVER_PORT must be a number."
    [[ -n "$REMOTE_DIR" && "$REMOTE_DIR" != "YOUR_REMOTE_DIR" ]] || fail "REMOTE_DIR is not configured."
    [[ "$REMOTE_DIR" == /* ]] || fail "REMOTE_DIR must be an absolute path."
    [[ "$REMOTE_DIR" != "/" ]] || fail "REMOTE_DIR cannot be '/'."
    [[ "$REMOTE_DIR" != "/root" && "$REMOTE_DIR" != "/home" && "$REMOTE_DIR" != "/var" && "$REMOTE_DIR" != "/usr" ]] || \
        fail "REMOTE_DIR points to a high-risk system directory: $REMOTE_DIR"
    [[ "$AUTH_METHOD" == "key" || "$AUTH_METHOD" == "password" ]] || fail "AUTH_METHOD must be 'key' or 'password'."
    [[ "$FULL_OVERWRITE_REMOTE_DIR" == true || "$FULL_OVERWRITE_REMOTE_DIR" == false ]] || \
        fail "FULL_OVERWRITE_REMOTE_DIR must be true or false."
    [[ ${#TARGET_FILES[@]} -gt 0 && "${TARGET_FILES[0]}" != "YOUR_TARGET_FILES" ]] || fail "TARGET_FILES is not configured."

    if [[ "$AUTH_METHOD" == "key" ]]; then
        if [[ -n "$SERVER_SSH_KEY" ]]; then
            [[ -f "$SERVER_SSH_KEY" ]] || fail "SSH key not found: $SERVER_SSH_KEY"
        fi
    else
        [[ -n "$SERVER_PASSWORD" ]] || fail "SERVER_PASSWORD is empty while AUTH_METHOD is 'password'."
    fi
}

check_local_dependencies() {
    local required_commands=(bash ssh rsync basename printf)

    if [[ "$AUTH_METHOD" == "password" ]]; then
        required_commands+=(sshpass)
    fi

    echo -e "\033[36m🔍 Checking local dependencies...\033[0m"
    for cmd in "${required_commands[@]}"; do
        command -v "$cmd" > /dev/null || fail "Local dependency missing: $cmd"
    done
}

check_remote_dependencies() {
    local remote_commands=(rsync mkdir)

    if [[ "$FULL_OVERWRITE_REMOTE_DIR" == true ]]; then
        remote_commands+=(find rm)
    fi

    echo -e "\033[36m🔍 Checking remote dependencies...\033[0m"
    local check_script="for cmd in ${remote_commands[*]}; do command -v \"\$cmd\" > /dev/null || { echo \"Missing remote dependency: \$cmd\" >&2; exit 127; }; done"
    if ! "${SSH_CMD[@]}" "${SERVER_USER}@${SERVER_IP}" "$check_script"; then
        fail "Remote dependency check failed. Please install missing software and verify SSH connectivity.
Debian/Ubuntu: apt-get install rsync coreutils findutils
CentOS/RHEL: yum install rsync coreutils findutils"
    fi
}

validate_config
check_local_dependencies

echo -e "\n\033[34m===== 🚀 Start Deployment & Sync =====\033[0m"
echo -e "\033[33mTarget Server:\033[0m ${SERVER_USER}@${SERVER_IP}:${SERVER_PORT}"
echo -e "\033[33mTarget Path:\033[0m ${REMOTE_DIR}"
echo -e "\033[33mAuth Method:\033[0m ${AUTH_METHOD}"
echo -e "\033[33mFull Overwrite:\033[0m ${FULL_OVERWRITE_REMOTE_DIR}"
echo -e "------------------------------------"

# 過濾不需要上傳的檔案 / Filter files that don't need to be uploaded
FINAL_FILES=()
for file in "${TARGET_FILES[@]}"; do
    [[ "$file" != "YOUR_TARGET_FILES" ]] || fail "TARGET_FILES is not configured."

    if [[ "$(basename "$file")" != "deploy.sh" ]]; then
        FINAL_FILES+=("$file")
    fi
done

[[ ${#FINAL_FILES[@]} -gt 0 ]] || fail "TARGET_FILES is empty after filtering deploy.sh."

# 初始化 SSH 執行命令與 rsync 使用的 ssh / Initialize SSH command and ssh for rsync
SSH_CMD=(ssh -p "$SERVER_PORT")
RSYNC_SSH_CMD=(ssh -p "$SERVER_PORT")

# 檢查認證方式 / Check authentication method
if [[ "$AUTH_METHOD" == "password" ]]; then
    if ! command -v sshpass &> /dev/null; then
        fail "Password login is set, but 'sshpass' is not installed.
macOS Install: brew install hudochenkov/sshpass/sshpass
Linux Install: apt-get install sshpass or yum install sshpass"
    fi
    export SSHPASS="$SERVER_PASSWORD"
    SSH_CMD=(sshpass -e ssh -p "$SERVER_PORT")
    RSYNC_SSH_CMD=(sshpass -e ssh -p "$SERVER_PORT")
else
    if [[ -n "$SERVER_SSH_KEY" ]]; then
        SSH_CMD+=(-i "$SERVER_SSH_KEY")
        RSYNC_SSH_CMD+=(-i "$SERVER_SSH_KEY")
    fi
fi

# 檢查遠端伺服器是否安裝必要軟體 / Check required remote software
check_remote_dependencies

# 可選：清空遠端目錄 / Optional: clear original contents in remote directory
if [[ "$FULL_OVERWRITE_REMOTE_DIR" == true ]]; then
    echo -e "\033[36m🗑️  Clearing original contents in remote directory...\033[0m"
    REMOTE_DIR_QUOTED=$(printf '%q' "$REMOTE_DIR")
    if ! "${SSH_CMD[@]}" "${SERVER_USER}@${SERVER_IP}" \
        "mkdir -p -- ${REMOTE_DIR_QUOTED} && find ${REMOTE_DIR_QUOTED} -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +"; then
        fail "Failed to clear remote directory. Please check connection info and directory permissions."
    fi
else
    echo -e "\033[36m📁 Ensuring remote directory exists...\033[0m"
    REMOTE_DIR_QUOTED=$(printf '%q' "$REMOTE_DIR")
    if ! "${SSH_CMD[@]}" "${SERVER_USER}@${SERVER_IP}" "mkdir -p -- ${REMOTE_DIR_QUOTED}"; then
        fail "Failed to create remote directory. Please check connection info and directory permissions."
    fi
fi

# 執行 rsync 傳輸 / Execute rsync transmission
echo -e "\033[36m📦 Uploading new files...\033[0m"
RSYNC_SSH_COMMAND=$(printf '%q ' "${RSYNC_SSH_CMD[@]}")
if ! rsync -avz -e "$RSYNC_SSH_COMMAND" "${FINAL_FILES[@]}" "${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/"; then
    fail "Deployment failed. Please check connection config, password/key correctness, or server firewall."
fi

# 判斷執行結果 / Check execution result
echo -e "\n\033[32m✅ Deployment successful! All files synced to ${SERVER_IP}.\033[0m\n"

