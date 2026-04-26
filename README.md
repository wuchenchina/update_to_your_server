# 🚀 Quick Deployment & Sync Script

*[Read this in 繁體中文](README_cn.md)*

This is a Bash script designed to quickly synchronize your local project files to a remote server (e.g., VPS, Baota Panel server).
It supports **Password Login** and **SSH Key Login**, utilizing `rsync` to ensure efficient differential file transfers.

## 🌟 Features

- **Bilingual Prompts**: Includes bilingual (English/Chinese) comments and terminal outputs within the script.
- **Multiple Login Methods**: Supports automated password login via `sshpass`, or passwordless login using SSH Keys.
- **Dependency Checks**: Automatically detects if `sshpass` is installed locally and if `rsync` is installed on the remote server.
- **Highly Customizable**: Easily customize the target paths and file patterns (supports wildcards) to upload.

## 🛠️ Requirements

### Local Machine
- OS: macOS / Linux
- Dependencies:
  - `rsync` (Usually pre-installed)
  - `sshpass` (**Only required if using password login**)
    - macOS: `brew install hudochenkov/sshpass/sshpass`
    - Linux: `apt-get install sshpass` or `yum install sshpass`

### Remote Server
- Dependencies: `rsync` (The script will automatically check if it's installed; if not, it will prompt you to install it and exit).

## ⚙️ Configuration

Open `deploy.sh` and set your connection and path information at the top of the file:

1. **Server Connection Info**
   Fill in `SERVER_USER` (username) and `SERVER_IP` (your server's IP address).

2. **Authentication Method**
   - **Method A: Password Login**: Fill your password in `SERVER_PASSWORD`.
   - **Method B: SSH Key Login**: Leave `SERVER_PASSWORD` empty and fill in your key path (e.g., `~/.ssh/id_rsa`) in `SERVER_SSH_KEY`.

3. **Target and Source Settings**
   - `REMOTE_DIR`: The absolute target path on the remote server (e.g., your website root `/var/www/html/your_project/`).
   - `TARGET_FILES`: The local files or folders to upload (e.g., `dist/*` or `build/*`).

## 🚀 Usage

Navigate to the directory containing the script in your terminal, grant execution permissions, and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

## ⚠️ Notes

- By default, this script will **clear the remote directory** (`rm -rf ${REMOTE_DIR}/*`) before synchronizing. If you do not want to delete the remote files, please comment out the corresponding section in the script manually.
- Avoid uploading `deploy.sh` containing real passwords or private key paths to public GitHub repositories. It is highly recommended to add it to your `.gitignore`.
