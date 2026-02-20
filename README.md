# moltis on Android

<img src="docs/images/moltis_android.jpg" alt="moltis on Android">

![Android 7.0+](https://img.shields.io/badge/Android-7.0%2B-brightgreen)
![Termux](https://img.shields.io/badge/Termux-Required-orange)
![No proot](https://img.shields.io/badge/proot--distro-Not%20Required-blue)
![License MIT](https://img.shields.io/github/license/moltis-org/moltis-android)

Because Android deserves a shell.

## Why?

An Android phone is a great environment for running an moltis server:

- **Sufficient performance** — Even models from a few years ago have more than enough specs to run moltis
- **Repurpose old phones** — Put that phone sitting in your drawer to good use. No need to buy a mini PC
- **Low power + built-in UPS** — Runs 24/7 on a fraction of the power a PC would consume, and the battery keeps it alive through power outages

## Native Moltis Binary

The standard approach to running native tools on Android requires installing proot-distro with Ubuntu, adding 700MB-1GB of overhead. Because official Moltis binary releases (`aarch64-unknown-linux-gnu`) rely on `glibc`, they cannot execute natively on Android's custom `Bionic` libc environment out of the box ("cannot execute: required file not found"). 

**Moltis on Android eliminates this by automatically compiling a native standalone Rust binary for Termux (`aarch64-unknown-linux-musl`) inside a high-performance GitHub Actions workflow and streaming it to your device**. This gives you full native performance at a fraction of the cost, with no `cargo` compiling locally required!

| | Standard (proot-distro) | Pure Termux (Moltis Native) |
|---|---|---|
| Storage overhead | 1-2GB (Ubuntu + packages) | ~20MB (Static Binary) |
| Performance | Slower (proot layer) | Maximum (compiled for your CPU) |
| Setup steps | Install distro, configure Linux... | Run one script |

## Requirements

- Android 7.0 or higher (Android 10+ recommended)
- Wi-Fi or mobile data connection

## Step-by-Step Setup

1. [Enable Developer Options and Stay Awake](#step-1-enable-developer-options-and-stay-awake)
2. [Install Termux](#step-2-install-termux)
3. [Initial Termux Setup and Background Kill Prevention](#step-3-initial-termux-setup-and-background-kill-prevention)
4. [Install Moltis Native Binary](#step-4-install-moltis-native-binary)
5. [Start moltis Setup](#step-5-start-moltis-setup)
6. [Start moltis](#step-6-start-moltis)

### Step 1: Enable Developer Options and Stay Awake

moltis runs as a server, so the screen turning off can cause Android to throttle or kill the process. Keeping the screen on while charging ensures stable operation.

**A. Enable Developer Options**
1. Go to **Settings** > **About phone**
2. Tap **Build number** 7 times

**B. Stay Awake While Charging**
1. Go to **Settings** > **Developer options**
2. Turn on **Stay awake**

### Step 2: Install Termux

> **Important**: The Play Store version of Termux is discontinued and will not work. You must install from F-Droid.

1. Open your phone's browser and go to [f-droid.org](https://f-droid.org)
2. Search for `Termux`, download the APK. Allow "Install from unknown sources".

### Step 3: Initial Termux Setup and Background Kill Prevention

Open the Termux app and paste the following command. It updates repos and prevents Android from killing it:

```bash
pkg update -y && pkg upgrade -y && termux-wake-lock
```

> Once `termux-wake-lock` runs, a notification pins in the status bar and prevents Android from killing the Termux process.

**Disable Battery Optimization for Termux**
1. Go to Android **Settings** > **Battery**
2. Open **Battery optimization**
3. Find **Termux** and set it to **Not optimized** (or **Unrestricted**)

### Step 4: Install Moltis Native Binary

> **Tip: Use SSH for easier typing**
> From this step on, you can type commands from your computer keyboard instead of the phone screen. Connect via SSH:
> ```bash
> pkg install -y openssh && passwd && sshd
> ssh -p 8022 <phone-ip>
> ```

Install Moltis directly utilizing the official `moltis-termux` android payload:

```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

Once downloaded, the installer automatically drops the executable into your native path (`$PREFIX/bin/moltis`) and executes flawlessly!

### Step 5: Start moltis Setup

Run the initialization wizard to setup memory, auth, and identity:

```bash
moltis onboard
```

Follow the on-screen instructions to complete the initial setup.

### Step 6: Start moltis

Once setup is complete, start the moltis gateway:

> **Important**: Run `moltis` directly in the Termux app on your phone, not via SSH. If you run it over SSH, the gateway will stop when the SSH session disconnects.

```bash
moltis
```

> To stop the gateway, press `Ctrl+C`. Do not use `Ctrl+Z`.

### Access the Dashboard from Your PC

To manage moltis from your PC browser, see the [Termux SSH Setup Guide](docs/termux-ssh-guide.md) to set up a Secure tunnel. 

Run the following in Termux to find your phone IP (look under `wlan0` inet):
```bash
ifconfig
```

Open a new terminal on your PC and establish your SSH tunnel to Moltis:
```bash
ssh -N -L 13131:127.0.0.1:13131 -p 8022 <phone-ip>
```
Visit `http://localhost:13131/` in your browser!

## Update

When a new version of Moltis is released, simply re-run the installer. It will seamlessly swap out the binary preserving your configurations:
```bash
curl -fsSL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh | bash
```

## Uninstall

If you wish to remove Moltis, you simply delete the executable and data:
```bash
rm $PREFIX/bin/moltis
rm -rf ~/.moltis
```

## VS Code Remote SSH (Tailscale)

Connect to your phone's development environment seamlessly from your PC:

1.  Open your SSH config on your PC (usually ~/.ssh/config).
2.  Add this block (replace with your IP):

\\\ssh
Host phone
    HostName 100.76.136.73
    Port 8022
    User termux
\\\

3.  In VS Code, press \F1\ -> \Remote-SSH: Connect to Host...\ -> Select \phone\.

## Useful Commands

| Command | Action |
| --- | --- |
| \moltis-up\ | Starts SSH (sshd), prevents sleep, and starts the gateway |
| \moltis-update\ | Pulls the latest static binary from GitHub |
| \moltis --version\ | Checks your current version |
