#!/usr/bin/env bash
# Moltis Installer for Android (Termux)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Preparing Moltis for Termux...${NC}"

# Install deps
pkg update -y
pkg install -y curl tar openssl binutils termux-api

# Grab the latest termux release from GitHub API
echo "Fetching latest Moltis Termux build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux${NC}"
    echo "This means the GitHub Actions workflow hasn't finished building the release yet!"
    exit 1
fi

echo -e "Downloading binary from GitHub Releases:\n$DOWNLOAD_URL"
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"

echo "Extracting binary..."
# Cleanup common legacy paths to prevent "file not found" errors
rm -f "$HOME/.local/bin/moltis"

tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# Create Moltis Helpers
echo -e "${GREEN}Creating helper commands...${NC}"

# 1. moltis-up
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
echo "Starting Moltis Gateway..."
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# 2. moltis-update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Moltis successfully installed to $PREFIX/bin/moltis${NC}"
echo "-------------------------------------------------------"
echo -e "${GREEN}New commands available:${NC}"
echo -e "  ${NC}moltis-up${NC}      - Starts SSH, locks CPU, and launches Moltis"
echo -e "  ${NC}moltis-update${NC}  - Checks for and installs the latest Termux build"
echo "-------------------------------------------------------"
echo "Run 'moltis-up' to get started!"
