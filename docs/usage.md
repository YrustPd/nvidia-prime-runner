# Usage

Running installed apps
- Default form: `nvidia-run <command> [args...]`
- Explicit form: `nvidia-run run <command> [args...]`
- Example: `nvidia-run run firefox-esr`

Running AppImages
- Use `nvidia-run run ./app.AppImage`
- Some distros require FUSE (e.g., `libfuse2`) for AppImages to launch.

Running scripts
- If the target is a non-executable file, `nvidia-run` runs it via Bash.
- Example: `nvidia-run run ./myscript.sh --flag`

Shell mode (PRIME offload shell)
- Use `nvidia-run shell` to open an interactive shell with PRIME offload enabled.
- Add `--no-banner` or set `NVIDIA_NO_BANNER=1` to suppress the banner.
- Exit the shell to return to normal environment.

Verify subcommand
- `nvidia-run verify` prints commands you can run to confirm renderer output.
- It does not execute checks for you.
- When offload is active, the renderer should report NVIDIA instead of Intel.
- For troubleshooting, see `docs/troubleshooting.md`.

Examples
- `nvidia-run run <cmd>`
- `nvidia-run <cmd>` (default)
- `nvidia-run shell --no-banner`
- `NVIDIA_NO_BANNER=1 nvidia-run shell`

Flags overview
- `--help` show help text
- `--version` show version info
- `--dry-run` print what would run and exit
- `--verbose` print env vars and command details
- `--no-banner` shell mode only; suppresses the banner hook

About --dry-run
- Prints the environment variables and the command that would be executed.
- Useful for validating paths and arguments without running anything.
