#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Moltis Installer for Android (Termux) — ANTIGRAVITY EDITION
# Native Bionic + termux-exec + termux-services + Self-Healing VS Code
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Moltis Antigravity: Bionic VPS Installer${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}
banner

# ────────────────────────────────────────────────────────
# PHASE 0: Android Quirks Warning
# ────────────────────────────────────────────────────────
echo -e "\n${RED}${BOLD}⚠️  CRITICAL BIONIC VPS PREREQUISITES ⚠️${NC}"
echo -e "1. ${CYAN}Phantom Process Killer:${NC} Android 12+ kills background apps."
echo -e "   Run from your PC via ADB:"
echo -e "   ${GREEN}adb shell \"settings put global phantom_process_handling false\"${NC}"
echo -e "2. ${CYAN}Battery Optimization:${NC} Set Termux + Tailscale to 'Unrestricted'."
echo -e "3. ${CYAN}Paths:${NC} termux-exec handles /bin/bash → \$PREFIX/bin/bash translation."
echo -e "───────────────────────────────────────────────────────────\n"

sleep 3

# ────────────────────────────────────────────────────────
# PHASE 1: Core Dependencies
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[1/8] Installing Core Dependencies...${NC}"
pkg update -y
pkg install -y \
    termux-exec termux-services termux-api \
    curl wget tar openssl ca-certificates binutils \
    coreutils nodejs which python python-pip \
    libxml2 libxslt clang make pkg-config libiconv \
    mosh tmux caddy gitea runit \
    inotify-tools openssh \
    || true

# Shim: fake ldd for tools that probe for glibc
if [ ! -f "$PREFIX/bin/ldd" ]; then
    cat <<'EOF' > "$PREFIX/bin/ldd"
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
    echo "ldd (Bionic shim) 2.28"
    exit 0
fi
echo "libc.so.6 => /system/lib64/libc.so (0x0000000000000000)"
EOF
    chmod +x "$PREFIX/bin/ldd"
fi

# ────────────────────────────────────────────────────────
# PHASE 2: Bionic Compatibility Headers
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[2/8] Setting up Bionic Compatibility Layer...${NC}"
mkdir -p ~/.openclaw-android/patches/
touch ~/.openclaw-android/patches/bionic-compat.js

cat <<'COMPAT_H' > ~/.openclaw-android/patches/termux-compat.h
/* Termux Bionic compatibility shim — intentionally minimal */
#ifndef TERMUX_COMPAT_H
#define TERMUX_COMPAT_H
/* No-op: Termux Bionic does not need extra compat for node-pty */
#endif
COMPAT_H

# ────────────────────────────────────────────────────────
# PHASE 3: Fetch Latest Moltis Bionic Build
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[3/8] Fetching latest Moltis Bionic build...${NC}"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Muxd21/moltis-termux/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*moltis-termux-aarch64.tar.gz"' | head -n 1 | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find release binary from Muxd21/moltis-termux.${NC}"
    echo -e "${ORANGE}Continuing with existing binaries (if present)...${NC}"
else
    echo -e "  Downloading Moltis AI + Pro Tools..."
    curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
    tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/bin"
    chmod +x "$PREFIX/bin/moltis" "$PREFIX/bin/mosh"* "$PREFIX/bin/entr" "$PREFIX/bin/socat" "$PREFIX/bin/sslh" 2>/dev/null || true
    rm -f "$PREFIX/tmp/moltis-termux.tar.gz"
    echo -e "  ${GREEN}✓ Binaries extracted${NC}"
fi

# ────────────────────────────────────────────────────────
# PHASE 4: Deploy VPS Dashboard & Configs
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[4/8] Deploying Workstation configs...${NC}"
mkdir -p ~/.config/moltis ~/www/docs ~/forgejo-data/repositories

curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/app.ini" -o ~/.config/moltis/app.ini
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/vps-config/Caddyfile" -o ~/.config/moltis/Caddyfile
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/docs/index.html" -o ~/www/docs/index.html

