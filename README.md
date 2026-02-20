# Moltis on Android (Native Termux)

<img src="docs/images/moltis_android.jpg" alt="moltis on Android">

![Termux](https://img.shields.io/badge/Termux-Required-orange)
![No proot](https://img.shields.io/badge/No%20Proot-Required-blue)
![VS Code](https://img.shields.io/badge/VS%20Code-Tunnel%20(GOAT)-cyan)

The most refined AI gateway setup for Android. No Proot, No Ubuntu overhead—just high-performance static binaries and a cloud-proxied development tunnel.

## 🚀 One-Command Install

Paste this into Termux (installed from F-Droid):

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

## ⚡ Step 1: Start the Gateway
```bash
moltis-up
```
Starts the Moltis AI server and prepares the environment.

## 🍰 Step 2: The GOAT Tunnel (VS Code)
Forget complex SSH configurations. This repository installs the native **VS Code CLI (Musl)** for direct tunneling. 

**On your phone (new tab), run:**
```bash
moltis-tunnel
```
1. Follow the link to log in with GitHub/Microsoft.
2. Open your PC's VS Code, install the **"Remote - Tunnels"** extension.
3. Your phone will appear in the "Remote Explorer" tab. **Click and you are in.**

## 🛠️ Helper Commands

| Command | Action |
| --- | --- |
| `moltis-tunnel` | **Best Method**: Starts a secure cloud tunnel for VS Code. |
| `moltis-up` | Starts the gateway and locks CPU to prevent sleep. |
| `moltis-update` | Pulls the latest static build from GitHub Actions. |
| `moltis-fix-vscode` | repairs VS Code if using the old Fallback SSH method. |

## 🧠 Why this version?

Instead of running a heavy Ubuntu distribution (1.5GB+), we use **GitHub Actions** to cross-compile Moltis into a **Static Musl Binary**.
* **Truly Native**: No emulation layer (proot). Uses ~20MB of storage.
* **Always Updated**: Our CI/CD checks for new versions every 24 hours.
* **PC-Grade Dev Experience**: The Tunnel method gives you full VS Code performance on your phone's files without the lag of a VNC or SSH bridge.

---

## Troubleshooting

### VS Code Tunnel Login
If the link doesn't open, copy the 8-digit code and go to `github.com/login/device` on your computer.

### Permission Denied
Ensure you are using the **F-Droid version of Termux**. The Play Store version is legacy and blocks binary execution on Android 10+.

## License
MIT
