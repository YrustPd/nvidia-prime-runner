# Release Notes v1.0.0

What It Is
- A Bash CLI for PRIME offload on Debian/Ubuntu hybrid Intel+NVIDIA systems.
- Run apps or a shell with offload environment variables applied.

Install
- Local: `sudo ./scripts/install.sh`
- One-liner: `curl -fsSL https://raw.githubusercontent.com/YrustPd/nvidia-prime-runner/main/scripts/install.sh | sudo bash`
- Uninstall: `sudo ./scripts/uninstall.sh`

Verify
- `glxinfo -B | grep renderer`
- `glxgears -info | grep -E "GL_RENDERER|GL_VENDOR|GL_VERSION"`

Known Limitations
- PRIME offload is per-process; it does not switch the whole desktop.
- Nouveau has limited support; some apps may fail or perform poorly.

Safety Note
- Review scripts before running curl|bash, and prefer local installs when possible.

What's Included
- CLI (`nvidia-run`) with run/shell/verify modes
- Installer/uninstaller with .bashrc marker block and backups
- Test suite and CI workflow
- Man page and packaging helper
