# Moltis on Android (Native Termux)

<img src="docs/images/moltis_android.jpg" alt="moltis on Android">

![Termux](https://img.shields.io/badge/Termux-Required-orange)
![No proot](https://img.shields.io/badge/No%20Proot-Required-blue)
![VS Code](https://img.shields.io/badge/VS%20Code-Tunnel%20(GOAT)-cyan)

A professional AI workstation on your phone. Native performance, cloud-grade connectivity.

## 🚀 One-Command Install

Paste this into Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

## ⚡ The Only Two Commands You Need

### 1. `moltis-up` (The God Command)
Starts the entire stack:
* Starts **Moltis AI Gateway**.
* Starts **VS Code Remote Tunnel** in the background.
* Starts **SSH Server** as a fallback.
* Locks CPU to prevent sleep.

### 2. `moltis-update`
Pulls the latest static builds and scripts from GitHub.

---

## 🍰 First-Time Setup (VS Code)
1. Run `moltis-tunnel` on your phone to link your GitHub/Microsoft account.
2. **On your PC VS Code**: Install the **"Remote - Tunnels"** extension.
3. Open **Remote Explorer** -> Select **Tunnels** -> **Sign In**.
4. Click your device name to connect. No IP or SSH config required!

## 🧠 Behind the Scenes

This setup uses **Static Musl Binaries** built via GitHub Actions.
* **Zero Overhead**: No Ubuntu/Proot distributions (saving 1.5GB+).
* **Self-Healing**: Uses "Proot-Light" + "Node-Swapping" to bypass Android security blocks (PIE) automatically.

## Uninstall
```bash
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis
rm -rf ~/.moltis-vroot
```

## License
MIT
