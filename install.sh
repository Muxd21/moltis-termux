#!/usr/bin/env bash
# Moltis Installer for Android (Termux) - PRIVATE VPS EDITION

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis on Android: Private VPS Mode${NC}"
echo -e "${CYAN}-------------------------------------------------------${NC}"

# Install core dependencies
pkg update -y
pkg install -y curl wget tar openssl ca-certificates binutils termux-api coreutils nodejs which python python-pip libxml2 libxslt clang make pkg-config libiconv mosh || true

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

# Helper: The Simple Gateway (Tailscale Focused)
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
export SSL_CERT_FILE="\$PREFIX/etc/tls/cert.pem"
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

IP=\$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1 || ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print \$2}' || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}')

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis Simple Gateway is Online!${NC}"
echo -e "${CYAN}IP:${NC} \$IP"
echo -e "${CYAN}SSH Access:${NC}   ssh -p 8022 termux@\$IP"
echo -e "${CYAN}Web UI:${NC}       http://\$IP:3000"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

# Helper: The Professional Dev Mode (The Full Stack)
cat <<EOF > "$PREFIX/bin/moltis-dev"
#!/usr/bin/env bash
sshd
export SSL_CERT_FILE="\$PREFIX/etc/tls/cert.pem"
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

# Start SSLH Multiplexer (Forwarding 443 to SSH/3000)
# We use port 4433 as a non-priv substitute if 443 fails
sslh-fork --user \$(whoami) --listen 0.0.0.0:4433 --ssh 127.0.0.1:8022 --http 127.0.0.1:3000 --pidfile /tmp/sslh.pid 2>/dev/null || true

IP=\$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1 || ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print \$2}' || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}')

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis PROFESSIONAL DEV MODE Online! 🚀${NC}"
echo -e "${CYAN}Full Stack:${NC} Mosh + Entr + Socat + Sslh"
echo -e "${CYAN}IP:${NC} \$IP"
echo -e "${CYAN}Resilient Access (Mosh):${NC} mosh --ssh=\"ssh -p 8022\" termux@\$IP"
echo -e "${CYAN}Stealth Multiplexer:${NC}     0.0.0.0:4433 (multiplexes SSH/HTTP)"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${CYAN}Watch logs with Entr:${NC} ls ~/.moltis/*.log | entr tail -f"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-dev"

# Helper: The Public Tunnel (Optional)
cat <<EOF > "$PREFIX/bin/moltis-tunnel"
#!/usr/bin/env bash
echo -e "${CYAN}Starting Anonymous Public Tunnel (Fallback)...${NC}"
cloudflared tunnel --url http://localhost:3000
EOF
chmod +x "$PREFIX/bin/moltis-tunnel"

# Helper: Update
cat <<EOF > "$PREFIX/bin/moltis-update"
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/vps/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "1. Run ${NC}moltis-up${NC}"
echo -e "2. Connect via VS Code on PC using your Tailscale IP."
echo "--------------------------------------------------------"
