#!/bin/bash
set -e

# Moltis Termux Elite Installer
# Automatic deployment of Android Bionic AI Stack

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "    __  ___      ____  _      "
echo "   /  |/  /___  / / /_(_)____ "
echo "  / /|_/ / __ \/ / __/ / ___/ "
echo " / /  / / /_/ / / /_/ (__  )  "
echo "/_/  /_/\____/_/\__/_/____/   "
echo -e "      Termux Elite Stack${NC}"
echo "=============================="

# Check for Termux
if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}Error: Run this in Termux!${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing system dependencies...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y openssh jq curl tar procps -y

# Fetch latest release
echo -e "${YELLOW}Identifying latest Bionic payload...${NC}"
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"

# Download
DOWNLOAD_URL="https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-termux/moltis-${VERSION}-aarch64-linux-android.tar.gz"
echo -e "${YELLOW}Downloading: ${NC}$DOWNLOAD_URL"

if ! curl -sL "$DOWNLOAD_URL" -o "moltis-stack.tar.gz"; then
    echo -e "${RED}Download failed! Checking fallback...${NC}"
    exit 1
fi

# Extract
echo -e "${YELLOW}Deploying binary...${NC}"
tar -xzf "moltis-stack.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis "$PREFIX/bin/moltis"
rm -rf moltis-termux "moltis-stack.tar.gz"

# Create claw.sh (The Command Center)
echo -e "${YELLOW}Creating Command Center (claw.sh)...${NC}"
cat << 'EOF' > claw.sh
#!/bin/bash

# Claw-Mission Launcher
# Zero-overhead Android AI Stack Control

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}🚀 Launching Claw-Mission Stack...${NC}"

# 1. Network Detection
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not Connected")
LOCAL_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)

# 2. Start SSH Services
echo -e "${YELLOW}[1/3] Initializing Infrastructure...${NC}"
if ! pgrep sshd > /dev/null; then
    sshd -p 2222
    echo -e "      ${GREEN}✓ SSH Server active on port 2222${NC}"
else
    echo -e "      ${GREEN}✓ SSH Server already running${NC}"
fi

# 3. Start Moltis AI Stack
echo -e "${YELLOW}[2/3] Powering up AI Engines...${NC}"
if ! pgrep moltis > /dev/null; then
    # Start moltis in background, logging to ~/moltis.log
    # Port 18789 is the default gateway port
    # Port 3000 is the dashboard port
    nohup moltis serve --host 0.0.0.0 > ~/moltis.log 2>&1 &
    echo -e "      ${GREEN}✓ Moltis AI Federation online${NC}"
else
    echo -e "      ${GREEN}✓ Moltis AI already active${NC}"
fi

# 4. Finalizing Dashboard
echo -e "${YELLOW}[3/3] Syncing Matrix...${NC}"
sleep 2

echo -e "${CYAN}"
echo "------------------------------------------------"
echo "    CLAW-MISSION OPERATIONAL STATUS"
echo "------------------------------------------------"
echo -e "${NC}🌐 Tailscale IP: ${GREEN}$TAILSCALE_IP${NC}"
echo -e "${NC}🏠 Local IP:     ${GREEN}$LOCAL_IP${NC}"
echo ""
echo -e "🛸 ${CYAN}Mission Control:${NC}    http://${TAILSCALE_IP:-$LOCAL_IP}:3000"
echo -e "🦞 ${CYAN}OpenClaw Gateway:${NC}   http://${TAILSCALE_IP:-$LOCAL_IP}:18789"
echo -e "💻 ${CYAN}SSH Access:${NC}         ssh -p 2222 root@$TAILSCALE_IP"
echo ""
echo -e "${YELLOW}Stack Status: RUNNING${NC}"
echo "------------------------------------------------"
echo "Log: tail -f ~/moltis.log"
echo "Stop: pkill moltis"
EOF

chmod +x claw.sh

echo ""
echo -e "${GREEN}✓ Moltis Android Bionic Stack Installed!${NC}"
echo -e "Commands available:"
echo -e "  - ${CYAN}moltis --help${NC} (Direct CLI access)"
echo -e "  - ${CYAN}./claw.sh${NC}      (Start full stack with dash & SSH)"
echo ""
echo -e "${YELLOW}Try it now:${NC} ./claw.sh"
