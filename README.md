# Moltis Android VPS (Private & Secure)

<img src="docs/images/moltis-logo.svg" width="120" alt="moltis on Android">

![Termux](https://img.shields.io/badge/Termux-Required-orange)
![Tailscale](https://img.shields.io/badge/Security-Tailscale-blue)
![Architecture](https://img.shields.io/badge/Target-Native--aarch64-green)

Turn your phone into a professional, private AI VPS. This setup runs natively on Android with zero emulation overhead, secured behind your Tailscale firewall.

## 🚀 One-Command Install

Paste this into Termux (F-Droid version):

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/vps/install.sh | bash
```

## 🔒 The Private VPS Workflow (Tailscale)

This is the most secure way to work. Your phone is never exposed to the public internet.

### 1. Start the VPS
Run this on your phone:
```bash
moltis-up
```

### 2. Configure your PC
Add this to your PC's SSH config (`~/.ssh/config`):

```ssh
Host moltis
    HostName 100.x.x.x  # Your Phone's Tailscale IP
    Port 8022
    User termux
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### 3. Connect (VS Code / SSH)
*   **Terminal**: Just run `ssh moltis`.
*   **VS Code**: `F1` -> `Remote-SSH: Connect to Host...` -> `moltis`.
*   **Dashboard**: Open `http://100.x.x.x:3000` in your PC browser.

---

## 🌍 Fallback: Public Tunnel (Cloudflare)
If you are on a machine without Tailscale, you can generate a temporary public URL:
```bash
moltis-tunnel
```
*Gives you a temporary `https://...trycloudflare.com` address.*

---

## 🛠️ Toolset

| Command | Purpose |
| --- | --- |
| `moltis-dev` | **Pro Mode**: Full stack (Mosh, Entr, Socat, Sslh) for dev work. |
| `moltis-up` | **Simple Mode**: Basic gateway + Tailscale access. |
| `moltis-update` | Pulls latest native builds and script fixes. |
| `moltis-fix-vscode` | **Healer**: Automatically fixes VS Code Server for Android. |
| `mosh` | **Resilience**: Persistent SSH that survives WiFi drops. |
| `entr` | **DevLoop**: Watches files and re-runs commands automatically. |
| `socat` | **Plumbing**: Bridges sockets and ports across Tailscale. |
| `sslh` | **Stealth**: Multiplexes SSH/HTTP on port 443 (Firewall bypass). |

## 🚀 Professional Suite Quickstart

### 1. Resilient Sessions (Mosh)
Forget SSH timeouts. Mosh handles IP roaming (WiFi to 5G) without dropping your session.
```bash
# Connect from your PC
mosh --ssh="ssh -p 8022" termux@<YOUR_PHONE_IP>
```

### 2. Auto-Reloading (Entr)
Develop on your phone like a pro. Run a command whenever files change.
```bash
# Watch logs and tail them automatically
ls ~/.moltis/*.log | entr tail -f
```

### 3. Networking Plumbing (Socat)
Bridge ports or sockets across your network.
```bash
# Forward local 3000 to Tailscale 8080
socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:127.0.0.1:3000
```

### 4. Stealth Access (SSLH)
Stay connected even on hotel or office networks that block SSH.
```bash
# Access SSH via HTTPS port (443)
ssh -p 443 termux@<YOUR_PHONE_IP>
```

## 🧠 Why Native?
Most Android "Linux" setups use **Proot/Ubuntu** which wastes 2GB of space and adds lag. This repository leverages native **Android NDK (Bionic)** builds for raw, native speed and full compatibility with the Android networking stack.

## ⚠️ Troubleshooting

**OpenRouter / SSL / API Connection Errors**  
If your models fail to load or you see `error sending request for url` inside Moltis, ensure you haven't removed `SSL_CERT_FILE` from your configuration. Android handles SSL root certificates differently than standard Linux.

Make sure your `~/.config/moltis/moltis.toml` includes this exactly as shown:
```toml
[env]
SSL_CERT_FILE = "/data/data/com.termux/files/usr/etc/tls/cert.pem"
```

## Uninstall
```bash
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis
```

## License
MIT
