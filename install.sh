#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Moltis Installer for Android (Termux) — GLIBC HYBRID EDITION
# Harnessing native Termux Glibc-packages for pure compatibility
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Moltis Antigravity: Glibc Hybrid Workstation${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}
banner

# ────────────────────────────────────────────────────────
# PHASE 0: Android Quirks Warning
# ────────────────────────────────────────────────────────
echo -e "\n${RED}${BOLD}⚠️  CRITICAL ANDROID PREREQUISITES ⚠️${NC}"
echo -e "1. ${CYAN}Phantom Process Killer:${NC} Android 12+ destroys background apps."
echo -e "   Run from your PC via ADB:"
echo -e "   ${GREEN}adb shell \"settings put global phantom_process_handling false\"${NC}"
echo -e "2. ${CYAN}Battery Optimization:${NC} Set Termux to 'Unrestricted'."
echo -e "───────────────────────────────────────────────────────────\n"

sleep 3

# ────────────────────────────────────────────────────────
# PHASE 1: Install Glibc-Repo and Core Dependencies
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[1/7] Installing Glibc Repo & Core Tools...${NC}"

# Add Glibc Repository (the crucial step)
pkg update -y
pkg install -y glibc-repo

# Install glibc-runner and core Termux utilities
pkg install -y \
    glibc-runner \
    termux-exec termux-services termux-api \
    curl wget tar openssl ca-certificates binutils \
    coreutils inotify-tools openssh mosh tmux \
    caddy gitea runit

echo -e "  ${GREEN}✓ Core dependencies & Glibc-runner installed${NC}"

# ────────────────────────────────────────────────────────
# PHASE 2: Fetch Latest Moltis Build
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[2/7] Fetching Moltis Toolkit...${NC}"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${ORANGE}Release not found, preserving existing binaries if present...${NC}"
else
    echo -e "  Downloading Moltis..."
    curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
    tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/bin"
    chmod +x "$PREFIX/bin/moltis" "$PREFIX/bin/mosh"* "$PREFIX/bin/entr" "$PREFIX/bin/socat" "$PREFIX/bin/sslh" 2>/dev/null || true
    rm -f "$PREFIX/tmp/moltis-termux.tar.gz"
    echo -e "  ${GREEN}✓ Toolkit extracted${NC}"
fi

# ────────────────────────────────────────────────────────
# PHASE 3: Deploy Dashboard & Configs
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[3/7] Deploying Services Configuration...${NC}"
mkdir -p ~/.config/moltis ~/www/docs ~/forgejo-data/repositories

curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/app.ini" -o ~/.config/moltis/app.ini
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/Caddyfile" -o ~/.config/moltis/Caddyfile
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/docs/index.html" -o ~/www/docs/index.html

# Inject active Termux username
sed -i "s/__TERMUX_USER__/$(whoami)/" ~/.config/moltis/app.ini

# Gitea to Forgejo alias
if [ -f "$PREFIX/bin/gitea" ] && [ ! -f "$PREFIX/bin/forgejo" ]; then
    ln -sf "$PREFIX/bin/gitea" "$PREFIX/bin/forgejo"
fi

echo -e "  ${GREEN}✓ Configuration templates deployed${NC}"

# ────────────────────────────────────────────────────────
# PHASE 4: Hardened SSH Setup
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[4/7] Securing SSH Configurations...${NC}"

mkdir -p "$PREFIX/etc/ssh"
cat <<'SSHD_CONF' > "$PREFIX/etc/ssh/sshd_config"
Port 8022
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 10
AllowTcpForwarding yes
GatewayPorts yes
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
Compression yes
Subsystem sftp /data/data/com.termux/files/usr/libexec/sftp-server
PermitTTY yes
PermitUserEnvironment yes
AcceptEnv TERM COLORTERM LANG
SSHD_CONF

