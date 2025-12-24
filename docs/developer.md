# Developer Notes

Tests and Sandboxing
- The test suite creates a temporary sandbox and never touches your real HOME or /usr/local.
- Run all tests with `./tests/run-tests.sh` or a single test with `./tests/run-tests.sh install`.
- No NVIDIA hardware is required; tests avoid running GPU commands.
- Tests assume GNU coreutils/awk/stat (Debian/Ubuntu default).

Sandbox Override Environment Variables
- `TEST_MODE=1` bypasses root checks for tests only.
- `INSTALL_BIN_DIR` or `INSTALL_PREFIX` redirect install targets to the sandbox.
- `TARGET_HOME` points .bashrc edits at the sandboxed HOME directory.

Offload Environment Variables
- The CLI sets `DRI_PRIME=1`, `__NV_PRIME_RENDER_OFFLOAD=1`, and `__GLX_VENDOR_LIBRARY_NAME=nvidia` for offload.
- Shell mode additionally sets `NVIDIA_SHELL=1`, and `NVIDIA_NO_BANNER=1` when requested.

Rationale
- These overrides keep tests safe and deterministic while preserving default install behavior.
