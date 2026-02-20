#!/usr/bin/env bash
# Moltis Installer for Android (Termux)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Preparing Moltis for Termux...${NC}"

# Install deps
pkg update -y
pkg install -y curl tar openssl binutils

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
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

echo -e "\n${GREEN}Moltis successfully installed to $PREFIX/bin/moltis${NC}"
echo "Run 'moltis' to start it!"
