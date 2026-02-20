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

### 1. `moltis-up` (The "Everything" Command)
Run this to start your entire stack:
* Starts **Moltis AI Gateway**.
* Starts **VS Code Remote Tunnel** (Background).
* Starts **SSH Server** (Fallback).
* Disables CPU sleep (Wake Lock).

### 2. `moltis-update`
Run this to pull the latest static builds and scripts from GitHub.

---

## 🛠️ First-Time Setup (VS Code)
If you've never used the VS Code tunnel before, run this once to link your GitHub/Microsoft account:
```bash
moltis-tunnel
```
Follow the link, enter the code, and you are done. From then on, `moltis-up` will handle it automatically.

## 🧠 Behind the Scenes

This setup uses **Static Musl Binaries** built via GitHub Actions.
* **Zero Overhead**: No Ubuntu/Proot (saving 1.5GB+).
* **Self-Healing**: `moltis-up` automatically detects and repairs VS Code server binaries for Android compatibility.

## Uninstall
```bash
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis
```

## License
MIT
