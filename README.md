# Moltis — Your Pocket AI Workstation

<p align="center">
  <img src="docs/images/moltis-logo.svg" width="80" alt="Moltis Logo">
</p>

<p align="center">
  <strong>Turn any Android phone into a private AI server, Git forge, and web host.</strong><br>
  Zero emulation. Zero cloud dependency. True Bionic VPS orchestration.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-Native_Bionic-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Security-Tailscale-005AFF?style=flat-square&logo=tailscale&logoColor=white" alt="Tailscale">
  <img src="https://img.shields.io/badge/Proc-Runit-FF0000?style=flat-square" alt="Runit">
  <img src="https://img.shields.io/badge/Git-Forgejo-FB923C?style=flat-square&logo=forgejo&logoColor=white" alt="Forgejo">
  <img src="https://img.shields.io/badge/Web-Caddy-00ADD8?style=flat-square&logo=caddy&logoColor=white" alt="Caddy">
  <img src="https://img.shields.io/badge/License-MIT-gray?style=flat-square" alt="MIT">
</p>

---

## What is Moltis?

Moltis transforms a spare Android phone into a **true private VPS** running on the device's native hardware. All binaries are compiled natively against Bionic. Services are orchestrated via `termux-services` (`runit`) just like systemd on a real server.

| Service | Port | What it does |
|---------|------|-------------|
| **Moltis AI** | `46697` | Multi-provider AI gateway with 340+ models, web UI, MCP integrations, and robust SQLite memory. |
| **Forgejo** | `3001` | A full Git forge — repositories, issues, PRs — mapped instantly on Android's secure `Ext4`. |
| **Caddy** | `3002` | Automated web hosting routing docs & dashboards. |

---

## Overcoming Android's VPS Constraints (Why Moltis works)

To make a phone act like a server, Moltis automatically accounts for core Android "quirks":
1. **The Phantom Process Killer:** Android 12+ randomly kills child background apps to save battery. **(See Setup section regarding the ADB command to fix this).**
2. **The Hardcoded Path Trap (`/bin/bash` missing):** We seamlessly intercept hardcoded unix paths using `termux-exec` (`LD_PRELOAD`), allowing `node-pty`, python bots, and random bash scripts to work as if they are running on Ubuntu.
3. **No `systemd` / Init bindings:** Bootstraps `termux-services` (runit module) so if Forgejo or Moltis crashes, they automatically auto-restart.

---

## Install / Setup

Get Termux (via F-Droid, **NOT** Google Play). Then paste:

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/FULL/install.sh | bash
```

### ⚠️ Critical Step for True VPS Stability
You must disable the Phantom Process Killer holding your server back, or Android will mysteriously kill your AI gateway after a few hours:
Plug your phone into a PC (or use Wireless Debugging tools) and run:
```bash
adb shell "settings put global phantom_process_handling false"
```
*(Also set Termux Battery usage to 'Unrestricted' in Android Apps settings).*

---

## Managing Your Services

Because Moltis uses `termux-services`, you don't rely on brittle background commands. You use the service manager (`sv`).

### Boot the Suite
```bash
moltis-up        # Starts moltis, caddy, forgejo via sv
moltis-dev       # Pro mode (adds SSLH stealth multiplexer)
```

### Manual Service Control
```bash
sv up caddy      # Start Caddy web server
sv down forgejo  # Stop Git Forge
sv status moltis # Check if the AI gateway is running
svlogd -tt $PREFIX/var/log/moltis  # Tail your service logs!
```

---

## The Pro Dev Toolkit

Along with core services, `install.sh` provisions a native pocket toolkit designed to emulate root-level workflows inside the unprivileged Bionic sandbox:
- `mosh`: Persistent SSH connections surviving network handoffs between LTE and home Wifi.
- `socat` / `entr`: Advanced port forwarding and directory live-watching.
- `sslh` (Dev Mode): Automatically detects if an incoming connection is SSH or HTTP on a single port (like `4433`) bypassing corporate firewalls.

## Networking via Tailscale
Standard public binding fails on mobile networks due to CGNAT. Connect the Termux instance to **Tailscale** natively:
1. `pkg install tailscale`
2. `tailscaled 2>&1 & tailscale up`
3. Access your phone's stable `100.x.x.x` IP globally.

Add this entry to your laptop `~/.ssh/config`:
```ssh
Host moltis
    HostName 100.x.x.x  # The phone Tailscale IP
    Port 8022
    User termux
```

---

## License

MIT - See the LICENSE file for details.
