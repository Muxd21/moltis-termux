# Moltis Termux - Setup Guide

This repository provides automated musl builds of moltis for Termux on Android.

## Quick Start

### Step 1: Fork/Clone This Repository

1. Fork this repository to your GitHub account
2. Or create a new repository named `moltis-termux`

### Step 2: Copy the Workflow

Copy the `.github/workflows/build-musl.yml` file to your repository.

### Step 3: Update the Workflow

In `build-musl.yml`, update the release creation step to use your username:

```yaml
# Change YOUR_USERNAME to your GitHub username
```

### Step 4: Enable GitHub Actions

1. Go to your repository's **Settings** → **Actions** → **General**
2. Ensure "Allow all actions and reusable workflows" is enabled
3. Go to **Actions** tab and enable workflows if needed

### Step 5: Manual Trigger (Optional)

You can manually trigger a build:
1. Go to **Actions** tab
2. Select "Build Musl Binary for Termux"
3. Click "Run workflow"
4. Select branch (main)
5. Click "Run workflow"

## Automatic Builds

The workflow runs automatically:
- **Schedule**: 4 times daily (00:00, 06:00, 12:00, 18:00 UTC)
- **Trigger**: When a new release is detected from moltis-org/moltis

## Installation in Termux

After a successful build, install in Termux with:

```bash
# One-liner (replace YOUR_USERNAME)
LATEST=$(curl -s https://api.github.com/repos/moltis-org/moltis/releases/latest | jq -r '.tag_name')
VERSION="${LATEST#v}"
curl -LO "https://github.com/Muxd21/moltisdroid/releases/download/${LATEST}-termux/moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
tar -xzf "moltis-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
chmod +x moltis-termux/moltis
mv moltis-termux/moltis $PREFIX/bin/moltis
```

## Customization

### Change Build Schedule

Edit the cron expression in `.github/workflows/build-musl.yml`:

```yaml
on:
  schedule:
    - cron: '0 0,6,12,18 * * *'  # Change this line
```

### Add More Architectures

Add additional targets to the build matrix:

```yaml
strategy:
  matrix:
    target:
      - aarch64-unknown-linux-musl
      - x86_64-unknown-linux-musl  # Add this for x86_64
```

## Troubleshooting

### Build Fails

1. Check the **Actions** tab for error logs
2. Common issues:
   - Missing dependencies (ensure Alpine packages are installed)
   - Source repo changes (check moltis-org/moltis releases)

### Release Not Created

Ensure your repository has write permissions enabled:
- Settings → Actions → General → Workflow permissions
- Select "Read and write permissions"

## License

MIT - Same as moltis-org/moltis
