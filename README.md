# Moltis on Android (Native Termux)

<img src="docs/images/moltis_android.jpg" alt="moltis on Android">

![Termux](https://img.shields.io/badge/Termux-Required-orange)
![No proot](https://img.shields.io/badge/No%20Proot-Required-blue)
![Architecture](https://img.shields.io/badge/Arch-aarch64--musl-green)

A high-performance AI gateway running natively on your spare phone. No bloated Linux distributions, no overhead—just raw Rust power.

## 🚀 One-Command Install

Paste this into Termux (installed from F-Droid):

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

## ⚡ The "All-In-One" Startup

Once installed, you only need one command to run everything:

```bash
moltis-up
```

**What it does:**
1. **SSHD**: Starts the SSH server for PC connection.
2. **Wake Lock**: Prevents Android from killing the process when the screen is off.
3. **VS Code Patch**: Automatically repairs the VS Code Remote-SSH server for Termux compatibility.
4. **Gateway**: Launches the Moltis AI Gateway.

## 💻 Seamless VS Code + Tailscale

If you use Tailscale (highly recommended), you can edit your phone's files from your PC using VS Code as if it were a local machine.

### 1. Configure SSH on your PC
Add this to your `~/.ssh/config` file:

```ssh
Host phone
    HostName 100.x.x.x  # Your Tailscale IP
    Port 8022
    User termux
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### 2. Connect
In VS Code: `F1` -> `Remote-SSH: Connect to Host...` -> `phone`.

## 🛠️ Helper Commands

| Command | Action |
| --- | --- |
| `moltis-up` | Starts SSH, prevents sleep, patches VS Code, and starts Gateway. |
| `moltis-update` | Pulls the latest static build from GitHub Actions. |
| `moltis-fix-vscode` | Manually repairs VS Code Server if a new version breaks it. |
| `moltis onboard` | Runs the initial setup/auth wizard. |

## 🧠 Why this version?

Standard Linux binaries don't run on Android because of library differences (Glibc vs Bionic).

This repository uses **GitHub Actions** to automatically cross-compile the official Moltis source code into a **Truly Static Musl Binary**. 
* **Native Speed**: No emulation layer (like proot).
* **Zero Bloat**: Takes up ~20MB instead of 1.5GB for a Linux distro.
* **Auto-Sync**: Checks every 24 hours for new Moltis versions and builds them automatically.

## Uninstall

```bash
rm $PREFIX/bin/moltis*
rm -rf ~/.moltis
```

## Troubleshooting

### VS Code "Exit Code 207" or "Node not found"
VS Code Remote-SSH often fails on the first connection because it expects a standard Linux environment.

1.  Connect from your PC and let it **fail**.
2.  On your phone, run: `moltis-fix-vscode`.
3.  Click **Retry** in VS Code. It will now work.

### Permission Denied
If you get a permission error when running `moltis`, you are likely using the outdated Play Store version of Termux. **Uninstall it and install the version from F-Droid.**

## License
MIT
