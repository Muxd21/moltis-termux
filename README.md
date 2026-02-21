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

## 🧠 Why Native?
Most Android "Linux" setups use **Proot/Ubuntu** which wastes 2GB of space and adds lag. This repository uses **Static Musl Binaries** built via GitHub Actions for raw, native speed.

### Professional VPS Tools
We bundle four critical tools that define a professional VPS experience:
*   **Mosh**: Keeps your session alive when switching between WiFi and Cellular.
*   **Entr**: Enables native hot-reloading for code edits over SSH.
*   **Socat**: The "Swiss-army knife" for networking and socket debugging.
*   **Sslh**: Lets you access your phone via port 443 even on restricted networks.

## Uninstall
```bash
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis
```

## License
MIT
