#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - FINAL GHOST SHIM VERSION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: The Final Frontier Fix${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api coreutils nodejs libc++ || true

# 1. Setup Environment Shims
echo "Creating GHOST shims..."
# Dummy ldconfig (VS Code checks for this)
if [ ! -f "$PREFIX/bin/ldconfig" ]; then
    echo '#!/usr/bin/env bash' > "$PREFIX/bin/ldconfig"
    echo 'exit 0' >> "$PREFIX/bin/ldconfig"
    chmod +x "$PREFIX/bin/ldconfig"
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

# 3. Setup VS Code CLI
echo "Installing VS Code CLI..."
curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64" -o "$PREFIX/tmp/vscode_cli.tar.gz"
tar -xzf "$PREFIX/tmp/vscode_cli.tar.gz" -C "$PREFIX/bin"
rm "$PREFIX/tmp/vscode_cli.tar.gz"

# Create Moltis Helpers
echo -e "${GREEN}Updating helper commands...${NC}"

# Helper: The SSH Patcher (unchanged)
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
BIN_DIR=\$HOME/.vscode-server/bin
if [ -d "\$BIN_DIR" ]; then
    for dir in "\$BIN_DIR"/*; do
        if [ -d "\$dir/bin" ] && [ -f "\$dir/node" ] && [ ! -L "\$dir/node" ]; then
            mv "\$dir/node" "\$dir/node.broken"
            ln -s "\$PREFIX/bin/node" "\$dir/node"
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
# Start tunnel silently with the prerequisite-skip flag
DONT_PROMPT_WSL_INSTALL=true VSCODE_SKIP_PREREQUISITES=1 nohup code tunnel > /dev/null 2>&1 &
echo -e "${GREEN}Moltis Gateway starting...${NC}"
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: Tunnel Starter with Environment Overrides
# This uses the hidden flags that VS Code devs use to bypass checks
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting VS Code Tunnel (Prerequisite Bypass Mode)...${NC}"
export VSCODE_SKIP_PREREQUISITES=1
export DONT_PROMPT_WSL_INSTALL=true
code tunnel
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: Global Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Updated!${NC}"
echo "--------------------------------------------------------"
echo -e "Try: ${GREEN}moltis-tunnel${NC}"
echo "--------------------------------------------------------"
