# Troubleshooting

Common issues and solutions when using Moltis Antigravity on Termux.

---

## VS Code Remote-SSH: "Could not establish connection" / `cxx_abstract` error

### Cause

VS Code Remote-SSH downloads a generic Linux `node` binary compiled for **glibc**, which is incompatible with Android's **Bionic** C library. The binary fails with linker errors like `File Not Found` (despite the file existing) or `cxx_abstract`.

### Solution

Run the self-healing patcher:

```bash
moltis-fix-vscode --force
```

This will:
1. Back up the glibc `node` binary
2. Replace it with a Bionic wrapper that execs Termux's native `node`
3. Graft native `pty.node` bindings for terminal support
4. Configure `.env` for proper terminal environment

**If VS Code updates auto-download a new server version**, the watchdog service will auto-patch it:

```bash
sv status vscode-patcher   # Should show "run:"
```

If the watchdog isn't running, start it: `sv up vscode-patcher`

---

## VS Code Terminal: "Pty Host has terminated" / Orange indicator

### Cause

The bundled `pty.node` C++ binding was compiled for musl/glibc, not Bionic. The Pty Host process crashes when trying to load it.

### Solution

```bash
moltis-fix-vscode --force
```

This grafts a natively-compiled `pty.node` from your Termux environment. If that doesn't work, check the diagnostic:

```bash
bash diagnose-pty.sh
```

Look at the "Global node-pty" section — if it shows `NOT FOUND`, install it manually:

```bash
export CPPFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
npm install -g node-pty --cc=clang --cxx=clang++
moltis-fix-vscode --force
```

### Terminal Environment

Ensure your environment exports the correct terminal capabilities:

```bash
export TERM=xterm-256color
export COLORTERM=truecolor
export PATH="$PREFIX/bin:$PATH"
```

These are automatically added to `.bashrc` by the installer.

---

## Gateway won't start: "gateway already running" or "Port is already in use"

```
Gateway failed to start: gateway already running (pid XXXXX); lock timeout after 5000ms
Port 18789 is already in use.
```

### Cause

A previous gateway process was terminated abnormally, leaving behind a lock file or a zombie process. This typically happens when:

- SSH connection drops, leaving the gateway process orphaned
- `Ctrl+Z` (suspend) was used instead of `Ctrl+C` (terminate), leaving the process alive in the background
- Termux was force-killed by Android

> **Note**: Always use `Ctrl+C` to stop the gateway. `Ctrl+Z` only suspends the process — it does not terminate it.

### Solution

**Step 1: Use `moltis-stop` to cleanly shut down all services**

```bash
moltis-stop
```

**Step 2: If that doesn't work, find and kill remaining processes**

```bash
ps aux | grep -E "node|moltis" | grep -v grep
kill -9 <PID>
```

**Step 3: Remove lock files**

```bash
rm -rf $PREFIX/tmp/moltis-*
```

**Step 4: Restart**

```bash
moltis-up
```

### If it still doesn't work

Fully close and reopen the Termux app, then run `moltis-up`. Rebooting the phone will reliably clear all state.

---

## SSH connection failed: "Connection refused"

```
ssh: connect to host 100.x.x.x port 8022: Connection refused
```

### Cause

The Termux SSH server (`sshd`) is not running. Closing the Termux app or rebooting the phone stops sshd.

### Solution

Open the Termux app on the phone and run `sshd`. Or use `moltis-up` which starts sshd automatically.

```bash
moltis-up
```

If connecting via ADB:

```bash
adb shell input text 'sshd'
adb shell input keyevent 66
```

The IP address may have changed. Verify:

```bash
moltis-status
# or manually:
ip addr show tailscale0 | grep 'inet '
ifconfig wlan0 | grep 'inet '
```

> The boot hook at `~/.termux/boot/start-services` automatically starts sshd when Termux opens.

---

## SSH connection drops when switching WiFi ↔ 5G

### Cause

Android tears down the TCP connection when switching network interfaces. Without keepalive, the SSH session hangs.

### Solution

**On the phone (already configured by installer)**:

The `sshd_config` at `$PREFIX/etc/ssh/sshd_config` includes:
```
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 10
```

**On your laptop** — add to `~/.ssh/config`:

```ssh
Host moltis
    HostName 100.x.x.x  # Your Tailscale IP
    User termux
    Port 8022
    ServerAliveInterval 15
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/moltis-%r@%h:%p
    ControlPersist 5m
```

The `ControlMaster`/`ControlPersist` settings reuse connections, making reconnections near-instant.

---

## Services killed by Android OOM Killer

### Cause

Android's kernel aggressively kills background processes to save battery, even if they're doing useful work.

### Solution

1. **Disable Phantom Process Killer** (requires ADB once):
   ```bash
   adb shell "settings put global phantom_process_handling false"
   ```

2. **Disable Battery Optimization** for both Termux and Tailscale in Android Settings → Apps → Battery → Unrestricted.

3. **Use `moltis-up`** which automatically acquires a wakelock:
   ```bash
   moltis-up   # Runs termux-wake-lock + elevates process priority
   ```

4. **Check service status** — runit auto-restarts crashed services:
   ```bash
   moltis-status
   ```

---

## Gateway disconnected: "gateway not connected"

```
send failed: Error: gateway not connected
disconnected | error
```

### Cause

The gateway process has stopped or the SSH session was disconnected.

### Solution

Check the SSH session where the gateway was running. If the session was disconnected, reconnect via SSH and start the gateway:

```bash
moltis-up
```

If you get a "gateway already running" error, see the [Gateway won't start](#gateway-wont-start-gateway-already-running-or-port-is-already-in-use) section above.

---

## `moltis --version` fails

### Cause

Environment variables are not loaded.

### Solution

```bash
source ~/.bashrc
```

Or fully close and reopen the Termux app.

---

## "Cannot find module bionic-compat.js" error

```
Error: Cannot find module '/data/data/com.termux/files/home/.moltis-lite/patches/bionic-compat.js'
```

### Cause

The `NODE_OPTIONS` environment variable in `~/.bashrc` still references the old installation path (`.moltis-lite`). This happens when updating from an older version.

### Solution

Run the updater to refresh everything:

```bash
moltis-update
source ~/.bashrc
```

---

## "systemctl --user unavailable" during update

```
Gateway service check failed: Error: systemctl --user unavailable: spawn systemctl ENOENT
```

### Cause

After running `moltis update`, moltis tries to restart the gateway using `systemctl`. Since Termux uses **runit** (not systemd), `systemctl` doesn't exist.

### Impact

**This error is harmless.** The update has completed successfully — only the automatic service restart failed.

### Solution

Simply restart using runit:

```bash
moltis-stop && moltis-up
```

---

## "not supported on android" error

```
Gateway status failed: Error: Gateway service install not supported on android
```

### Cause

The `process.platform` override in `bionic-compat.js` is not being applied.

### Solution

Check if the environment is loaded:

```bash
echo $NODE_OPTIONS
source ~/.bashrc
node -e "console.log(process.platform)"
```

If it prints `android`, the bionic-compat module needs updating. Run:

```bash
moltis-update
```

---

## Quick Diagnostic

Run the full system diagnostic:

```bash
bash diagnose-pty.sh
```

This checks:
- Terminal environment variables
- SSH configuration
- VS Code server binary patching status
- node-pty loading
- Runit service status
- Network connectivity
- Android OOM mitigation
- Recent error logs
