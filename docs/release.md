# Release Checklist

Before Release
- Ensure CI is green (shellcheck + tests).
- Review and update `CHANGELOG.md`.
- Bump the version string in `bin/nvidia-run` if needed.
- Confirm README and docs are accurate for the release.
- Generate a tarball with `./scripts/package.sh`.
- Ensure `bin/nvidia-run` and `CHANGELOG.md` agree on the release version.

Tagging and GitHub Release
- Create an annotated tag (e.g., `v1.0.0`).
- Push the tag to GitHub.
- Create a GitHub Release from the tag and include key changelog notes.
- Use `docs/release-notes-v1.0.0.md` as a starting point for release notes.

Versioning Strategy
- Use semantic versioning (MAJOR.MINOR.PATCH).
- Increment PATCH for fixes, MINOR for new features, MAJOR for breaking changes.

Packaging
- `scripts/package.sh` reads the version from `bin/nvidia-run` (fallback to `CHANGELOG.md`).
- Output: `dist/nvidia-prime-runner-<version>.tar.gz`

Local Verification (Commands Only)
- `shellcheck bin/nvidia-run scripts/install.sh scripts/uninstall.sh tests/*.sh`
- `./tests/run-tests.sh`
- Optional: run `nvidia-run --help` and `nvidia-run verify` for smoke checks.
