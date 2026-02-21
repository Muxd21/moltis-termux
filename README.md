# Moltis on Android (Native Termux)

<img src="docs/images/moltis-logo.svg" width="120" alt="moltis on Android">

![Termux](https://img.shields.io/badge/Termux-Required-orange)
![No proot](https://img.shields.io/badge/No%20Proot-Required-blue)
![Tunnels](https://img.shields.io/badge/Tunnel-Cloudflare%20(Open)-f38020)

A professional AI workstation on your phone. Native performance, account-free remote access.

## 🚀 One-Command Install

Paste this into Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

## ⚡ The Open Workflow (Account-Free)

### 1. `moltis-up`
Starts the **Moltis AI Gateway** locally on your phone.

### 2. `moltis-tunnel` (Web Dashboard)
Instantly generates a public HTTPS URL (via Cloudflare) so you can access your Moltis dashboard from any browser in the world. **No login required.**

### 3. `moltis-ssh-tunnel` (VS Code Desktop)
If you use **VSCodium**, **Cursor**, or **PearAI**, use this to expose your phone's SSH port. It provides a secure bridge for your PC's VS Code to connect to your phone's files.

---

## 🛠️ Helper Commands

| Command | Action |
| --- | --- |
| `moltis-up` | Starts the gateway and locks CPU to prevent sleep. |
| `moltis-tunnel` | Generates an anonymous HTTPS URL for the Web UI. |
| `moltis-ssh-tunnel` | Generates a TCP tunnel for VS Code Desktop / SSH. |
| `moltis-update` | Pulls the latest static build and cloudflare agent. |

## 🧠 Why this version?

Unlike official Microsoft Tunnels, this version is **Truly Open**.
* **No Accounts**: No GitHub or Microsoft login required.
* **Open Source**: Uses the `cloudflared` engine, compatible with all VS Code forks.
* **Privacy**: Your data flows through Cloudflare's edge network directly to your device.

## Uninstall
```bash
rm $PREFIX/bin/moltis*
rm $PREFIX/bin/cloudflared
rm -rf ~/.moltis
```

## License
MIT
