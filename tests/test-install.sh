#!/usr/bin/env bash
set -euo pipefail

# Uses sandboxed HOME and INSTALL_BIN_DIR to avoid touching real system paths.

START_MARKER="# >>> NVIDIA-RUN START >>>"
END_MARKER="# <<< NVIDIA-RUN END <<<"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "${script_dir}/.." && pwd)"
install_script="${root_dir}/scripts/install.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_exists() {
  [[ -e "$1" ]] || fail "Expected file to exist: $1"
}

assert_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
    fail "Expected content not found in ${file}: ${needle}"
  fi
}

assert_contains_once() {
  local file="$1"
  local needle="$2"
  local count
  count="$(awk -v pat="$needle" '$0==pat {c++} END {print c+0}' "$file")"
  if [[ "$count" -ne 1 ]]; then
    fail "Expected exactly one occurrence in ${file}: ${needle} (got ${count})"
  fi
}

run_install() {
  local bin_dir="$1"
  local home_dir="$2"
  TEST_MODE=1 INSTALL_BIN_DIR="$bin_dir" TARGET_HOME="$home_dir" HOME="$home_dir" \
    bash "$install_script"
}

tmp1="$(mktemp -d)"
tmp2="$(mktemp -d)"
cleanup() {
  rm -rf -- "$tmp1" "$tmp2"
}
trap cleanup EXIT

bin_dir1="${tmp1}/usr/local/bin"
home1="${tmp1}/home"
mkdir -p -- "$bin_dir1" "$home1"
bashrc1="${home1}/.bashrc"
printf '%s\n' "# custom line" > "$bashrc1"
printf '%s\n' "custom_line" >> "$bashrc1"

run_install "$bin_dir1" "$home1"

assert_file_exists "${bin_dir1}/nvidia-run"
assert_contains_once "$bashrc1" "$START_MARKER"
assert_contains_once "$bashrc1" "$END_MARKER"
assert_contains "$bashrc1" "custom_line"

shopt -s nullglob
backups=( "${bashrc1}".backup-* )
shopt -u nullglob
if [[ "${#backups[@]}" -lt 1 ]]; then
  fail "Expected backup file for ${bashrc1}"
fi

run_install "$bin_dir1" "$home1"
assert_contains_once "$bashrc1" "$START_MARKER"
assert_contains_once "$bashrc1" "$END_MARKER"

bin_dir2="${tmp2}/usr/local/bin"
home2="${tmp2}/home"
mkdir -p -- "$bin_dir2" "$home2"
bashrc2="${home2}/.bashrc"

run_install "$bin_dir2" "$home2"

assert_file_exists "$bashrc2"
assert_contains_once "$bashrc2" "$START_MARKER"
assert_contains_once "$bashrc2" "$END_MARKER"

owner_uid="$(stat -c '%u' "$bashrc2")"
current_uid="$(id -u)"
if [[ "$owner_uid" -ne "$current_uid" ]]; then
  fail "Expected ${bashrc2} owned by current user"
fi

printf 'ok: install tests completed\n'
