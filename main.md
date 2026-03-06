# Moltis Termux Build Repository

Automated GitHub Actions workflow that builds static Bionic binaries of [moltis](https://github.com/moltis-org/moltis) for Termux on Android.

## Features

- ✅ **Automatic builds** - Checks for new releases 4 times daily
- ✅ **Termux compatible** - Static Bionic binary (no glibc required)
- ✅ **No proot needed** - Runs natively in Termux
- ✅ **One-liner install** - Simple installation script

## Quick Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/Muxd21/moltisdroid/main/install.sh)
```

## How It Works

1. Workflow checks moltis-org/moltis releases via GitHub API
2. When a new release is detected, clones the source at that tag
3. Builds with `aarch64-unknown-linux-Bionic` target (static linking)
4. Uploads binary as a GitHub Release asset

## Repository Structure

```
moltis-termux/
├── .github/
│   └── workflows/
│       └── build-Bionic.yml    # Main CI workflow
├── install.sh                 # One-liner installer
├── README.md                  # User documentation
├── SETUP.md                   # Setup guide for maintainers
└── LICENSE                    # MIT license
```

## For Maintainers

See [SETUP.md](SETUP.md) for detailed setup instructions.

## Binary Compatibility

| Target | Works | Notes |
|--------|-------|-------|
| Termux (Android ARM64) | ✅ | Primary target |
| Alpine Linux (ARM64) | ✅ | Static Bionic |
| Ubuntu/Debian (glibc) | ❌ | Use official .deb |
| x86_64 Linux | ❌ | Different arch |

## Schedule

Builds run at:
- 00:00 UTC
- 06:00 UTC
- 12:00 UTC
- 18:00 UTC

## Manual Trigger

Use GitHub Actions "Run workflow" button to trigger an immediate build.

## Disclaimer

This is an unofficial build repository. Official releases are available at [moltis-org/moltis/releases](https://github.com/moltis-org/moltis/releases).

## License

MIT License - see [LICENSE](LICENSE)
