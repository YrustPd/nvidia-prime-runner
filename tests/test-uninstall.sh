#!/usr/bin/env bash
set -euo pipefail

# Uses sandboxed HOME and INSTALL_BIN_DIR to avoid touching real system paths.

START_MARKER="# >>> NVIDIA-RUN START >>>"
END_MARKER="# <<< NVIDIA-RUN END <<<"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "${script_dir}/.." && pwd)"
uninstall_script="${root_dir}/scripts/uninstall.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_exists() {
  [[ -e "$1" ]] || fail "Expected file to exist: $1"
}

assert_not_exists() {
  [[ ! -e "$1" ]] || fail "Expected file to be removed: $1"
}

assert_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
    fail "Expected content not found in ${file}: ${needle}"
  fi
}

assert_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
    fail "Expected content removed from ${file}: ${needle}"
  fi
}

run_uninstall() {
  local bin_dir="$1"
  local home_dir="$2"
  TEST_MODE=1 INSTALL_BIN_DIR="$bin_dir" TARGET_HOME="$home_dir" HOME="$home_dir" \
    bash "$uninstall_script"
}

tmp1="$(mktemp -d)"
tmp2="$(mktemp -d)"
tmp3="$(mktemp -d)"
cleanup() {
  rm -rf -- "$tmp1" "$tmp2" "$tmp3"
}
trap cleanup EXIT

bin_dir1="${tmp1}/usr/local/bin"
home1="${tmp1}/home"
mkdir -p -- "$bin_dir1" "$home1"
bashrc1="${home1}/.bashrc"
printf '%s\n' "keep-this-line" > "$bashrc1"
{
  printf '%s\n' "$START_MARKER"
  printf '%s\n' "export DRI_PRIME=1"
  printf '%s\n' "$END_MARKER"
  printf '%s\n' "tail-line"
} >> "$bashrc1"
printf '%s\n' "stub" > "${bin_dir1}/nvidia-run"

run_uninstall "$bin_dir1" "$home1"

assert_not_exists "${bin_dir1}/nvidia-run"
assert_not_contains "$bashrc1" "$START_MARKER"
assert_not_contains "$bashrc1" "$END_MARKER"
assert_contains "$bashrc1" "keep-this-line"
assert_contains "$bashrc1" "tail-line"

run_uninstall "$bin_dir1" "$home1"

bin_dir2="${tmp2}/usr/local/bin"
home2="${tmp2}/home"
mkdir -p -- "$bin_dir2" "$home2"
bashrc2="${home2}/.bashrc"
printf '%s\n' "no markers here" > "$bashrc2"

run_uninstall "$bin_dir2" "$home2"
assert_contains "$bashrc2" "no markers here"

bin_dir3="${tmp3}/usr/local/bin"
home3="${tmp3}/home"
mkdir -p -- "$bin_dir3" "$home3"
bashrc3="${home3}/.bashrc"
printf '%s\n' "keep-this-line" > "$bashrc3"
{
  printf '%s\n' "$START_MARKER"
} >> "$bashrc3"

set +e
run_uninstall "$bin_dir3" "$home3"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  fail "Expected uninstall to fail on malformed markers"
fi
assert_contains "$bashrc3" "keep-this-line"
assert_contains "$bashrc3" "$START_MARKER"

printf 'ok: uninstall tests completed\n'
