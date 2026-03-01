#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - PRIVATE VPS EDITION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis Android: Private VPS Mode${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl ca-certificates binutils termux-api coreutils nodejs which python python-pip libxml2 libxslt clang make pkg-config libiconv mosh caddy gitea || true

if [ ! -f "$PREFIX/bin/ldd" ]; then
    cat <<'EOF' > "$PREFIX/bin/ldd"
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
    echo "ldd (unknown) 2.28"
    exit 0
fi
echo "libc.so.6 => /system/lib64/libc.so (0x0000000000000000)"
EOF
    chmod +x "$PREFIX/bin/ldd"
fi

# Bionic Compatibility
mkdir -p ~/.openclaw-android/patches/
touch ~/.openclaw-android/patches/bionic-compat.js

# 2. Grab the latest Termux build of Moltis (Bionic v2 Branch)
echo "Fetching latest Moltis Bionic build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux. Falling back to nightly. ${NC}"
    exit 1
fi

echo -e "Downloading Moltis AI + Bionic PTY Shim..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/bin"
chmod +x "$PREFIX/bin/moltis" "$PREFIX/bin/mosh"* "$PREFIX/bin/entr" "$PREFIX/bin/socat" "$PREFIX/bin/sslh" 2>/dev/null || true
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# 3. Deploy Professional VPS Dashboard & Configs
echo "Deploying Workstation configs..."
mkdir -p ~/.config/moltis ~/www/docs ~/forgejo-data/repositories
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/app.ini" -o ~/.config/moltis/app.ini
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/Caddyfile" -o ~/.config/moltis/Caddyfile
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/dashboard.html" -o ~/www/docs/index.html

# Patch the config with the real Termux username
sed -i "s/__TERMUX_USER__/$(whoami)/" ~/.config/moltis/app.ini

# Helper: The Node Healer (Essential for VS Code Remote)
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
for BASE_DIR in "\$HOME/.vscode-server/bin" "\$HOME/.antigravity-server/bin"; do
    if [ -d "\$BASE_DIR" ]; then
        echo "Healing Server for Android Bionic (\$BASE_DIR)..."
        for dir in "\$BASE_DIR"/*; do
            if [ -d "\$dir/bin" ] && [ -f "\$dir/node" ] && [ ! -L "\$dir/node" ]; then
                mv "\$dir/node" "\$dir/node.broken"
                ln -sf "\$PREFIX/bin/node" "\$dir/node"
            fi
        done
    fi
done
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# Symlink native Gitea to Forgejo command
if [ -f "$PREFIX/bin/gitea" ] && [ ! -f "$PREFIX/bin/forgejo" ]; then
    ln -sf "$PREFIX/bin/gitea" "$PREFIX/bin/forgejo"
fi

# ────────────────────────────────────────────────────────
# Helper: Moltis Control (Service Manager)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-stop"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
echo -e "${CYAN}Stopping all Workstation services...${NC}"
pkill -f "forgejo web" 2>/dev/null || true
pkill -f "gitea web" 2>/dev/null || true
caddy stop 2>/dev/null || true
pkill -f "sslh-fork" 2>/dev/null || true
pkill -f "moltis$" 2>/dev/null || true
rm -rf ~/forgejo-data/queues/ 2>/dev/null || true
sleep 1
echo -e "${GREEN}All services stopped.${NC}"
EOF
chmod +x "$PREFIX/bin/moltis-stop"

# ────────────────────────────────────────────────────────
# Helper: Moltis-Up (Production Simple Mode)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
# 1. Start core services
moltis-stop
sshd 2>/dev/null || true
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"

# 2. Forgejo & Caddy (Dashboard)
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
forgejo web -c ~/.config/moltis/app.ini >/dev/null 2>&1 &
caddy start --config ~/.config/moltis/Caddyfile >/dev/null 2>&1 &

IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1)

clear
echo -e "\033[0;32mMoltis Bionic Edition is Online! 🚀\033[0m"
echo -e "IP: $IP"
echo -e "Workstation Dashboard: http://$IP:3002"
echo -e "Moltis AI Gateway:    https://$IP:46697"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# ────────────────────────────────────────────────────────
# Pro Mode with Stealth Sslh Multiplexer
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-dev"
#!/usr/bin/env bash
moltis-up & 
sleep 3
echo -e "\033[0;36mActivating Professional Stealth Mux (Port 4433)... \033[0m"
sslh-fork --user $(whoami) --listen 0.0.0.0:4433 --ssh 127.0.0.1:8022 --http 127.0.0.1:3001 --pidfile /tmp/sslh.pid 2>/dev/null || true
echo -e "Stealth Mux Access (SSH + HTTP): $IP:4433"
wait
EOF
chmod +x "$PREFIX/bin/moltis-dev"

echo -e "\n${GREEN}Setup Complete! Bionic Workstation is ready.${NC}"
echo "--------------------------------------------------------"
echo -e "  ${CYAN}moltis-up${NC}     Run AI + Git + Dashboard"
echo -e "  ${CYAN}moltis-dev${NC}    Pro Mode (Stealth Mux + Mosh)"
echo -e "  ${CYAN}moltis-stop${NC}   Kill all services"
echo "--------------------------------------------------------"

