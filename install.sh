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

# 2. Grab the latest Termux build of Moltis
echo "Fetching latest Moltis Termux build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux${NC}"
    exit 1
fi

echo -e "Downloading Moltis & VPS Tools..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
# Extract everything directly to $PREFIX/bin
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/bin"
chmod +x "$PREFIX/bin/moltis" "$PREFIX/bin/mosh"* "$PREFIX/bin/entr" "$PREFIX/bin/socat" "$PREFIX/bin/sslh" 2>/dev/null || true
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# 3. Setup Cloudflared (For Public Fallback Only)
if [ ! -f "$PREFIX/bin/cloudflared" ]; then
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" -o "$PREFIX/bin/cloudflared"
    chmod +x "$PREFIX/bin/cloudflared"
fi

# Helper: The Node Swapper (Required for VS Code Remote-SSH on Android)
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
for BASE_DIR in "\$HOME/.vscode-server/bin" "\$HOME/.antigravity-server/bin"; do
    if [ -d "\$BASE_DIR" ]; then
        echo "Healing Server for Android VPS Mode (\$BASE_DIR)..."
        for dir in "\$BASE_DIR"/*; do
            if [ -d "\$dir/bin" ] && [ -f "\$dir/node" ] && [ ! -L "\$dir/node" ]; then
                mv "\$dir/node" "\$dir/node.broken"
                ln -s "\$PREFIX/bin/node" "\$dir/node"
            fi
        done
    fi
done
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# 4. Fetch the VPS Configs (Caddy & Forgejo)
mkdir -p ~/.config/moltis
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/app.ini" -o ~/.config/moltis/app.ini
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/Caddyfile" -o ~/.config/moltis/Caddyfile

# Patch the config with the real Termux username (e.g. u0_a570)
sed -i "s/__TERMUX_USER__/$(whoami)/" ~/.config/moltis/app.ini

# Create required data directories
mkdir -p ~/forgejo-data/repositories
mkdir -p ~/www/docs
echo "<h1>Moltis Local Pages</h1><p>Deploy your docs here via Forgejo Actions.</p>" > ~/www/docs/index.html 2>/dev/null || true

# Symlink Termux's native Gitea to serve as our "Forgejo Bionic" until the NDK compile pipeline is ready
if [ -f "$PREFIX/bin/gitea" ] && [ ! -f "$PREFIX/bin/forgejo" ]; then
    ln -sf "$PREFIX/bin/gitea" "$PREFIX/bin/forgejo"
fi

# ────────────────────────────────────────────────────────
# Helper: Clean Stop (kills all Moltis-managed services)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-stop"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
echo -e "${CYAN}Stopping all Moltis services...${NC}"
pkill -f "forgejo web" 2>/dev/null || true
pkill -f "gitea web" 2>/dev/null || true
caddy stop 2>/dev/null || true
pkill -f "sslh-fork" 2>/dev/null || true
pkill -f "moltis$" 2>/dev/null || true
# Clean stale LevelDB locks from Forgejo
rm -rf ~/forgejo-data/queues/ 2>/dev/null || true
sleep 1
echo -e "${GREEN}All services stopped.${NC}"
EOF
chmod +x "$PREFIX/bin/moltis-stop"

# ────────────────────────────────────────────────────────
# Helper: The Simple Gateway (Tailscale Focused)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Clean shutdown of any lingering processes
moltis-stop

# 2. Core services
sshd 2>/dev/null || true
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

# 3. Start Caddy (Local Pages on :3002)
caddy start --config ~/.config/moltis/Caddyfile >/dev/null 2>&1 || true

# 4. Start Forgejo (Local Git on :3001)
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
forgejo web -c ~/.config/moltis/app.ini >/dev/null 2>&1 &
sleep 2

IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}  Moltis Simple Gateway is Online!${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${CYAN}  IP:${NC}                $IP"
echo -e "${CYAN}  SSH Access:${NC}        ssh -p 8022 termux@$IP"
echo -e "${CYAN}  Moltis AI:${NC}         https://$IP:46697"
echo -e "${CYAN}  Forgejo Git UI:${NC}    http://$IP:3001"
echo -e "${CYAN}  Caddy Docs UI:${NC}     http://$IP:3002"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${CYAN}  Stop all:${NC}          moltis-stop"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""

# 5. Start Moltis (foreground, takes over the terminal)
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# ────────────────────────────────────────────────────────
# Helper: The Professional Dev Mode (The Full Stack)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-dev"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Clean shutdown of any lingering processes
moltis-stop

# 2. Core services
sshd 2>/dev/null || true
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

# 3. Start Caddy (Local Pages on :3002)
caddy start --config ~/.config/moltis/Caddyfile >/dev/null 2>&1 || true

# 4. Start Forgejo (Local Git on :3001)
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
forgejo web -c ~/.config/moltis/app.ini >/dev/null 2>&1 &
sleep 2

# 5. Start SSLH Multiplexer (Forwarding 4433 to SSH/Forgejo)
sslh-fork --user $(whoami) --listen 0.0.0.0:4433 --ssh 127.0.0.1:8022 --http 127.0.0.1:3001 --pidfile /tmp/sslh.pid 2>/dev/null || true

IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}  Moltis PROFESSIONAL DEV MODE Online! 🚀${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${CYAN}  Stack:${NC} Mosh + Entr + Socat + Sslh + Forgejo + Caddy"
echo -e "${CYAN}  IP:${NC}                $IP"
echo -e "${CYAN}  SSH:${NC}               ssh -p 8022 termux@$IP"
echo -e "${CYAN}  Mosh:${NC}              mosh --ssh=\"ssh -p 8022\" termux@$IP"
echo -e "${CYAN}  Moltis AI:${NC}         https://$IP:46697"
echo -e "${CYAN}  Forgejo Git UI:${NC}    http://$IP:3001"
echo -e "${CYAN}  Caddy Docs UI:${NC}     http://$IP:3002"
echo -e "${CYAN}  Stealth Mux:${NC}       0.0.0.0:4433 (SSH + HTTP)"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${CYAN}  Watch logs:${NC}  ls ~/.moltis/*.log | entr tail -f"
echo -e "${CYAN}  Stop all:${NC}    moltis-stop"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""

# 6. Start Moltis (foreground, takes over the terminal)
moltis
EOF
chmod +x "$PREFIX/bin/moltis-dev"

# Helper: The Public Tunnel (Optional)
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting Anonymous Public Tunnel (Fallback)...${NC}"
cloudflared tunnel --url http://localhost:3001
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "  ${CYAN}moltis-up${NC}     Simple gateway mode"
echo -e "  ${CYAN}moltis-dev${NC}    Professional dev mode"
echo -e "  ${CYAN}moltis-stop${NC}   Stop all services"
echo -e "  ${CYAN}moltis-update${NC} Pull latest updates"
echo "--------------------------------------------------------"
