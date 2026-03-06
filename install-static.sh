#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Moltis Termux Installer${NC}"
echo "================================"

if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}Error: Run this in Termux${NC}"
    echo "Get Termux: https://termux.dev/"
    exit 1
fi

echo -e "${YELLOW}Fetching latest release...${NC}"
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')

if [ "$LATEST" = "null" ] || [ -z "$LATEST" ]; then
    echo -e "${RED}Error: Could not fetch latest release${NC}"
    exit 1
fi

VERSION="${LATEST#v}"
echo "Latest moltis version: ${VERSION}"

DOWNLOAD_URL="https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-termux/moltis-${VERSION}-musl-arm64.tar.gz"
echo -e "${YELLOW}Downloading...${NC}"

if ! curl -sL "$DOWNLOAD_URL" -o "moltis-${VERSION}-musl-arm64.tar.gz"; then
    echo -e "${RED}Error: Download failed${NC}"
    echo "Check: https://github.com/Muxd21/moltisdroid/releases"
    exit 1
fi

echo -e "${YELLOW}Installing...${NC}"
tar -xzf "moltis-${VERSION}-musl-arm64.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis "$PREFIX/bin/moltis"
rm -rf moltis-termux "moltis-${VERSION}-musl-arm64.tar.gz"

if command -v moltis &> /dev/null; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Run 'moltis --help' to get started"
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "Ensure \$PREFIX/bin is in PATH"
    exit 1
fi
