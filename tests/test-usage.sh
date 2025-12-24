#!/usr/bin/env bash
set -euo pipefail

# Exercises CLI parsing using --dry-run/--help paths to avoid executing apps.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "${script_dir}/.." && pwd)"
cli="${root_dir}/bin/nvidia-run"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    fail "Expected output to contain: ${needle}"
  fi
}

run_cmd() {
  set +e
  CMD_OUTPUT="$("$@" 2>&1)"
  CMD_STATUS=$?
  set -e
}

run_cmd bash "$cli" --help
if [[ "$CMD_STATUS" -ne 0 ]]; then
  fail "--help returned nonzero"
fi
assert_contains "$CMD_OUTPUT" "Usage:"

run_cmd bash "$cli" --version
if [[ "$CMD_STATUS" -ne 0 ]]; then
  fail "--version returned nonzero"
fi
assert_contains "$CMD_OUTPUT" "version"

run_cmd bash "$cli" verify
if [[ "$CMD_STATUS" -ne 0 ]]; then
  fail "verify returned nonzero"
fi
assert_contains "$CMD_OUTPUT" "glxinfo -B | grep renderer"
assert_contains "$CMD_OUTPUT" "glxgears -info | grep -E"

run_cmd bash "$cli" --dry-run --verbose run /bin/echo hello
if [[ "$CMD_STATUS" -ne 0 ]]; then
  fail "--dry-run returned nonzero"
fi
assert_contains "$CMD_OUTPUT" "DRI_PRIME=1"
assert_contains "$CMD_OUTPUT" "__NV_PRIME_RENDER_OFFLOAD=1"
assert_contains "$CMD_OUTPUT" "__GLX_VENDOR_LIBRARY_NAME=nvidia"
assert_contains "$CMD_OUTPUT" "Dry run: would execute:"
assert_contains "$CMD_OUTPUT" "/bin/echo"

run_cmd bash "$cli" --unknown
if [[ "$CMD_STATUS" -eq 0 ]]; then
  fail "Unknown option should return nonzero"
fi
assert_contains "$CMD_OUTPUT" "Unknown option"
assert_contains "$CMD_OUTPUT" "Try: nvidia-run --help"

run_cmd bash "$cli" run
if [[ "$CMD_STATUS" -eq 0 ]]; then
  fail "Missing run target should return nonzero"
fi
assert_contains "$CMD_OUTPUT" "Missing command after 'run'"
assert_contains "$CMD_OUTPUT" "Try: nvidia-run --help"

printf 'ok: usage tests completed\n'
