#!/bin/bash
set -e

# Moltis Termux One-Liner Installer
# Downloads and installs the latest musl binary for Termux

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Moltis Termux Installer${NC}"
echo "========================"

# Check if running in Termux
if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}Error: This script should be run in Termux${NC}"
    echo "Install Termux from: https://termux.dev/"
    exit 1
fi

# Get the latest release tag from moltis-org/moltis
echo -e "${YELLOW}Fetching latest release...${NC}"
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')

if [ "$LATEST" = "null" ] || [ -z "$LATEST" ]; then
    echo -e "${RED}Error: Could not fetch latest release${NC}"
    exit 1
fi

VERSION="${LATEST#v}"
echo "Latest moltis version: ${VERSION}"

# Download the musl binary
DOWNLOAD_URL="https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-termux/moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
echo -e "${YELLOW}Downloading from: $DOWNLOAD_URL${NC}"

if ! curl -sL "$DOWNLOAD_URL" -o "moltis-${VERSION}-musl.tar.gz"; then
    echo -e "${RED}Error: Download failed${NC}"
    echo "Make sure the release exists at: https://github.com/Muxd21/moltisdroid/releases"
    exit 1
fi

# Extract and install
echo -e "${YELLOW}Extracting...${NC}"
tar -xzf "moltis-${VERSION}-musl.tar.gz"

echo -e "${YELLOW}Installing to $PREFIX/bin/moltis${NC}"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis "$PREFIX/bin/moltis"

# Cleanup
rm -rf moltis-termux "moltis-${VERSION}-musl.tar.gz"

# Verify installation
if command -v moltis &> /dev/null; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Run 'moltis --help' to get started"
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "Make sure $PREFIX/bin is in your PATH"
    exit 1
fi
