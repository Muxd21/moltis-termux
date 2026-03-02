#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
# Moltis Antigravity — Full System Diagnostic
# Checks VS Code patching, PTY bindings, SSH, services
# ═══════════════════════════════════════════════════════

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Moltis Antigravity — System Diagnostic${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"

# ── 1. Terminal Environment ──
echo ""
echo -e "${CYAN}--- 1. Terminal Environment ---${NC}"
echo "  TERM=$TERM"
echo "  COLORTERM=$COLORTERM"
echo "  SHELL=$SHELL"
echo "  LD_PRELOAD=$LD_PRELOAD"
echo "  PREFIX=$PREFIX"
echo "  Node: $(which node 2>/dev/null || echo 'NOT FOUND')"
echo "  Node version: $(node --version 2>/dev/null || echo 'N/A')"

# ── 2. SSH Configuration ──
echo ""
echo -e "${CYAN}--- 2. SSH Configuration ---${NC}"
SSHD_CONF="$PREFIX/etc/ssh/sshd_config"
if [ -f "$SSHD_CONF" ]; then
    echo -e "  ${GREEN}✓${NC} sshd_config exists"
    PORT=$(grep "^Port " "$SSHD_CONF" | awk '{print $2}')
    KEEPALIVE=$(grep "^ClientAliveInterval" "$SSHD_CONF" | awk '{print $2}')
    FORWARDING=$(grep "^AllowTcpForwarding" "$SSHD_CONF" | awk '{print $2}')
    echo "  Port: ${PORT:-default}"
    echo "  ClientAliveInterval: ${KEEPALIVE:-not set}"
    echo "  AllowTcpForwarding: ${FORWARDING:-not set}"
else
    echo -e "  ${RED}✗${NC} sshd_config NOT FOUND"
fi
# Check sshd running
if pgrep -x sshd >/dev/null 2>&1; then
    echo -e "  sshd: ${GREEN}running${NC}"
else
    echo -e "  sshd: ${RED}not running${NC}"
fi

# ── 3. VS Code Server Binaries ──
echo ""
echo -e "${CYAN}--- 3. VS Code / Antigravity Server Binaries ---${NC}"
for BASE_DIR in "$HOME/.vscode-server/bin" "$HOME/.antigravity-server/bin"; do
    [ -d "$BASE_DIR" ] || continue
    echo "  Base: $BASE_DIR"
    for d in "$BASE_DIR"/*/; do
        [ -d "$d" ] || continue
        DIR=$(basename "$d")
        echo ""
        echo -e "  ${ORANGE}[$DIR]${NC}"
        
        # Check node binary
        if [ -f "$d/node" ]; then
            if head -10 "$d/node" 2>/dev/null | grep -q "LD_PRELOAD"; then
                echo -e "    node: ${GREEN}Bionic wrapper (patched)${NC}"
            else
                TYPE=$(file "$d/node" 2>/dev/null | head -1)
                echo -e "    node: ${RED}$TYPE${NC}"
            fi
        elif [ -f "$d/node.original" ]; then
            echo -e "    node: ${RED}MISSING (node.original exists — re-run moltis-fix-vscode)${NC}"
        else
            echo -e "    node: ${RED}NOT FOUND${NC}"
        fi
        
        # Check node.original backup
        [ -f "$d/node.original" ] && echo "    node.original: exists (backup)"
        
        # Check .env
        if [ -f "$d/.env" ]; then
            echo -e "    .env: ${GREEN}exists${NC}"
        else
            echo -e "    .env: ${ORANGE}missing${NC}"
        fi
        
        # Check pty.node bindings
        for PTY_ROOT in "node_modules/node-pty" "node_modules/@vscode/node-pty"; do
            PTY_PATH="$d/$PTY_ROOT/build/Release/pty.node"
            if [ -f "$PTY_PATH" ]; then
                PTY_TYPE=$(file "$PTY_PATH" 2>/dev/null | head -1)
                if echo "$PTY_TYPE" | grep -q "aarch64\|ARM"; then
                    echo -e "    $PTY_ROOT: ${GREEN}Native ARM64${NC}"
                else
                    echo -e "    $PTY_ROOT: ${RED}$PTY_TYPE${NC}"
                fi
            fi
        done
        
        # Check for conflicting libraries
        for PTY_ROOT in "node_modules/node-pty" "node_modules/@vscode/node-pty"; do
            LIBUTIL="$d/$PTY_ROOT/build/Release/libutil.so"
            [ -f "$LIBUTIL" ] && echo -e "    ${RED}⚠ Conflicting libutil.so found in $PTY_ROOT${NC}"
        done
    done
done

# ── 4. Global node-pty ──
echo ""
echo -e "${CYAN}--- 4. Global node-pty ---${NC}"
for PTY_PATH in "$(npm root -g 2>/dev/null)/node-pty/build/Release/pty.node" \
                "$(npm root -g 2>/dev/null)/@vscode/node-pty/build/Release/pty.node"; do
    if [ -f "$PTY_PATH" ]; then
        echo -e "  ${GREEN}✓${NC} $PTY_PATH"
        echo "    Type: $(file "$PTY_PATH" 2>/dev/null)"
    fi
done

echo ""
echo -e "${CYAN}--- 5. Node can load node-pty? ---${NC}"
node -e "try { require('$(npm root -g 2>/dev/null)/node-pty'); console.log('  SUCCESS: node-pty loads'); } catch(e) { console.log('  FAIL:', e.message); }" 2>&1

# ── 6. Runit Service Status ──
echo ""
echo -e "${CYAN}--- 6. Runit Service Status ---${NC}"
for svc in moltis forgejo caddy sslh vscode-patcher; do
    STATUS=$(sv status "$svc" 2>/dev/null || echo "not configured")
    if echo "$STATUS" | grep -q "^run:"; then
        echo -e "  ${GREEN}●${NC} $svc: ${GREEN}running${NC}"
    else
        echo -e "  ${RED}○${NC} $svc: $STATUS"
    fi
done

# ── 7. Wakelock Status ──
echo ""
echo -e "${CYAN}--- 7. Android OOM Mitigation ---${NC}"
if [ -f "$HOME/.termux/boot/start-services" ]; then
    echo -e "  Boot hook: ${GREEN}installed${NC}"
else
    echo -e "  Boot hook: ${RED}missing${NC}"
fi
# Check if wakelock is active (termux-wake-lock creates a notification)
if pgrep -f "termux.*wake" >/dev/null 2>&1 || [ -f "/data/data/com.termux/files/home/.termux/shell" ]; then
    echo -e "  Wakelock: ${GREEN}likely active${NC}"
else
    echo -e "  Wakelock: ${ORANGE}unknown (check notification bar)${NC}"
fi

# ── 8. Network ──
echo ""
echo -e "${CYAN}--- 8. Network ---${NC}"
TS_IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
WLAN_IP=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -n 1)
echo "  Tailscale: ${TS_IP:-not connected}"
echo "  WiFi:      ${WLAN_IP:-not connected}"

# ── 9. Bionic Compat Headers ──
echo ""
echo -e "${CYAN}--- 9. Bionic Compatibility ---${NC}"
if [ -f "$HOME/.openclaw-android/patches/termux-compat.h" ]; then
    echo -e "  termux-compat.h: ${GREEN}exists${NC}"
else
    echo -e "  termux-compat.h: ${RED}missing${NC}"
fi
if [ -f "$PREFIX/bin/ldd" ]; then
    echo -e "  ldd shim: ${GREEN}installed${NC}"
else
    echo -e "  ldd shim: ${RED}missing${NC}"
fi

# ── 10. Recent Logs ──
echo ""
echo -e "${CYAN}--- 10. Recent Error Logs ---${NC}"
for svc in moltis forgejo caddy; do
    LOG="$PREFIX/var/log/$svc/current"
    if [ -f "$LOG" ]; then
        ERRORS=$(grep -i "error\|fail\|panic" "$LOG" 2>/dev/null | tail -3)
        if [ -n "$ERRORS" ]; then
            echo -e "  ${RED}[$svc] Recent errors:${NC}"
            echo "$ERRORS" | while read -r line; do
                echo "    $line"
            done
        else
            echo -e "  ${GREEN}[$svc]${NC} No recent errors"
        fi
    fi
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Diagnostic complete.${NC}"
echo -e "  Run ${CYAN}moltis-fix-vscode --force${NC} to re-patch VS Code."
echo -e "  Run ${CYAN}moltis-status${NC} for a quick health check."
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
