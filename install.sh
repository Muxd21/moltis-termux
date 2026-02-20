#!/usr/bin/env bash
# Moltis Installer for Android (Termux)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Preparing Moltis + VS Code environment for Termux...${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api patchelf

# 1. Setup VS Code Remote-SSH Shims
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

echo -e "Downloading binary..."
rm -f "$HOME/.local/bin/moltis"
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"

echo "Extracting binary..."
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# Create Moltis Helpers
echo -e "${GREEN}Updating helper commands...${NC}"

# 1. moltis-fix-vscode
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
BIN_DIR=\$HOME/.vscode-server/bin
if [ -d "\$BIN_DIR" ]; then
    echo "Patching VS Code Server binaries..."
    for dir in "\$BIN_DIR"/*; do
        if [ -f "\$dir/node" ]; then
            # Only patch if not already patched
            if ! patchelf --print-interpreter "\$dir/node" 2>/dev/null | grep -q "/system/bin/linker64"; then
                echo "Applying link fix to \$dir/node"
                patchelf --set-interpreter /system/bin/linker64 "\$dir/node"
            fi
        fi
    done
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# 2. moltis-up (The All-In-One command)
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
# Fire up SSH
sshd
# Prevent Android from killing the process
termux-wake-lock
# Auto-patch VS Code if someone tries to connect
moltis-fix-vscode
echo -e "${GREEN}Moltis Status:${NC} Online"
echo -e "${GREEN}SSH Status:${NC}    Online (Port 8022)"
echo ""
echo "Starting Gateway..."
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# 3. moltis-update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}One-Command Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "Simply run: ${GREEN}moltis-up${NC}"
echo "--------------------------------------------------------"
