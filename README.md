# nvidia-prime-runner
Run apps on the discrete NVIDIA GPU (PRIME offload) with one command.

nvidia-prime-runner targets hybrid Intel+NVIDIA laptops on Debian/Ubuntu. It applies per-process PRIME offload and does not switch the entire desktop session.

![CI](https://github.com/YrustPd/nvidia-prime-runner/actions/workflows/ci.yml/badge.svg)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0.html)

---

## Quick Start

### Install (one-liner)
```bash
curl -fsSL https://raw.githubusercontent.com/YrustPd/nvidia-prime-runner/main/scripts/install.sh | sudo bash
```
Installs `nvidia-run` to `/usr/local/bin` and adds a `.bashrc` marker block for the banner.
Security note: review scripts before running curl|bash, and prefer local installs when possible.

### Run an app
```bash
nvidia-run firefox-esr
```

### Start a PRIME offload shell
```bash
nvidia-run shell
```

### Verify renderer
```bash
nvidia-run verify
glxinfo -B | grep renderer
```

### Uninstall (one-liner)
```bash
curl -fsSL https://raw.githubusercontent.com/YrustPd/nvidia-prime-runner/main/scripts/uninstall.sh | sudo bash
```

### Local install (preferred)
```bash
sudo ./scripts/install.sh
```

### Local uninstall
```bash
sudo ./scripts/uninstall.sh
```

---

## Commands Overview

Default run:
`nvidia-run <command> [args...]` runs a command with PRIME offload.

Subcommands:
- `run <command|file> [args...]` Explicit run mode (same behavior as default).
- `shell` Start an interactive shell with PRIME offload enabled.
- `verify` Print verification commands for renderer checks.
- `help` or `--help` Show usage.
- `version` or `--version` Show the version string.

Flags:
- `--dry-run` Print environment variables and the command that would run.
- `--verbose` Print environment variables and execution details.
- `--no-banner` Shell mode only; suppresses the banner hook.

---

## How It Works

- Sets `DRI_PRIME=1`, `__NV_PRIME_RENDER_OFFLOAD=1`, and `__GLX_VENDOR_LIBRARY_NAME=nvidia` for the launched process.
- Shell mode sets `NVIDIA_SHELL=1`; the banner can be suppressed with `NVIDIA_NO_BANNER=1`.
- PRIME offload is per-process; the desktop session remains on the integrated GPU.

---

## Requirements and Dependencies

- Hybrid Intel+NVIDIA hardware with PRIME offload support.
- Working Mesa PRIME setup and GPU drivers.
- `mesa-utils` recommended for `glxinfo` and `glxgears`.
- Driver note: nouveau has limitations; proprietary NVIDIA drivers often work better, but results vary by system.

---

## Verification

Baseline (Intel):
```bash
glxinfo -B | grep renderer
```

With offload (NVIDIA):
```bash
nvidia-run glxinfo -B | grep renderer
# or
DRI_PRIME=1 glxinfo -B | grep renderer
```

Optional detail:
```bash
nvidia-run glxgears -info | grep -E "GL_RENDERER|GL_VENDOR|GL_VERSION"
```

Example NVIDIA renderer line: `GL_RENDERER = NVD7` (exact string varies by GPU).

---

## Installation Details

- The installer creates `~/.bashrc.backup-YYYYmmdd-HHMMSS` before changes.
- Marker lines:
  - `# >>> NVIDIA-RUN START >>>`
  - `# <<< NVIDIA-RUN END <<<`

---

## Documentation

- `docs/usage.md`
- `docs/troubleshooting.md`
- `docs/constraints.md`
- `docs/developer.md`
- `docs/release.md`
- `docs/release-notes-v1.0.0.md`

---

## Developer

- `make lint`, `make test`, `make install`, `make uninstall`, `make package`
- Man page: `man/nvidia-run.1`
- Packaging: `./scripts/package.sh` writes `dist/nvidia-prime-runner-<version>.tar.gz`

---

## License

- GNU Affero General Public License v3.0 (AGPL-3.0): https://www.gnu.org/licenses/agpl-3.0.html

---

## Security

- See `SECURITY.md` for reporting vulnerabilities.

## Code of Conduct

- See `CODE_OF_CONDUCT.md` for community guidelines.
