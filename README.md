# Moltis Termux Build

Automated builds of [moltis](https://github.com/moltis-org/moltis) for Termux on Android (aarch64-unknown-linux-musl).

## Why This Exists

The official moltis releases ship binaries targeting `-unknown-linux-gnu` (glibc), which are incompatible with Termux's Bionic libc. This repository automatically builds static musl binaries that work natively in Termux without requiring proot or chroot.

## Installation

### One-Liner Install

```bash
# Get the latest release tag from moltis-org/moltis
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"

# Download and install
curl -LO "https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-termux/moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
tar -xzf "moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis $PREFIX/bin/moltis
rm -rf moltis-termux "moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
```

### Quick Install (Latest)

```bash
bash <(curl -sL https://raw.githubusercontent.com/Muxd21/moltisdroid/main/install.sh)
```

## Usage

After installation, run moltis as usual:

```bash
moltis --help
```

## Build Schedule

This repository checks for new releases from [moltis-org/moltis](https://github.com/moltis-org/moltis) **4 times a day** (at 00:00, 06:00, 12:00, and 18:00 UTC) and automatically builds new musl binaries when a new release is detected.

## Manual Trigger

You can manually trigger a build using the "Run workflow" button on the [Actions tab](https://github.com/Muxd21/moltisdroid/actions).

## Binary Details

- **Target**: `aarch64-unknown-linux-musl`
- **Linking**: Static (no external dependencies)
- **Compatibility**: Termux on Android (ARM64), Alpine Linux, any musl-based system

## Troubleshooting

### "Permission denied"

Make sure the binary is executable:

```bash
chmod +x $PREFIX/bin/moltis
```

### "Binary not found"

Ensure `$PREFIX/bin` is in your PATH:

```bash
echo 'export PATH=$PREFIX/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## License

MIT (same as moltis-org/moltis)

## Disclaimer

This is an unofficial build. For official releases, see [moltis-org/moltis/releases](https://github.com/moltis-org/moltis/releases).
