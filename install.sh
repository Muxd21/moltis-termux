#!/usr/bin/env bash
# Moltis Installer for Android (Termux)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Preparing Moltis + VS Code environment for Termux...${NC}"

# Install core dependencies and VS Code remote-ssh headers
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api

# Grab the latest termux release from GitHub API
echo "Fetching latest Moltis Termux build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux${NC}"
    exit 1
fi

echo -e "Downloading binary..."
rm -f "$HOME/.local/bin/moltis" # Cleanup old paths
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"

echo "Extracting binary..."
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# Apply VS Code Remote-SSH Fix for Termux
echo "Injecting VS Code Remote compatibility..."
if [ ! -f "$PREFIX/bin/ldd" ]; then
    ln -s "$PREFIX/bin/pkg-config" "$PREFIX/bin/ldd" || true
fi

# Create Moltis Helpers
echo -e "${GREEN}Updating helper commands...${NC}"

# 1. moltis-up
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
echo "Moltis & SSH Server are running!"
echo "You can now connect via VS Code at port 8022."
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# 2. moltis-update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "-------------------------------------------------------"
echo "Run 'moltis-up' then try connecting your VS Code again."
echo "-------------------------------------------------------"
