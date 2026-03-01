# Moltis — Your Pocket AI Workstation

<p align="center">
  <img src="docs/imgaes/moltis-logo.svg" width="80" alt="Moltis">
</p>

<p align="center">
  <strong>Turn any Android phone into a private AI server, Git forge, and web host.</strong><br>
  Zero emulation. Zero cloud dependency. One command.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-Native_Bionic-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Security-Tailscale-005AFF?style=flat-square&logo=tailscale&logoColor=white" alt="Tailscale">
  <img src="https://img.shields.io/badge/Git-Forgejo-FB923C?style=flat-square&logo=forgejo&logoColor=white" alt="Forgejo">
  <img src="https://img.shields.io/badge/Web-Caddy-00ADD8?style=flat-square&logo=caddy&logoColor=white" alt="Caddy">
  <img src="https://img.shields.io/badge/License-MIT-gray?style=flat-square" alt="MIT">
</p>

---

## What is Moltis?

Moltis transforms a spare Android phone into a **self-healing, self-documenting AI workstation** that runs entirely on the device's native hardware. No Docker. No Proot. No cloud bills.

It bundles three powerful services behind a single `moltis-up` command:

| Service | Port | What it does |
|---------|------|-------------|
| **Moltis AI** | `46697` | Multi-provider AI gateway (OpenRouter, Gemini, Groq, Cerebras) with 340+ models, MCP integrations, and a web chat UI. |
| **Forgejo** | `3001` | A full GitHub-style Git forge — repositories, issues, pull requests, and CI/CD Actions — powered by native SQLite on Android's Ext4 partition. |
| **Caddy** | `3002` | Instant static site hosting for docs, dashboards, and AI-generated reports. Auto-HTTPS over Tailscale. |

---

## Install

Paste this into [Termux](https://f-droid.org/en/packages/com.termux/) on your Android device:

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/install.sh | bash
```

That's it. Everything is compiled for `aarch64-linux-android` (Bionic) and installs in under 60 seconds.

---

## Quick Start

### Start all services
```bash
moltis-up        # Simple mode
moltis-dev       # Pro mode (adds Mosh, SSLH multiplexer)
```

### Stop all services
```bash
moltis-stop
```

### Connect from your PC

Add to `~/.ssh/config`:
```ssh
Host moltis
    HostName 100.x.x.x  # Your phone's Tailscale IP
    Port 8022
    User termux
```

Then:
- **Terminal:** `ssh moltis`
- **VS Code:** `F1` → Remote-SSH → `moltis`
- **Moltis AI:** `https://100.x.x.x:46697`
- **Forgejo:** `http://100.x.x.x:3001`
- **Caddy Pages:** `http://100.x.x.x:3002`

---

## The Full Toolkit

| Command | Purpose |
|---------|---------|
| `moltis-up` | Start everything — AI + Git + Web in one command. |
| `moltis-dev` | Pro mode with Mosh resilience and SSLH stealth multiplexing. |
| `moltis-stop` | Gracefully stop all services and clean stale locks. |
| `moltis-fix-vscode` | Auto-heal VS Code Server's Node.js for Android. |
| `moltis-update` | Pull the latest scripts and configs from GitHub. |
| `moltis-tunnel` | Generate a temporary public URL via Cloudflare. |

### Pro Dev Suite

| Tool | What it does |
|------|-------------|
| `mosh` | Roaming-proof SSH — survives WiFi ↔ 5G handoffs. |
| `entr` | Watch files and auto-run commands on save. |
| `socat` | Bridge ports and sockets across your Tailnet. |
| `sslh` | Multiplex SSH + HTTP on a single port (firewall bypass). |
| `forgejo` | Native SQLite Git forge with Actions CI/CD. |
| `caddy` | Zero-config HTTPS web server for local pages. |

---

## Use Cases

### 🧠 AI Coding Server
SSH from your laptop into your phone's Moltis gateway. Use VS Code Remote or any MCP-compatible client to access 340+ AI models with zero cloud hosting costs.

### 🐙 Private Git Forge
Push code to Forgejo on your phone instead of GitHub. Review PRs, manage issues, and run CI workflows — all on hardware you own. Mirror to GitHub once a day as a cold backup.

### 📄 Local Documentation Site
Commit Markdown docs to Forgejo → Actions deploy them to Caddy → instant preview at `http://your-phone:3002`. Faster than GitHub Pages with zero latency.

### 🤖 Self-Documenting AI Agent
Your Moltis AI generates reports and dashboards → commits them to local Forgejo → Actions push them to Caddy → your "Daily Dashboard" auto-updates.

### 🏠 Home Lab on the Go
A pocket-sized, battery-backed server that travels with you. Access it anywhere through Tailscale. No static IP, no port forwarding, no DNS hassle.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Android Phone (Termux — Native Bionic aarch64)         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Moltis   │  │ Forgejo  │  │  Caddy   │              │
│  │ AI :46697│  │ Git :3001│  │ Web :3002│              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │              │              │                    │
│       └──────────────┼──────────────┘                    │
│                      │                                   │
│              ┌───────┴───────┐                           │
│              │  Tailscale    │                           │
│              │  WireGuard    │                           │
│              └───────┬───────┘                           │
└──────────────────────┼──────────────────────────────────┘
                       │
              ┌────────┴────────┐
              │   Your Laptop   │
              │  ssh / browser  │
              └─────────────────┘
```

### Why native Bionic?

Most Android "Linux" setups use Proot/Ubuntu — 2GB of wasted space and emulation lag. Static Musl binaries bypass Android's socket broker, breaking DNS and VPN routing.

Moltis compiles directly against Android's **NDK Bionic C runtime**:
- **Zero overhead** (~20 MB total)
- **Native VPN routing** (Tailscale MagicDNS works perfectly)
- **Executable Git hooks** (no `noexec` filesystem issues)
- **First-class SQLite** (Android's native database engine)

---

## Troubleshooting

**SSL / API errors?**
Ensure your `~/.config/moltis/moltis.toml` includes:
```toml
[env]
SSL_CERT_FILE = "/data/data/com.termux/files/usr/etc/tls/cert.pem"
```

**Forgejo won't start?**
Clear stale locks: `rm -rf ~/forgejo-data/queues/` then restart.

**VS Code can't connect?**
Run `moltis-fix-vscode` on the phone, then reconnect.

---

## Uninstall

```bash
moltis-stop
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis ~/forgejo-data ~/www
```

## License

MIT
