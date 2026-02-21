#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - OPENTUNNEL / CLOUDFLARE VERSION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: The OpenTunnel (Cloudflare) Setup${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl binutils termux-api coreutils nodejs || true

# 1. Grab the latest Termux build of Moltis
echo "Fetching latest Moltis Termux build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux${NC}"
    exit 1
fi

echo -e "Downloading Moltis binary..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# 2. Install Cloudflared (The OpenTunnel Engine)
echo "Installing Cloudflared (Native aarch64)..."
if [ ! -f "$PREFIX/bin/cloudflared" ]; then
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" -o "$PREFIX/bin/cloudflared"
    chmod +x "$PREFIX/bin/cloudflared"
fi

# Helper: The Universal Tunnel Command
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting OpenTunnel (Powered by Cloudflare)...${NC}"
echo -e "This will expose your Moltis Web UI to the internet safely."
cloudflared tunnel --url http://localhost:3000
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: The God Command (Updated)
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
termux-wake-lock
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis Gateway starting...${NC}"
echo -e "${GREEN}SSH Local:${NC} Online (Port 8022)"
echo -e "${CYAN}Web Tunnel:${NC} Run 'moltis-tunnel' to get a public URL"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: The SSH Tunnel (For VS Code Remote-SSH)
cat <<EOF > "$PREFIX/bin/moltis-ssh-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting Public SSH Tunnel...${NC}"
echo -e "Use this URL in your PC's SSH config to connect via VSCodium/OpenTunnel."
cloudflared tunnel --url tcp://localhost:8022
EOF
chmod +x "$PREFIX/bin/moltis-ssh-tunnel"

# Helper: Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete (The Open Way)!${NC}"
echo "--------------------------------------------------------"
echo -e "1. ${NC}moltis-up${NC}           (Starts Gateway)"
echo -e "2. ${NC}moltis-tunnel${NC}       (Exposes Web UI Dashboard)"
echo -e "3. ${NC}moltis-ssh-tunnel${NC}   (Exposes SSH for VS Code Desktop)"
echo "--------------------------------------------------------"
