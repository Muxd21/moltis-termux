#!/bin/bash
set -e

# Moltis Termux Elite Installer (Android Bionic Edition)
# One-liner to rule them all.

# High-def colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GOLD='\033[38;5;220m'
NC='\033[0m'

clear
echo -e "${PURPLE}   __  __  ____  _      _______ _____  _____ ${NC}"
echo -e "${PURPLE}  |  \/  |/ __ \| |    |__   __|_   _|/ ____|${NC}"
echo -e "${PURPLE}  | \  / | |  | | |       | |    | | | (___  ${NC}"
echo -e "${PURPLE}  | |\/| | |  | | |       | |    | |  \___ \ ${NC}"
echo -e "${PURPLE}  | |  | | |__| | |____   | |   _| |_ ____) |${NC}"
echo -e "${PURPLE}  |_|  |_|\____/|______|  |_|  |_____|_____/ ${NC}"
echo -e "         ${GOLD}Android Native Powerhouse${NC}"
echo "================================================="

# 1. Environment Validation
if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}Error: This stack requires Termux!${NC}"
    exit 1
fi

# 2. Dependency Injection
echo -e "${CYAN}🛰️  Deploying system infrastructure...${NC}"
pkg update -y && pkg upgrade -y --o "Dpkg::Options::=--force-confold"
pkg install -y openssh jq curl tar procps iproute2 -y

# 3. Payload Acquisition
echo -e "${CYAN}🔍 Scanning for latest Bionic payload...${NC}"
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"

DOWNLOAD_URL="https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-android/moltis-${VERSION}-aarch64-linux-android.tar.gz"

echo -e "${CYAN}📥 Downloading:${NC} ${WHITE}moltis-v${VERSION}-android-bionic${NC}"
if ! curl -sL "$DOWNLOAD_URL" -o "moltis-stack.tar.gz"; then
    echo -e "${RED}❌ Download failed! Build might still be in progress.${NC}"
    echo "Check status at: https://github.com/Muxd21/moltisdroid/actions"
    exit 1
fi

# 4. Binary Extraction
echo -e "${CYAN}⚡ Hardening binary...${NC}"
tar -xzf "moltis-stack.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis "$PREFIX/bin/moltis"
rm -rf moltis-termux "moltis-stack.tar.gz"

# 5. The Command Center (claw.sh)
echo -e "${CYAN}🛸 Generating Command Center (claw.sh)...${NC}"
cat << 'EOF' > claw.sh
#!/bin/bash

# Claw-Mission Launcher v2.0
# Zero-overhead Android AI Stack Control

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
GOLD='\033[38;5;220m'
NC='\033[0m'

clear
echo -e "${PURPLE}🚀 CLAW-MISSION | MOLTIS ANDROID STACK${NC}"
echo -e "${WHITE}----------------------------------------${NC}"

# Detect IPs
TS_IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
LOCAL_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)

# Start SSH (Port 2222)
if ! pgrep sshd > /dev/null; then
    echo -e "${YELLOW}[INFRA] Starting SSH Environment...${NC}"
    sshd -p 2222
fi

# Start Moltis (0.0.0.0)
if ! pgrep moltis > /dev/null; then
    echo -e "${YELLOW}[AI] Starting Moltis Federation...${NC}"
    # Standard ports: 3000 (UI), 18789 (API)
    nohup moltis serve --host 0.0.0.0 > ~/moltis.log 2>&1 &
    sleep 3
fi

echo -e "\n${GOLD}✨ ALL SYSTEMS OPERATIONAL${NC}"
echo -e "${WHITE}----------------------------------------${NC}"

printf "${CYAN}%-20s${NC} %s\n" "🛰️ Tailscale IP:" "${GOLD}$TS_IP${NC}"
printf "${CYAN}%-20s${NC} %s\n" "🏠 Local IP:" "$LOCAL_IP"
printf "${CYAN}%-20s${NC} %s\n" "🛸 Dashboard:" "http://${TS_IP:-$LOCAL_IP}:3000"
printf "${CYAN}%-20s${NC} %s\n" "🦞 Gateway API:" "http://${TS_IP:-$LOCAL_IP}:18789"
printf "${CYAN}%-20s${NC} %s\n" "💻 Terminal access:" "ssh -p 2222 root@$TS_IP"
echo -e "${WHITE}----------------------------------------${NC}"
echo -e "${WHITE}SSH Password: ${GOLD}root${NC}"
echo -e "${WHITE}Log Viewer:   ${CYAN}tail -f ~/moltis.log${NC}"
EOF

chmod +x claw.sh

echo -e "\n${GOLD}✅ DEPLOYMENT COMPLETE!${NC}"
echo -e "The ${WHITE}Moltis Android Bionic${NC} engine is now installed."
echo -e "You can now start everything with one command:"
echo -e "\n    ${CYAN}./claw.sh${NC}\n"
echo -e "Your visual command center is ready at:"
echo -e "${PURPLE}https://Muxd21.github.io/moltisdroid/${NC}"