# Host keys
[ ! -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" ] && ssh-keygen -t ed25519 -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" -N "" -q
[ ! -f "$PREFIX/etc/ssh/ssh_host_rsa_key" ] && ssh-keygen -t rsa -b 4096 -f "$PREFIX/etc/ssh/ssh_host_rsa_key" -N "" -q

# Environment for non-interactive shells
mkdir -p "$HOME/.ssh"
cat <<'SSH_ENV' > "$HOME/.ssh/environment"
PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin
TMPDIR=/data/data/com.termux/files/usr/tmp
PREFIX=/data/data/com.termux/files/usr
SSH_ENV
chmod 600 "$HOME/.ssh/environment"

echo -e "  ${GREEN}✓ SSH secured (KeepAlive, Tunnels) on Port 8022${NC}"

# ────────────────────────────────────────────────────────
# PHASE 5: VS Code Glibc-Runner Patcher
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[5/7] Installing Glibc VS Code Patcher...${NC}"

cat <<'EOF' > "$PREFIX/bin/moltis-fix-vscode"
#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════
# Moltis Antigravity — VS Code Glibc Auto-Patcher
# ═══════════════════════════════════════════════════════
set -euo pipefail

PREFIX="/data/data/com.termux/files/usr"
WATCH=0
FORCE=0
QUIET=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --quiet) QUIET=1 ;;
        --watch) WATCH=1 ;;
    esac
done

log() { [ "$QUIET" -eq 0 ] && echo -e "$@"; }

