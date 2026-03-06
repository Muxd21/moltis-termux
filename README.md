# Moltis

Personal AI gateway.

## Termux Install (Android ARM64)

**One-liner:**
```bash
curl -sL https://github.com/Muxd21/moltisdroid/releases/latest/download/moltis-musl-arm64.tar.gz | tar -xz && chmod +x moltis-termux/moltis && mv moltis-termux/moltis $PREFIX/bin/ && rm -rf moltis-termux
```

**Starter:**
```bash
moltis
```

---

## Auto-Builds

This repo builds **static musl ARM64** binaries for Termux 4x daily from [moltis-org/moltis](https://github.com/moltis-org/moltis) releases.

- **No proot** - Native ARM64 build
- **No dependencies** - Statically linked
- **Auto-updates** - Checks for new releases at 00:00, 06:00, 12:00, 18:00 UTC

## Manual Download

1. Go to [Releases](https://github.com/Muxd21/moltisdroid/releases)
2. Find `vX.Y.Z-termux` tag
3. Download `moltis-*-musl-arm64.tar.gz`

## Build Workflow

Triggered automatically or manually via [Actions](https://github.com/Muxd21/moltisdroid/actions/workflows/build-termux.yml).

---

**License:** MIT (same as moltis-org/moltis)
