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
│  Build on ubuntu-24.04-arm (native ARM64)              │
│                      ↓                                  │
│  Create GitHub Release with binary                     │
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
| **Runner** | ubuntu-24.04-arm (GitHub ARM64) |
| **Target** | aarch64-unknown-linux-gnu |
| **Compatibility** | Termux, Android, Linux ARM64 |
| **Schedule** | 00:00, 12:00 UTC |

## Troubleshooting

**Build fails:** Check Actions tab for logs

**Release not created:** Enable workflow write permissions

**Binary won't run:** Ensure ARM64 device, check `ldd` for missing libs

## License

MIT
