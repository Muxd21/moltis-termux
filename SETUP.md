# Moltis Termux - Setup Guide

## Quick Setup

### 1. Create Repository

1. Create a new GitHub repository named `moltis-termux`
2. Copy `.github/workflows/build-termux.yml` to your repo
3. Copy `install.sh` and `README.md`

### 2. Update Placeholders

In all files, replace `YOUR_USERNAME` with your GitHub username:
- `.github/workflows/build-termux.yml`
- `README.md`
- `install.sh`

### 3. Enable Actions

1. **Settings** → **Actions** → **General**
2. Enable "Allow all actions"
3. **Workflow permissions** → "Read and write permissions"

### 4. Test Build

Go to **Actions** → Select workflow → "Run workflow"

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  Schedule (4x daily) or Manual Trigger                  │
│                      ↓                                  │
│  Check moltis-org/moltis for new release               │
│                      ↓                                  │
│  Clone source at release tag                           │
│                      ↓                                  │
│  Build on alpine container (ARM64 runner)              │
│  Target: aarch64-unknown-linux-musl                    │
│                      ↓                                  │
│  Create GitHub Release with static binary              │
└─────────────────────────────────────────────────────────┘
```

## Install in Termux

```bash
# One-liner
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/moltis-termux/main/install.sh)
```

## Build Details

| Item | Value |
|------|-------|
| **Runner** | ubuntu-24.04-arm (native ARM64) |
| **Container** | Alpine Linux |
| **Target** | aarch64-unknown-linux-musl |
| **Linking** | Static (no dependencies) |
| **Schedule** | 00:00, 06:00, 12:00, 18:00 UTC |

## Why This Works

- **Native ARM64 runner** - No emulation, fast builds
- **Static musl** - Bundles libc, compatible with Android Bionic
- **No NDK needed** - Avoids Android toolchain complexity
- **Zero dependencies** - Works out of the box in Termux

## Troubleshooting

**Build fails:** Check Actions tab for logs

**Release not created:** Enable workflow write permissions

**Binary won't run:** Ensure ARM64 device (`uname -m` should show `aarch64`)

## License

MIT
