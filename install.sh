#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - POWERFUL TWO-COMMAND VERSION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: The Ultimate AI Workstation${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
# We ignore errors on non-essential packages for ChromeOS compatibility
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api coreutils nodejs || true

# 1. Setup VS Code Remote-SSH Shims (The Ghost Library)
if [ ! -f "$PREFIX/bin/ldd" ]; then
    echo '#!/usr/bin/env bash' > "$PREFIX/bin/ldd"
    echo 'echo "libc.so.6 => /system/lib64/libc.so (0x0000000000000000)"' >> "$PREFIX/bin/ldd"
    chmod +x "$PREFIX/bin/ldd"
fi

# 2. Grab the latest Termux build of Moltis
echo "Fetching latest Moltis Termux build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux${NC}"
    exit 1
fi

echo -e "Downloading Moltis binary..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"

echo "Extracting binary..."
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# 3. Setup VS Code CLI (The GOAT Tunnel)
if [ ! -f "$PREFIX/bin/code" ]; then
    echo "Installing VS Code CLI (Standalone)..."
    curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64" -o "$PREFIX/tmp/vscode_cli.tar.gz"
    tar -xzf "$PREFIX/tmp/vscode_cli.tar.gz" -C "$PREFIX/bin"
    rm "$PREFIX/tmp/vscode_cli.tar.gz"
fi

# Helper: The Ultimate Maintenance Tool
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
# 1. Fix SSH Server Binaries (PIE Bypass)
BIN_DIR=\$HOME/.vscode-server/bin
if [ -d "\$BIN_DIR" ]; then
    for dir in "\$BIN_DIR"/*; do
        if [ -d "\$dir/bin" ] && [ -f "\$dir/node" ] && [ ! -L "\$dir/node" ]; then
            mv "\$dir/node" "\$dir/node.broken"
            ln -s "\$PREFIX/bin/node" "\$dir/node"
        fi
    done
fi
# 2. Fix Local CLI (If needed)
if [ -f "\$PREFIX/bin/code" ]; then
    chmod +x "\$PREFIX/bin/code"
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# Helper: The GOD Command
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis Gateway is starting...${NC}"
echo -e "${GREEN}SSH Fallback:${NC} Online (Port 8022)"

# Start Tunnel in the background (Silent)
# It will use previous login. If first time, user should run 'code tunnel'
nohup code tunnel > /dev/null 2>&1 &
echo -e "${GREEN}VS Code Tunnel:${NC} Online (Check Remote Explorer on PC)"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: The Tunnel Initializer (Only for first-time login)
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}First-time Tunnel Setup...${NC}"
code tunnel
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: The Global Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "THE ONLY TWO COMMANDS YOU NEED:"
echo -e "  1. ${NC}moltis-up${NC}      (Starts EVERYTHING)"
echo -e "  2. ${NC}moltis-update${NC}  (Updates EVERYTHING)"
echo "--------------------------------------------------------"
echo -e "${CYAN}Note: First time only, run 'moltis-tunnel' to authorize VS Code.${NC}"
