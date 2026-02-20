#!/usr/bin/env bash
# Moltis Installer for Android (Termux)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Preparing Moltis + VS Code environment for Termux...${NC}"

# Install core dependencies
# Adding patchelf and tur-repo for VS Code compatibility
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api patchelf

# 1. Setup VS Code Remote-SSH Shims (Native Fix)
echo -e "${GREEN}Setting up VS Code Remote-SSH Shims...${NC}"
# Create a fake ldd that VS Code expects
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

# 1. moltis-up
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
echo "Moltis & SSH Server are running!"
echo "Connect via VS Code at port 8022."
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# 2. moltis-update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

# 3. moltis-fix-vscode (The magic fix)
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
echo "Patching VS Code Server for Termux..."
BIN_DIR=\$HOME/.vscode-server/bin
if [ -d "\$BIN_DIR" ]; then
    for dir in "\$BIN_DIR"/*; do
        if [ -f "\$dir/node" ]; then
            echo "Patching node in \$dir"
            patchelf --set-interpreter /system/bin/linker64 "\$dir/node"
        fi
    done
    echo "VS Code Server patched successfully!"
else
    echo "VS Code Server directory not found yet. Try connecting once from PC first."
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "1. Run ${NC}moltis-up${NC}"
echo -e "2. Connect VS Code from your PC."
echo -e "3. If VS Code fails to start on the first try, run ${NC}moltis-fix-vscode${NC} in Termux and try again."
echo "--------------------------------------------------------"