patch_server_dirs() {
    for BASE_DIR in "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"; do
        [ -d "$BASE_DIR" ] || continue
        for dir in "$BASE_DIR"/*; do
            [ -d "$dir" ] || continue

            NODE_BIN="$dir/node"
            [ -e "$NODE_BIN" ] || [ -e "$dir/node.orig" ] || continue

            if [ "$FORCE" -eq 1 ] || ! head -5 "$NODE_BIN" 2>/dev/null | grep -q 'grun'; then
                COMMIT_ID=$(basename "$dir")
                log "\n🔧 Attaching Glibc-runner to VS Code [${COMMIT_ID:0:8}...]..."

                # Backup shipped glibc node
                if [ -e "$NODE_BIN" ] && [ ! -f "$dir/node.orig" ]; then
                    mv "$NODE_BIN" "$dir/node.orig"
                fi
                rm -f "$NODE_BIN"

                # Glibc runner wrapper
                cat <<'WRAPPER' > "$NODE_BIN"
#!/data/data/com.termux/files/usr/bin/bash
# Automatically generated Moltis Glibc wrapper
PREFIX="/data/data/com.termux/files/usr"

# Prevent termux-exec hooks from interfering with glibc
unset LD_PRELOAD

export SHELL="$PREFIX/bin/bash"
export TERM="xterm-256color"
export COLORTERM="truecolor"

# Execute the shipped node using Termux glibc-runner
exec grun "$0.orig" "$@"
WRAPPER
                chmod +x "$NODE_BIN"
                log "  ✓ Glibc Wrapper activated! Node and PTYs will work natively."
            fi
        done
    done
}

patch_server_dirs

if [ "$WATCH" -eq 1 ]; then
    log "🔭 Watchdog mode: Monitoring for new connections..."
    mkdir -p "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"
    while true; do
        inotifywait -q -e create,moved_to \
            "$HOME/.vscode-server/bin" \
            "$HOME/.antigravity-server/bin" 2>/dev/null || true
        sleep 2
        FORCE=0 QUIET=0 patch_server_dirs
    done
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"
echo -e "  ${GREEN}✓ Glibc auto-patcher configured${NC}"

# ────────────────────────────────────────────────────────
# PHASE 6: Runit Services Infrastructure
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[6/7] Establishing Background Services...${NC}"

# Boot hook
mkdir -p ~/.termux/boot/
cat <<'EOF' > ~/.termux/boot/start-services
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd
sv up vscode-patcher moltis caddy forgejo sslh
EOF
chmod +x ~/.termux/boot/start-services

# Service logs dirs
for s in moltis forgejo caddy sslh vscode-patcher; do
    mkdir -p "$PREFIX/var/log/$s" "$PREFIX/var/service/$s/log"
done

# Service 1: Moltis AI
cat <<'EOF' > "$PREFIX/var/service/moltis/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
exec 2>&1
exec nice -n -5 ionice -c 2 -n 0 moltis
EOF

# Service 2: Forgejo
cat <<'EOF' > "$PREFIX/var/service/forgejo/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
exec 2>&1
exec nice -n -5 ionice -c 2 -n 0 forgejo web -c $HOME/.config/moltis/app.ini
EOF

# Service 3: Caddy
cat <<'EOF' > "$PREFIX/var/service/caddy/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
exec 2>&1
exec nice -n -3 caddy run --config $HOME/.config/moltis/Caddyfile
EOF

# Service 4: SSLH Stealth Mux
cat <<'EOF' > "$PREFIX/var/service/sslh/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
exec 2>&1
exec sslh-fork --foreground --user u0_a123 --listen 0.0.0.0:4433 --ssh 127.0.0.1:8022 --http 127.0.0.1:3001
EOF
sed -i "s/u0_a123/$(whoami)/" "$PREFIX/var/service/sslh/run"

# Service 5: VS Code Watchdog
cat <<'EOF' > "$PREFIX/var/service/vscode-patcher/run"
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
exec moltis-fix-vscode --watch
EOF

# Link logs for all services
for s in moltis forgejo caddy sslh vscode-patcher; do
    cat <<EOF > "$PREFIX/var/service/$s/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/$s
EOF
    chmod +x "$PREFIX/var/service/$s/run" "$PREFIX/var/service/$s/log/run"
done

echo -e "  ${GREEN}✓ Robust Runit infrastructure laid down${NC}"

# ────────────────────────────────────────────────────────
# PHASE 7: Environment & CLI Commands
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[7/7] Exposing Command Line Interface...${NC}"

# moltis-up
cat <<'EOF' > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
termux-wake-lock 2>/dev/null || true
sshd 2>/dev/null || true
moltis-fix-vscode --quiet >/dev/null 2>&1
sv up moltis forgejo caddy vscode-patcher
IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1)

clear
echo -e "\033[0;32m═══════════════════════════════════════════════════════\033[0m"
echo -e "\033[0;32m  Moltis Antigravity Glibc Workstation Online! 🚀\033[0m"
echo -e "\033[0;36m  IP:\033[0m        $IP"
echo -e "\033[0;36m  Dashboard:\033[0m http://$IP:3002"
echo -e "\033[0;36m  Forgejo:\033[0m   http://$IP:3001"
echo -e "\033[0;36m  SSH:\033[0m       ssh termux@$IP -p 8022"
echo -e "\033[0;32m═══════════════════════════════════════════════════════\033[0m"
EOF

# moltis-stop
cat <<'EOF' > "$PREFIX/bin/moltis-stop"
#!/usr/bin/env bash
echo "Halting services..."
sv down moltis forgejo caddy sslh vscode-patcher 2>/dev/null || true
pkill -f "sslh-fork" 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true
echo "Workstation stopped."
EOF

# Create bashrc aliases
if ! grep -q "Moltis Glibc Terminal" "$HOME/.bashrc" 2>/dev/null; then
    cat <<'EOF' >> "$HOME/.bashrc"

# ═══ Moltis Glibc Terminal Rules ═══
export TERM=xterm-256color
export COLORTERM=truecolor
export PATH="$PREFIX/bin:$PREFIX/glibc/bin:$PATH"
export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"

alias mup="moltis-up"
alias mstop="moltis-stop"
EOF
fi

chmod +x "$PREFIX/bin/moltis-up" "$PREFIX/bin/moltis-stop"
echo -e "  ${GREEN}✓ Setup Complete. Type 'moltis-up' directly.${NC}"

# Final
echo ""
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo -e "${GREEN}${BOLD} ALL DONE! Restart your terminal or SSH connection! ! !${NC}"
echo -e "${GREEN}${BOLD}==========================================================${NC}"
