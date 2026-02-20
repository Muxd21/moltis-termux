#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - GOAT TUNNEL VERSION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: The 'GOAT' Tunnel Setup${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api coreutils nodejs

# 1. Setup VS Code Remote-SSH Shims (Still useful as fallback)
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
rm -f "$HOME/.local/bin/moltis"
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"

echo "Extracting binary..."
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# 3. Setup VS Code CLI (The GOAT Tunnel Method)
echo -e "Setting up VS Code Remote Tunnel (Alpine/Musl)..."
if [ ! -f "$PREFIX/bin/code" ]; then
    curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64" -o "$PREFIX/tmp/vscode_cli.tar.gz"
    tar -xzf "$PREFIX/tmp/vscode_cli.tar.gz" -C "$PREFIX/bin"
    rm "$PREFIX/tmp/vscode_cli.tar.gz"
    echo -e "${GREEN}VS Code CLI installed.${NC}"
fi

# Create Moltis Helpers
echo -e "${GREEN}Updating helper commands...${NC}"

# Helper: Tunnel Starter
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting VS Code Tunnel...${NC}"
echo "1. Follow the link below to login (GitHub or Microsoft)."
echo "2. Once logged in, this phone will appear in your PC's VS Code."
code tunnel
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: Patcher
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
BIN_DIR=\$HOME/.vscode-server/bin
if [ -d "\$BIN_DIR" ]; then
    echo "Swapping VS Code Node with Native Termux Node..."
    for dir in "\$BIN_DIR"/*; do
        if [ -f "\$dir/node" ] && [ ! -L "\$dir/node" ]; then
            mv "\$dir/node" "\$dir/node.broken"
            ln -s "\$PREFIX/bin/node" "\$dir/node"
            echo "Fixed: \$dir"
        fi
    done
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# Helper: All-In-One Up
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1
echo -e "${GREEN}Moltis Status:${NC} Online"
echo -e "${CYAN}Goated Method:${NC} Run 'moltis-tunnel' in a new tab"
echo "Starting Gateway..."
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}One-Command Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "PRIMARY METHOD (RECOMMENDED):"
echo -e "  1. Run ${NC}moltis-tunnel${NC} and login."
echo -e "  2. Connect from any browser or VS Code on PC."
echo ""
echo -e "FALLBACK METHOD (SSH):"
echo -e "  1. Run ${NC}moltis-up${NC}"
echo "--------------------------------------------------------"