# Patch config with real Termux username
sed -i "s/__TERMUX_USER__/$(whoami)/" ~/.config/moltis/app.ini

# Gitea → Forgejo symlink
if [ -f "$PREFIX/bin/gitea" ] && [ ! -f "$PREFIX/bin/forgejo" ]; then
    ln -sf "$PREFIX/bin/gitea" "$PREFIX/bin/forgejo"
fi

echo -e "  ${GREEN}✓ Configs deployed${NC}"

# ────────────────────────────────────────────────────────
# PHASE 5: Hardened SSH Configuration
# Aggressive keepalive to survive Android network switches
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[5/8] Deploying Hardened SSH Configuration...${NC}"

mkdir -p "$PREFIX/etc/ssh"

# Write the optimized sshd_config
cat <<'SSHD_CONF' > "$PREFIX/etc/ssh/sshd_config"
# ═══════════════════════════════════════════════════════
# Moltis Antigravity — Hardened sshd_config for Android
# Aggressive keepalive prevents Android from reaping SSH
# ═══════════════════════════════════════════════════════

Port 8022

# ── Connection Persistence ──
# Prevents session hangs when switching WiFi ↔ 5G
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 10

# ── Tunneling & Port Forwarding ──
# Required for VS Code Remote, Moltis AI, Forgejo port tunnels
AllowTcpForwarding yes
GatewayPorts yes

# ── Security ──
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no

# ── Performance ──
# Compression helps on mobile data
Compression yes

# ── Subsystems ──
Subsystem sftp /data/data/com.termux/files/usr/libexec/sftp-server

# ── PTY ──
# Permit TTY allocation for VS Code terminal
PermitTTY yes
SSHD_CONF

# Generate host keys if missing
if [ ! -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" -N "" -q
    echo -e "  ${GREEN}✓ ED25519 host key generated${NC}"
fi
if [ ! -f "$PREFIX/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -b 4096 -f "$PREFIX/etc/ssh/ssh_host_rsa_key" -N "" -q
    echo -e "  ${GREEN}✓ RSA host key generated${NC}"
fi

echo -e "  ${GREEN}✓ sshd_config deployed (Port 8022, KeepAlive 30s, Tunneling ON)${NC}"

# ────────────────────────────────────────────────────────
# PHASE 6: Self-Healing VS Code Binary Patcher
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[6/8] Installing Self-Healing VS Code Patcher...${NC}"

cat <<'EOF' > "$PREFIX/bin/moltis-fix-vscode"
#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════
# Moltis Antigravity — Self-Healing VS Code Patcher
# Intercepts glibc Node.js binaries and hot-swaps them
# with native Termux Bionic node.
# ═══════════════════════════════════════════════════════
set -euo pipefail

PREFIX="/data/data/com.termux/files/usr"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

FORCE=0
QUIET=0
WATCH=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --quiet) QUIET=1 ;;
        --watch) WATCH=1 ;;
    esac
done

log() { [ "$QUIET" -eq 0 ] && echo -e "$@"; }

# ── Step 0: Ensure Bionic compat headers exist ──
mkdir -p "$HOME/.openclaw-android/patches"
if [ ! -f "$HOME/.openclaw-android/patches/termux-compat.h" ]; then
    log "${CYAN}Creating termux-compat.h for native addon compilation...${NC}"
    cat <<'COMPAT' > "$HOME/.openclaw-android/patches/termux-compat.h"
/* Termux Bionic compatibility shim */
#ifndef TERMUX_COMPAT_H
#define TERMUX_COMPAT_H
#endif
COMPAT
fi

# ── Step 1: Build/Find global node-pty for Bionic ──
GLOBAL_PTY=""
if npm ls -g node-pty >/dev/null 2>&1; then
    GLOBAL_PTY="$(npm root -g)/node-pty/build/Release/pty.node"
    [ -f "$GLOBAL_PTY" ] || GLOBAL_PTY=""
