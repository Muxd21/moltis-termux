#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - PROOT-LIGHT VERSION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: Enabling Proot-Light Shims${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies (Added proot)
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api coreutils nodejs proot || true

# 1. Setup Virtual File System (The "Fake Root")
echo "Building Virtual File System..."
VROOT="$HOME/.moltis-vroot"
mkdir -p "$VROOT/lib"
mkdir -p "$VROOT/usr/bin"

# Link the Android Linker to the Musl path VS Code expects
ln -sf /system/bin/linker64 "$VROOT/lib/ld-musl-aarch64.so.1"
# Link local C++ libraries to the standard names
ln -sf "$PREFIX/lib/libc++.so" "$VROOT/lib/libstdc++.so.6"
# Create a dummy ldconfig
echo '#!/usr/bin/env bash' > "$VROOT/usr/bin/ldconfig"
echo 'exit 0' >> "$VROOT/usr/bin/ldconfig"
chmod +x "$VROOT/usr/bin/ldconfig"

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

# Helper: The SSH Patcher
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

# Launch Tunnel with Proot-Light Mapping
VROOT="\$HOME/.moltis-vroot"
nohup proot -b "\$VROOT/lib:/lib" -b "\$VROOT/usr/bin/ldconfig:/usr/bin/ldconfig" code tunnel > /dev/null 2>&1 &

echo -e "${GREEN}Moltis Gateway starting...${NC}"
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: Tunnel Starter (The authorized way)
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
VROOT="\$HOME/.moltis-vroot"
echo -e "${CYAN}Starting VS Code Tunnel with Virtual Mapping...${NC}"
proot -b "\$VROOT/lib:/lib" -b "\$VROOT/usr/bin/ldconfig:/usr/bin/ldconfig" code tunnel
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: Global Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Updated with Proot-Light!${NC}"
echo "--------------------------------------------------------"
echo -e "Run: ${GREEN}moltis-tunnel${NC}"
echo "--------------------------------------------------------"
