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
pkg install -y curl wget tar openssl ca-certificates binutils termux-api coreutils nodejs which python python-pip || true

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

echo -e "Downloading Moltis binary..."
curl -sL "$DOWNLOAD_URL" -o "$PREFIX/tmp/moltis-termux.tar.gz"
tar -xzf "$PREFIX/tmp/moltis-termux.tar.gz" -C "$PREFIX/tmp"
mv "$PREFIX/tmp/moltis" "$PREFIX/bin/moltis"
chmod +x "$PREFIX/bin/moltis"
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

# Helper: The God Command (Tailscale Focused)
cat <<EOF > "$PREFIX/bin/moltis-up"
#!/usr/bin/env bash
sshd
export SSL_CERT_FILE="\$PREFIX/etc/tls/cert.pem"
termux-wake-lock
moltis-fix-vscode > /dev/null 2>&1

IP=\$(ifconfig tun0 2>/dev/null | grep 'inet ' | awk '{print \$2}' || ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}')

echo -e "${CYAN}-------------------------------------------------------${NC}"
echo -e "${GREEN}Moltis VPS is Online!${NC}"
echo -e "${CYAN}Tailscale IP:${NC} \$IP"
echo -e "${CYAN}SSH Access:${NC}   ssh -p 8022 termux@\$IP"
echo -e "${CYAN}Web UI:${NC}       http://\$IP:3000"
echo -e "${CYAN}-------------------------------------------------------${NC}"
echo ""
moltis
EOF
chmod +x "$PREFIX/bin/moltis-up"

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
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
EOF
chmod +x "$PREFIX/bin/moltis-update"

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "--------------------------------------------------------"
echo -e "1. Run ${NC}moltis-up${NC}"
echo -e "2. Connect via VS Code on PC using your Tailscale IP."
echo "--------------------------------------------------------"
