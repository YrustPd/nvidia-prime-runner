# Troubleshooting

Banner not showing
- The banner only appears when `NVIDIA_SHELL` is set (use `nvidia-run shell`).
- Your .bashrc may manage banners or clear/fastfetch behavior; ensure the marker block exists.
- Use `--no-banner` or `NVIDIA_NO_BANNER=1` to suppress the banner intentionally.

PRIME offload not working
- Check drivers: `lspci -nnk | grep -A3 -E "VGA|3D"`
- Verify renderer under offload: `DRI_PRIME=1 glxinfo -B | grep renderer`
- Compare with and without `nvidia-run` to confirm switching.

Nouveau limitations
- Nouveau may not provide full PRIME offload capabilities or expected performance.
- Some apps may fail due to GL configuration differences; run them on Intel if needed.
- The proprietary NVIDIA driver is recommended for best results.

AppImage FUSE error
- Some AppImages require FUSE; ensure `libfuse2` is installed and working.
- If FUSE is unavailable, extract the AppImage and run the binary directly.

Wayland vs X11
- PRIME offload behavior can differ between Wayland and X11 sessions.
- If issues persist, test under X11 for comparison.

Safety and uninstall
- The installer adds a marker block in `.bashrc` and creates a timestamped backup.
- The uninstaller removes only the content between markers.

Limits
- For scope limitations, see `docs/constraints.md`.
