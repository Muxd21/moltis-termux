# Termux SSH Setup Guide

Connect to your Moltis Antigravity workstation from your computer via SSH.

## Prerequisites

- **Same network**: Both phone and computer on the same Wi-Fi, OR
- **Tailscale**: Both devices connected to your Tailscale mesh network (recommended for anywhere access)

## Step 1: Install openssh (already done by Moltis installer)

The installer handles this, but if you need to do it manually:

```bash
pkg install -y openssh
```

## Step 2: Set Password

```bash
passwd
```

Enter a password (e.g., `1234`):

```
New password: 1234          ← type
Retype new password: 1234   ← type the same password again
```

> It's normal that nothing shows on screen while typing the password. Just type it and press Enter.

## Step 3: Start SSH Server

> **Important**: Run `sshd` directly in the Termux app on your phone first.

```bash
moltis-up   # This starts sshd + all Moltis services + wakelock
```

Or if you only need SSH:

```bash
sshd
```

If the prompt (`$`) returns with no error message, it's working.

## Step 4: Find the Phone's IP Address

```bash
moltis-status
```

This shows both your Tailscale IP (`100.x.x.x`) and WiFi IP.

Or manually:

```bash
# Tailscale IP (accessible from anywhere)
ip addr show tailscale0 | grep 'inet '

# WiFi IP (same network only)
ifconfig wlan0 | grep 'inet '
```

## Step 5: Connect via SSH from Computer

### Option A: Quick connect

```bash
ssh -p 8022 100.x.x.x        # Tailscale IP
# or
ssh -p 8022 192.168.x.x      # WiFi IP
```

### Option B: Persistent SSH config (Recommended)

Add to your laptop's `~/.ssh/config`:

```ssh
Host moltis
    HostName 100.x.x.x  # Your Tailscale IP
    User termux
    Port 8022
    # Antigravity connection stability
    ServerAliveInterval 15
    ServerAliveCountMax 3
    # Reuse connections for instant reconnect
    ControlMaster auto
    ControlPath ~/.ssh/moltis-%r@%h:%p
    ControlPersist 5m
```

Then connect simply with:

```bash
ssh moltis
```

- `Are you sure you want to continue connecting?` → type `yes`
- `Password:` → enter the password you set in Step 2

### Option C: Key-based auth (no password)

```bash
# On your computer:
ssh-copy-id -p 8022 termux@100.x.x.x
```

Now `ssh moltis` works without a password.

## Step 6: VS Code Remote-SSH

Once SSH works, VS Code Remote-SSH will connect automatically:

1. Install the **Remote - SSH** extension in VS Code
2. Open Command Palette → `Remote-SSH: Connect to Host...`
3. Select `moltis` (if you configured the SSH config) or enter `termux@100.x.x.x -p 8022`
4. The Moltis watchdog service will **automatically patch** the VS Code server for Bionic compatibility

If you see PTY or Node errors, run on the phone:

```bash
moltis-fix-vscode --force
```

## SSH Configuration Details

The Moltis installer deploys a hardened `sshd_config` at `$PREFIX/etc/ssh/sshd_config`:

| Setting | Value | Purpose |
|---------|-------|---------|
| Port | 8022 | Non-standard port for Android |
| TCPKeepAlive | yes | Keeps connection alive |
| ClientAliveInterval | 30 | Pings client every 30 seconds |
| ClientAliveCountMax | 10 | Tolerates 10 missed pings (5 min) |
| AllowTcpForwarding | yes | VS Code port tunneling |
| GatewayPorts | yes | External port access |
| Compression | yes | Optimized for mobile data |
| PermitTTY | yes | VS Code terminal support |

## Notes

- Termux uses SSH port **8022** (not the standard Linux port 22)
- If you close the Termux app, the SSH server stops. The boot hook at `~/.termux/boot/start-services` auto-restarts it
- Use `moltis-up` instead of bare `sshd` — it also starts the wakelock and all services
- If switching between WiFi and mobile data, the `ServerAliveInterval` keeps the connection from hanging
