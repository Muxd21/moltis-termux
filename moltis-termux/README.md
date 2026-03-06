# Moltis Termux Build

Native ARM64 builds of [moltis](https://github.com/moltis-org/moltis) for Termux on Android.

## Why This Exists

Official moltis releases are built for x86_64. This repository builds **native ARM64** binaries on GitHub's ARM64 runners, producing glibc-compatible binaries that work in Termux without proot.

## Installation

### One-Liner Install

```bash
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"
curl -LO "https://github.com/YOUR_USERNAME/moltis-termux/releases/download/${LATEST}-termux/moltis-${VERSION}-linux-arm64.tar.gz"
tar -xzf "moltis-${VERSION}-linux-arm64.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis $PREFIX/bin/moltis
rm -rf moltis-termux "moltis-${VERSION}-linux-arm64.tar.gz"
```

### Quick Install Script

```bash
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/moltis-termux/main/install.sh)
```

## Usage

```bash
moltis --help
```

## Build Schedule

Checks for new releases **twice daily** (00:00, 12:00 UTC) and auto-builds.

## Binary Details

| Property | Value |
|----------|-------|
| **Architecture** | ARM64 (aarch64) |
| **OS** | Linux (Android compatible) |
| **Linking** | Dynamic (glibc/Bionic) |
| **Runner** | ubuntu-24.04-arm (native ARM64) |

## Compatibility

- ✅ Termux on Android (ARM64 devices)
- ✅ Linux ARM64 servers
- ✅ Raspberry Pi 4/5 (64-bit OS)
- ❌ x86_64 PCs

## License

MIT (same as moltis-org/moltis)

## Disclaimer

Unofficial build. Official releases: [moltis-org/moltis/releases](https://github.com/moltis-org/moltis/releases)