fi

if [ -z "$GLOBAL_PTY" ]; then
    log "${CYAN}Installing global node-pty for Termux Bionic compatibility...${NC}"
    export CPPFLAGS="-I$PREFIX/include"
    export CXXFLAGS="-I$PREFIX/include"
    export LDFLAGS="-L$PREFIX/lib"
    
    if npm install -g @vscode/node-pty --cc=clang --cxx=clang++ 2>&1 || \
       npm install -g node-pty --cc=clang --cxx=clang++ 2>&1; then
        GLOBAL_PTY="$(npm root -g)/@vscode/node-pty/build/Release/pty.node"
        [ -f "$GLOBAL_PTY" ] || GLOBAL_PTY="$(npm root -g)/node-pty/build/Release/pty.node"
        [ -f "$GLOBAL_PTY" ] || GLOBAL_PTY=""
    else
        log "${ORANGE}⚠ node-pty compilation failed — will use script-based PTY fallback${NC}"
    fi
fi

# ── Core patching function ──
PATCHED=0

is_bionic_wrapper() {
    [ -f "$1" ] || return 1
    head -10 "$1" 2>/dev/null | grep -q "LD_PRELOAD" && return 0
    return 1
}

patch_server_dirs() {
    for BASE_DIR in "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"; do
        [ -d "$BASE_DIR" ] || continue
        for dir in "$BASE_DIR"/*; do
            [ -d "$dir" ] || continue

            NODE_BIN="$dir/node"
            [ -e "$NODE_BIN" ] || [ -e "$dir/node.original" ] || continue

            # Detect if patching is needed
            NEEDS_PATCH=0
            if [ "$FORCE" -eq 1 ]; then
                NEEDS_PATCH=1
            elif [ ! -e "$NODE_BIN" ]; then
                NEEDS_PATCH=1
            elif is_bionic_wrapper "$NODE_BIN"; then
                NEEDS_PATCH=0
            else
                # Not a wrapper — it's a glibc binary that needs replacing
                NEEDS_PATCH=1
            fi

            if [ "$NEEDS_PATCH" -eq 1 ]; then
                COMMIT_ID=$(basename "$dir")
                log "${ORANGE}🔧 Patching server [${COMMIT_ID:0:8}...] for Android Bionic...${NC}"

                # Backup original (idempotent)
                if [ -e "$NODE_BIN" ] && [ ! -f "$dir/node.original" ]; then
                    mv "$NODE_BIN" "$dir/node.original"
                fi
                rm -f "$NODE_BIN"

                # Write the Bionic wrapper that exec's into Termux's native node
                cat <<'WRAPPER' > "$NODE_BIN"
#!/data/data/com.termux/files/usr/bin/bash
# Moltis Antigravity — Bionic Node Wrapper
PREFIX="/data/data/com.termux/files/usr"

# Enable path translation for scripts with /bin/bash shebangs
export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"

# Environmental Context
export PATH="$PREFIX/bin:$PATH"
export SHELL="$PREFIX/bin/bash"
export TERM="${TERM:-xterm-256color}"
export COLORTERM="truecolor"
export TMPDIR="$PREFIX/tmp"
export TMP="$PREFIX/tmp"
export TEMP="$PREFIX/tmp"

# Exec native Termux Bionic node
exec "$PREFIX/bin/node" "$@"
WRAPPER
                chmod +x "$NODE_BIN"
                log "  ${GREEN}✓ Bionic wrapper injected (LD_PRELOAD + xterm-256color)${NC}"
                PATCHED=$((PATCHED + 1))
            fi

            # ── Graft native pty.node bindings ──
            for PTY_ROOT in "node_modules/node-pty" "node_modules/@vscode/node-pty"; do
                PTY_DIR="$dir/$PTY_ROOT/build/Release"
                if [ -d "$PTY_DIR" ] && [ -n "$GLOBAL_PTY" ] && [ -f "$GLOBAL_PTY" ]; then
                    if [ "$FORCE" -eq 1 ] || [ ! -f "$PTY_DIR/pty.node.original" ]; then
                        [ -f "$PTY_DIR/pty.node" ] && [ ! -f "$PTY_DIR/pty.node.original" ] && \
                            mv "$PTY_DIR/pty.node" "$PTY_DIR/pty.node.original"
                        cp "$GLOBAL_PTY" "$PTY_DIR/pty.node"
                        log "  ${GREEN}✓ pty.node bindings grafted (via $PTY_ROOT)${NC}"
                    fi
                fi

                # Remove conflicting musl/glibc libraries that break Bionic
                CONFLICT_LIB="$dir/$PTY_ROOT/build/Release/libutil.so"
                [ -f "$CONFLICT_LIB" ] && rm -f "$CONFLICT_LIB" && \
                    log "  ${GREEN}✓ Removed conflicting libutil.so${NC}"
            done

            # ── Server .env configuration ──
            ENV_FILE="$dir/.env"
            if [ ! -f "$ENV_FILE" ] || [ "$FORCE" -eq 1 ]; then
                cat <<ENVF > "$ENV_FILE"
SHELL=$PREFIX/bin/bash
TERM=xterm-256color
COLORTERM=truecolor
LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
ENVF
                log "  ${GREEN}✓ Server .env configured${NC}"
            fi
        done
    done
}

# ── Run the patcher ──
patch_server_dirs

if [ "$PATCHED" -gt 0 ]; then
    log "${GREEN}✅ Patched $PATCHED server installation(s) for Android Bionic.${NC}"
    log "${CYAN}   Restart your IDE to clear the orange PTY Host indicator.${NC}"
elif [ "$QUIET" -eq 0 ]; then
    log "${GREEN}✅ All server installations are already patched. No action needed.${NC}"
fi

# ── Watchdog Mode: Auto-patch new VS Code updates ──
if [ "$WATCH" -eq 1 ]; then
    log "${CYAN}🔭 Watchdog mode: Monitoring for new VS Code server installations...${NC}"
    log "   Press Ctrl+C to stop.\n"
    
    # Create the directories if they don't exist yet
    mkdir -p "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"
    
    # Watch for new commit directories being created
    while true; do
        inotifywait -q -r -e create,moved_to \
            "$HOME/.vscode-server/bin" \
            "$HOME/.antigravity-server/bin" 2>/dev/null || true
        
        # Brief delay to let VS Code finish extracting
        sleep 3
        
        FORCE=0 QUIET=0 patch_server_dirs
    done
fi
EOF
chmod +x "$PREFIX/bin/moltis-fix-vscode"
echo -e "  ${GREEN}✓ moltis-fix-vscode installed (with --watch watchdog mode)${NC}"

# ────────────────────────────────────────────────────────
# PHASE 7: TERMUX-SERVICES (runit) + OOM Killer Mitigation
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[7/8] Configuring Services & OOM Killer Mitigation...${NC}"

# Boot hook: wakelock + sshd on device boot
mkdir -p ~/.termux/boot/
cat <<'EOF' > ~/.termux/boot/start-services
#!/data/data/com.termux/files/usr/bin/bash
# Moltis Antigravity — Boot Hook
# Acquire wakelock and start SSH immediately on boot
termux-wake-lock
sshd
# Auto-patch VS Code servers on boot
moltis-fix-vscode --quiet &
EOF
chmod +x ~/.termux/boot/start-services

# Service logs directories
mkdir -p "$PREFIX/var/log/moltis"
mkdir -p "$PREFIX/var/log/forgejo"
mkdir -p "$PREFIX/var/log/caddy"
mkdir -p "$PREFIX/var/log/sslh"

# ── Service 1: Moltis AI ──
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
export TERM=xterm-256color
export COLORTERM=truecolor
exec 2>&1
# OOM Killer Mitigation: elevate process priority
exec nice -n -5 ionice -c 2 -n 0 moltis
EOF
cat <<'EOF' > "$PREFIX/var/service/moltis/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/moltis
EOF
chmod +x "$PREFIX/var/service/moltis/run" "$PREFIX/var/service/moltis/log/run"

# ── Service 2: Forgejo ──
mkdir -p "$PREFIX/var/service/forgejo/log"
cat <<'EOF' > "$PREFIX/var/service/forgejo/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
export FORGEJO_WORK_DIR="$HOME/forgejo-data"
exec 2>&1
exec nice -n -5 ionice -c 2 -n 0 forgejo web -c $HOME/.config/moltis/app.ini
EOF
cat <<'EOF' > "$PREFIX/var/service/forgejo/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/forgejo
EOF
chmod +x "$PREFIX/var/service/forgejo/run" "$PREFIX/var/service/forgejo/log/run"

# ── Service 3: Caddy ──
mkdir -p "$PREFIX/var/service/caddy/log"
cat <<'EOF' > "$PREFIX/var/service/caddy/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
exec 2>&1
exec nice -n -3 caddy run --config $HOME/.config/moltis/Caddyfile
EOF
cat <<'EOF' > "$PREFIX/var/service/caddy/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/caddy
EOF
chmod +x "$PREFIX/var/service/caddy/run" "$PREFIX/var/service/caddy/log/run"

# ── Service 4: SSLH Stealth Mux ──
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
sed -i "s/u0_a123/$(whoami)/" "$PREFIX/var/service/sslh/run"
cat <<'EOF' > "$PREFIX/var/service/sslh/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/sslh
EOF
chmod +x "$PREFIX/var/service/sslh/run" "$PREFIX/var/service/sslh/log/run"

# ── Service 5: VS Code Patcher Watchdog (auto-heals new updates) ──
mkdir -p "$PREFIX/var/service/vscode-patcher/log"
cat <<'EOF' > "$PREFIX/var/service/vscode-patcher/run"
#!/data/data/com.termux/files/usr/bin/sh
export HOME="/data/data/com.termux/files/home"
export PREFIX="/data/data/com.termux/files/usr"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin"
exec 2>&1
exec moltis-fix-vscode --watch
EOF
cat <<'EOF' > "$PREFIX/var/service/vscode-patcher/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $PREFIX/var/log/moltis
EOF
chmod +x "$PREFIX/var/service/vscode-patcher/run" "$PREFIX/var/service/vscode-patcher/log/run"

echo -e "  ${GREEN}✓ All runit services configured with OOM priority elevation${NC}"

# ────────────────────────────────────────────────────────
# PHASE 8: CLI Helpers (moltis-up / stop / dev / bot / update)
# ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[8/8] Installing CLI Helpers...${NC}"

# ── moltis-up: Production Service Launcher with Wakelock + Priority ──
cat <<'EOF' > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
# Moltis Antigravity — Service Launcher
# Wakelock + Process Priority + Terminal Env + Auto-Patch
# ═══════════════════════════════════════════════════════

GREEN='\033[0;32m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

# ── Step 1: Acquire wakelock to prevent CPU sleep ──
echo -e "${CYAN}🔒 Acquiring Termux wakelock...${NC}"
termux-wake-lock 2>/dev/null || true

# ── Step 2: Export terminal environment for VS Code compatibility ──
export TERM=xterm-256color
export COLORTERM=truecolor
export PATH="$PREFIX/bin:$PATH"
export SHELL="$PREFIX/bin/bash"
export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"

# ── Step 3: Start SSH daemon ──
sshd 2>/dev/null || true

# ── Step 4: Auto-patch VS Code servers (silent) ──
moltis-fix-vscode --quiet > /dev/null 2>&1

# ── Step 5: Start runit services with priority ──
echo -e "${CYAN}🚀 Starting Bionic VPS Services via runit...${NC}"
sv up moltis
sv up forgejo
sv up caddy
sv up vscode-patcher

# ── Step 6: Display status ──
IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || \
     ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1)

clear
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Moltis Antigravity VPS is Online! 🚀${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}IP:${NC}        $IP"
echo -e "  ${CYAN}Dashboard:${NC} http://$IP:3002"
echo -e "  ${CYAN}Forgejo:${NC}   http://$IP:3001"
echo -e "  ${CYAN}Moltis AI:${NC} https://$IP:46697"
echo -e "  ${CYAN}SSH:${NC}       ssh termux@$IP -p 8022"
echo ""
echo -e "  ${ORANGE}Wakelock:${NC}       ACTIVE (CPU won't sleep)"
echo -e "  ${ORANGE}VS Code Patch:${NC}  Watchdog ACTIVE (auto-heals updates)"
echo ""
echo -e "  Check logs:  ${CYAN}cat $PREFIX/var/log/<service>/current${NC}"
echo -e "  Stop all:    ${CYAN}moltis-stop${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
EOF
chmod +x "$PREFIX/bin/moltis-up"

# ── moltis-stop ──
cat <<'EOF' > "$PREFIX/bin/moltis-stop"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
echo -e "${CYAN}Stopping all runit services...${NC}"
sv down moltis forgejo caddy sslh vscode-patcher 2>/dev/null || true
pkill -f "sslh-fork" 2>/dev/null || true
rm -rf ~/forgejo-data/queues/ 2>/dev/null || true
sleep 1
termux-wake-unlock 2>/dev/null || true
echo -e "${GREEN}All services stopped. Wakelock released.${NC}"
EOF
chmod +x "$PREFIX/bin/moltis-stop"

# ── moltis-dev: Pro Mode ──
cat <<'EOF' > "$PREFIX/bin/moltis-dev"
#!/usr/bin/env bash
moltis-up
sleep 2
echo -e "\033[0;36mActivating Professional Stealth Mux (Port 4433)...\033[0m"
sv up sslh
IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || echo "localhost")
echo -e "Stealth Mux Access (SSH + HTTP): $IP:4433"
EOF
chmod +x "$PREFIX/bin/moltis-dev"

# ── moltis-bot-setup ──
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
echo -e "Check logs: \033[0;36mcat $PREFIX/var/log/$BOT_NAME/current\033[0m"
EOF
chmod +x "$PREFIX/bin/moltis-bot-setup"

# ── moltis-update ──
cat <<'EOF' > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
echo -e "\033[0;36mUpdating Moltis Antigravity Workstation...\033[0m"
echo -e "  Upgrading Termux packages..."
pkg upgrade -y || true
echo -e "  Downloading latest installer..."
curl -sL "https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/install.sh" | bash
moltis-fix-vscode > /dev/null 2>&1
echo -e "\033[0;32mUpdate Complete! Restart services: moltis-stop && moltis-up\033[0m"
EOF
chmod +x "$PREFIX/bin/moltis-update"

# ── moltis-status: Quick health check ──
cat <<'EOF' > "$PREFIX/bin/moltis-status"
#!/usr/bin/env bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}═══ Moltis Service Status ═══${NC}"
for svc in moltis forgejo caddy sslh vscode-patcher; do
    STATUS=$(sv status "$svc" 2>/dev/null || echo "not configured")
    if echo "$STATUS" | grep -q "^run:"; then
        echo -e "  ${GREEN}●${NC} $svc: ${GREEN}running${NC}"
    else
        echo -e "  ${RED}○${NC} $svc: ${RED}$STATUS${NC}"
    fi
done

echo ""
echo -e "${CYAN}═══ Network ═══${NC}"
IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || echo "N/A")
echo -e "  Tailscale IP: ${GREEN}$IP${NC}"
WLAN=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1 || echo "N/A")
echo -e "  WiFi IP:      ${GREEN}$WLAN${NC}"

echo ""
echo -e "${CYAN}═══ VS Code Servers ═══${NC}"
for BASE_DIR in "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"; do
    [ -d "$BASE_DIR" ] || continue
    for dir in "$BASE_DIR"/*; do
        [ -d "$dir" ] || continue
        COMMIT=$(basename "$dir")
        if head -10 "$dir/node" 2>/dev/null | grep -q "LD_PRELOAD"; then
            echo -e "  ${GREEN}✓${NC} ${COMMIT:0:12}... ${GREEN}(Bionic patched)${NC}"
        elif [ -f "$dir/node" ]; then
            echo -e "  ${RED}✗${NC} ${COMMIT:0:12}... ${RED}(UNPATCHED — run moltis-fix-vscode)${NC}"
        fi
    done
done
EOF
chmod +x "$PREFIX/bin/moltis-status"

echo -e "  ${GREEN}✓ All CLI helpers installed${NC}"

# ────────────────────────────────────────────────────────
# PHASE 9: .bashrc Environment & Auto-Detect Hook
# ────────────────────────────────────────────────────────
echo -e "${CYAN}Configuring terminal environment...${NC}"

# Terminal environment block
BASHRC_ENV='# ═══ Moltis Antigravity Terminal Environment ═══
# Force 256-color + truecolor for VS Code and modern terminals
export TERM=xterm-256color
export COLORTERM=truecolor
# Ensure Termux Bionic binaries take priority
export PATH="$PREFIX/bin:$PATH"
export SHELL="$PREFIX/bin/bash"
# Bionic path translation for scripts with /bin/bash shebangs
export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"'

BASHRC_HOOK='# Moltis Auto-Detect: Silently patch new VS Code server updates on login
if command -v moltis-fix-vscode &>/dev/null; then
    moltis-fix-vscode --quiet &
fi'

if ! grep -q "Moltis Antigravity Terminal" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "$BASHRC_ENV" >> "$HOME/.bashrc"
    echo -e "${GREEN}  ✓ Terminal environment added to .bashrc${NC}"
fi

if ! grep -q "Moltis Auto-Detect" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "$BASHRC_HOOK" >> "$HOME/.bashrc"
    echo -e "${GREEN}  ✓ Auto-detect hook added to .bashrc${NC}"
fi

# ────────────────────────────────────────────────────────
# DONE: Installation Summary
# ────────────────────────────────────────────────────────
echo ""
banner
echo -e "\n${GREEN}${BOLD}Setup Complete! Antigravity Bionic VPS is ready.${NC}\n"
echo -e "  ${CYAN}moltis-up${NC}           Start all services (with wakelock + priority)"
echo -e "  ${CYAN}moltis-dev${NC}          Pro Mode (Stealth Mux on :4433)"
echo -e "  ${CYAN}moltis-stop${NC}         Stop all services + release wakelock"
echo -e "  ${CYAN}moltis-status${NC}       Health check (services, network, VS Code)"
echo -e "  ${CYAN}moltis-fix-vscode${NC}   Patch VS Code binaries (--force --watch)"
echo -e "  ${CYAN}moltis-update${NC}       Self-update everything"
echo -e "  ${CYAN}moltis-bot-setup${NC}    Add a custom bot as a runit service"
echo -e "  ${CYAN}sv status <service>${NC} Check individual service"
echo ""
echo -e "  ${ORANGE}Laptop SSH config (add to ~/.ssh/config):${NC}"
echo -e "  ┌──────────────────────────────────────────────────┐"
echo -e "  │ Host moltis                                      │"
echo -e "  │     HostName 100.x.x.x  # Tailscale IP          │"
echo -e "  │     User termux                                  │"
echo -e "  │     Port 8022                                    │"
echo -e "  │     ServerAliveInterval 15                       │"
echo -e "  │     ServerAliveCountMax 3                        │"
echo -e "  │     ControlMaster auto                           │"
echo -e "  │     ControlPath ~/.ssh/moltis-%r@%h:%p           │"
echo -e "  │     ControlPersist 5m                            │"
echo -e "  └──────────────────────────────────────────────────┘"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
