# Moltis Termux Build

Static musl builds of [moltis](https://github.com/moltis-org/moltis) for Termux on Android.

## Why This Exists

Official moltis releases are x86_64 glibc binaries. This repo builds **static musl ARM64** binaries on native ARM64 runners - they work in Termux without proot and have zero external dependencies.

## Installation

### One-Liner Install

```bash
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"
DOWNLOAD_URL="https://github.com/Muxd21/moltis-termux/releases/download/${LATEST}-termux/moltis-${VERSION}-musl-arm64.tar.gz"
echo -e "${YELLOW}Downloading...${NC}"

if ! curl -sL "$DOWNLOAD_URL" -o "moltis-${VERSION}-musl-arm64.tar.gz"; then
    echo -e "${RED}Error: Download failed${NC}"
    echo "Check: https://github.com/Muxd21/moltis-termux/releases"
    exit 1
fi

tar -xzf "moltis-${VERSION}-musl-arm64.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis $PREFIX/bin/moltis
rm -rf moltis-termux "moltis-${VERSION}-musl-arm64.tar.gz"
```

### Quick Install Script

```bash
bash <(curl -sL https://raw.githubusercontent.com/Muxd21/moltis-termux/main/install.sh)
```

## Usage

```bash
moltis --help
```

## Build Schedule

Checks for new releases **4 times daily** and auto-builds.

## Binary Details

| Property | Value |
|----------|-------|
| **Architecture** | ARM64 (aarch64) |
| **Target** | aarch64-unknown-linux-musl |
| **Linking** | Static (zero dependencies) |
| **Runner** | ubuntu-24.04-arm (native ARM64) |
| **Size** | ~50-80 MB |

## Compatibility

- ✅ Termux on Android (ARM64)
- ✅ Alpine Linux ARM64
- ✅ Any musl-based Linux ARM64
- ❌ x86_64 PCs
- ❌ 32-bit ARM

## Why Musl Works in Termux

Static musl binaries bundle all libc code, making them compatible with Android's Bionic libc - no glibc required, no proot needed.

## License

MIT (same as moltis-org/moltis)

## Disclaimer

Unofficial build. Official releases: [moltis-org/moltis/releases](https://github.com/moltis-org/moltis/releases)
