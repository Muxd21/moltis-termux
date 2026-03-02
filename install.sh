#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - TRUE VPS EDITION
# Powered by Native Bionic + termux-exec + termux-services

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis Android: True VPS Mode${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Warnings about Android Quirks
echo -e "${RED}⚠️  IMPORTANT BIONIC VPS QUIRKS ⚠️${NC}"
echo -e "1. ${CYAN}Phantom Process Killer:${NC} Android 12+ aggressively kills background apps."
echo -e "   Run this from your PC via ADB to fix:"
echo -e "   ${GREEN}adb shell \"settings put global phantom_process_handling false\"${NC}"
echo -e "2. ${CYAN}Battery Optimization:${NC} You MUST set Termux to 'Unrestricted' in Android settings."
echo -e "3. ${CYAN}Paths:${NC} We install termux-exec so standard #!/bin/bash scripts work."
echo -e "-------------------------------------------------------\n"

sleep 3

# Install core dependencies including critical termux VPS tools
echo "Installing Core Dependencies..."
pkg update -y
pkg install -y termux-exec termux-services curl wget tar openssl ca-certificates binutils termux-api coreutils nodejs which python python-pip libxml2 libxslt clang make pkg-config libiconv mosh caddy gitea runit || true

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

# Grab the latest Termux build of Moltis (Bionic Branch)
echo "Fetching latest Moltis Bionic build..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release executable from Muxd21/moltis-termux. Falling back...${NC}"
    # Add a fallback or exit
    exit 1
fi

echo -e "Downloading Moltis AI + Pro Tools..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/bin"
chmod +x "$PREFIX/bin/moltis" "$PREFIX/bin/mosh"* "$PREFIX/bin/entr" "$PREFIX/bin/socat" "$PREFIX/bin/sslh" 2>/dev/null || true
rm -f "$PREFIX/tmp/moltis-termux.tar.gz"

# Deploy VPS Dashboard & Configs
echo "Deploying Workstation configs..."
mkdir -p ~/.config/moltis ~/www/docs ~/forgejo-data/repositories
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/app.ini" -o ~/.config/moltis/app.ini
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/Caddyfile" -o ~/.config/moltis/Caddyfile
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/docs/index.html" -o ~/www/docs/index.html

# Patch the config with the real Termux username
sed -i "s/__TERMUX_USER__/$(whoami)/" ~/.config/moltis/app.ini

# Fix Gitea to Forgejo symlink
if [ -f "$PREFIX/bin/gitea" ] && [ ! -f "$PREFIX/bin/forgejo" ]; then
    ln -sf "$PREFIX/bin/gitea" "$PREFIX/bin/forgejo"
fi

# ────────────────────────────────────────────────────────
# Helper: The Node Healer (Termux-Exec + PTY fixes)
# ────────────────────────────────────────────────────────
# Since we now use termux-exec natively, we reduce the hacks.
cat <<EOF > "$PREFIX/bin/moltis-fix-vscode"
#!/usr/bin/env bash
if ! npm ls -g node-pty >/dev/null 2>&1; then
    echo "Installing global node-pty for Termux Bionic compatibility..."
    npm install -g node-pty
fi
GLOBAL_PTY=\$(npm root -g)/node-pty/build/Release/pty.node

for BASE_DIR in "\$HOME/.vscode-server/bin" "\$HOME/.antigravity-server/bin"; do
    if [ -d "\$BASE_DIR" ]; then
        echo "Healing Server for Android Bionic (\$BASE_DIR)..."
        for dir in "\$BASE_DIR"/*; do
            if [ -d "\$dir/bin" ] && [ -e "\$dir/node" ]; then
                PTY_DIR="\$dir/node_modules/node-pty/build/Release"
                if [ -d "\$PTY_DIR" ]; then
                    if [ -f "\$GLOBAL_PTY" ]; then
                        if [ ! -f "\$PTY_DIR/pty.node.broken" ]; then
                            echo "Patching node-pty.node for Termux Bionic..."
                            mv "\$PTY_DIR/pty.node" "\$PTY_DIR/pty.node.broken"
                            cp "\$GLOBAL_PTY" "\$PTY_DIR/pty.node"
                        fi
                    fi
                fi
            fi
        done
    fi
done
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"

# ────────────────────────────────────────────────────────
# TERMUX-SERVICES (runit) CONFIGURATION
# ────────────────────────────────────────────────────────
echo -e "${CYAN}Configuring termux-services (runit) for bulletproof backgrounding...${NC}"

# Enable boot service for termux-services
mkdir -p ~/.termux/boot/
cat <<'EOF' > ~/.termux/boot/start-services
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd
EOF
chmod +x ~/.termux/boot/start-services

# Service logs directory
mkdir -p "$PREFIX/var/log/moltis"
mkdir -p "$PREFIX/var/log/forgejo"
mkdir -p "$PREFIX/var/log/caddy"
mkdir -p "$PREFIX/var/log/sslh"

# 1. Moltis AI Service
mkdir -p "$PREFIX/var/service/moltis/log"
cat <<'EOF' > "$PREFIX/var/service/moltis/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export SHELL="$PREFIX/bin/bash"
export USER="$(whoami)"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
exec 2>&1
exec moltis
EOF
cat <<'EOF' > "$PREFIX/var/service/moltis/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/moltis
EOF
chmod +x "$PREFIX/var/service/moltis/run" "$PREFIX/var/service/moltis/log/run"

# 2. Forgejo Service
mkdir -p "$PREFIX/var/service/forgejo/log"
cat <<'EOF' > "$PREFIX/var/service/forgejo/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
exec 2>&1
exec forgejo web -c $HOME/.config/moltis/app.ini
EOF
cat <<'EOF' > "$PREFIX/var/service/forgejo/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/forgejo
EOF
chmod +x "$PREFIX/var/service/forgejo/run" "$PREFIX/var/service/forgejo/log/run"

# 3. Caddy Service
mkdir -p "$PREFIX/var/service/caddy/log"
cat <<'EOF' > "$PREFIX/var/service/caddy/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
exec 2>&1
exec caddy run --config $HOME/.config/moltis/Caddyfile
EOF
cat <<'EOF' > "$PREFIX/var/service/caddy/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/caddy
EOF
chmod +x "$PREFIX/var/service/caddy/run" "$PREFIX/var/service/caddy/log/run"

# 4. SSLH (Pro Mux) Service
mkdir -p "$PREFIX/var/service/sslh/log"
cat <<'EOF' > "$PREFIX/var/service/sslh/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
exec 2>&1
exec sslh-fork --foreground --user u0_a123 --listen 0.0.0.0:4433 --ssh 127.0.0.1:8022 --http 127.0.0.1:3001
EOF
# The u0_a123 will be dynamically patched:
sed -i "s/u0_a123/$(whoami)/" "$PREFIX/var/service/sslh/run"
cat <<'EOF' > "$PREFIX/var/service/sslh/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/sslh
EOF
chmod +x "$PREFIX/var/service/sslh/run" "$PREFIX/var/service/sslh/log/run"


# ────────────────────────────────────────────────────────
# Helper: Moltis-Up (Production Service Launcher)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
termux-wake-lock
sshd 2>/dev/null || true
moltis-fix-vscode > /dev/null 2>&1

echo -e "\033[0;36mStarting Bionic VPS Services via runit...\033[0m"
sv up moltis
sv up forgejo
sv up caddy

IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1)

clear
echo -e "\033[0;32mMoltis Bionic VPS is Online! 🚀\033[0m"
echo -e "Services are running in background natively."
echo -e ""
echo -e "IP: $IP"
echo -e "Workstation Dashboard: http://$IP:3002"
echo -e "Forgejo Git:          http://$IP:3001"
echo -e "Moltis AI Gateway:    https://$IP:46697"
echo ""
echo -e "Check logs: \033[0;36msvlogd -tt $PREFIX/var/log/<service>\033[0m"
echo -e "Stop all:   \033[0;36mmoltis-stop\033[0m"
EOF
chmod +x "$PREFIX/bin/moltis-up"

# ────────────────────────────────────────────────────────
# Helper: Moltis Control (Service Manager)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-stop"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
echo -e "${CYAN}Stopping all runit services...${NC}"
sv down moltis forgejo caddy sslh 2>/dev/null || true
pkill -f "sslh-fork" 2>/dev/null || true
rm -rf ~/forgejo-data/queues/ 2>/dev/null || true
sleep 1
echo -e "${GREEN}All services stopped.${NC}"
EOF
chmod +x "$PREFIX/bin/moltis-stop"

# ────────────────────────────────────────────────────────
# Pro Mode with Stealth Sslh Multiplexer
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-dev"
#!/usr/bin/env bash
moltis-up
sleep 2
echo -e "\033[0;36mActivating Professional Stealth Mux (Port 4433)... \033[0m"
sv up sslh
echo -e "Stealth Mux Access (SSH + HTTP): $IP:4433"
EOF
chmod +x "$PREFIX/bin/moltis-dev"

# ────────────────────────────────────────────────────────
# Helper: Moltis-Bot-Setup (Background Python/Node Bots natively)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-bot-setup"
#!/usr/bin/env bash
if [ -z "$1" ]; then
    echo -e "\033[0;31mUsage: moltis-bot-setup <bot-name> <path-to-script>\033[0m"
    echo -e "Example: moltis-bot-setup my_bot /data/data/com.termux/files/home/bot/run.sh"
    exit 1
fi
BOT_NAME=$1
BOT_SCRIPT=$(realpath "$2")

echo -e "\033[0;36mCreating runit service for $BOT_NAME...\033[0m"
mkdir -p "$PREFIX/var/service/$BOT_NAME/log"
mkdir -p "$PREFIX/var/log/$BOT_NAME"

cat <<RUN > "$PREFIX/var/service/$BOT_NAME/run"
#!/data/data/com.termux/files/usr/bin/sh
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
exec 2>&1
exec $BOT_SCRIPT
RUN

cat <<LOGNRUN > "$PREFIX/var/service/$BOT_NAME/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/$BOT_NAME
LOGNRUN

chmod +x "$PREFIX/var/service/$BOT_NAME/run" "$PREFIX/var/service/$BOT_NAME/log/run"
echo -e "\033[0;32mService created!\033[0m"
echo -e "Start it:   \033[0;36msv up $BOT_NAME\033[0m"
echo -e "Check logs: \033[0;36msvlogd -tt $PREFIX/var/log/$BOT_NAME\033[0m"
EOF
chmod +x "$PREFIX/bin/moltis-bot-setup"

# ────────────────────────────────────────────────────────
# Helper: Moltis-Update (Self Update & Node/VSCode Patch)
# ────────────────────────────────────────────────────────
cat <<'EOF' > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
echo -e "\033[0;36mUpdating Moltis Bionic Workstation...\033[0m"
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/install.sh" | bash
moltis-fix-vscode > /dev/null 2>&1
echo -e "\033[0;32mUpdate Complete! Please restart your services (moltis-stop && moltis-up).\033[0m"
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete! Native Bionic VPS is ready.${NC}"
echo "--------------------------------------------------------"
echo -e "  ${CYAN}moltis-up${NC}     Run AI + Git + Dashboard via runit"
echo -e "  ${CYAN}moltis-dev${NC}    Pro Mode (Stealth Mux + Mosh)"
echo -e "  ${CYAN}moltis-update${NC} Update configuration & Fix VS Code"
echo -e "  ${CYAN}moltis-stop${NC}   Kill all services"
echo -e "  ${CYAN}sv status <app>${NC} Check service status"
echo "--------------------------------------------------------"
