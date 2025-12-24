# Contributing

Thanks for improving nvidia-prime-runner. Keep changes small, focused, and well-documented.

Guidelines
- Use Bash strict mode for scripts (e.g., `set -euo pipefail`).
- Prioritize idempotency and safety; no destructive edits to user files.
- Preserve user .bashrc customizations (order, banners, clear/fastfetch, etc.).
- Avoid heavy dependencies; prefer standard tools available on Debian/Ubuntu.
- Add or update tests for behavior changes.
- Update docs when behavior, flags, or UX changes.
- Do not break default install/uninstall behavior when adding test overrides.
- Update the man page (`man/nvidia-run.1`) when CLI behavior or flags change.

Style
- Keep scripts readable with consistent naming and clear error messages.
- Prefer small, testable functions and explicit return codes.

Docs and Tests
- Update `docs/` for user-facing changes.
- Expand `tests/` to cover install/uninstall, usage, and idempotency.

CI Expectations
- Changes must pass shellcheck and the test suite.
- Shellcheck: `shellcheck bin/nvidia-run scripts/install.sh scripts/uninstall.sh tests/*.sh`

Developer Tools
- `make lint` and `make test` are available for convenience.
- Pre-commit is optional; see `.pre-commit-config.yaml`.

Running Tests
- Full suite: `./tests/run-tests.sh`
- Single test: `./tests/run-tests.sh install`
- Tests use sandboxed paths; they never touch the real HOME or /usr/local.
- See `docs/developer.md` for sandbox override details.

Test Overrides
- `TEST_MODE=1` bypasses root checks for sandboxed testing only.
- `INSTALL_BIN_DIR` or `INSTALL_PREFIX` redirect install targets for tests.
- `TARGET_HOME` sets the test HOME directory for .bashrc edits.
