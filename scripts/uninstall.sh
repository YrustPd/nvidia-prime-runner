#!/usr/bin/env bash
set -euo pipefail

START_MARKER="# >>> NVIDIA-RUN START >>>"
END_MARKER="# <<< NVIDIA-RUN END <<<"
DEFAULT_BIN_DIR="/usr/local/bin"
TEST_MODE="${TEST_MODE:-0}"
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-}"
NV_RUN_ROOT="${NV_RUN_ROOT:-}"
NV_RUN_PREFIX="${NV_RUN_PREFIX:-}"
TARGET_BIN=""

usage() {
  cat <<'USAGE'
Usage:
  sudo ./scripts/uninstall.sh [--help]

Removes /usr/local/bin/nvidia-run and deletes the NVIDIA-RUN block from ~/.bashrc.
USAGE
}

info() {
  printf '%s\n' "$*"
}

error() {
  printf 'Error: %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

require_root() {
  if is_test_mode; then
    return
  fi
  if [[ "$(id -u)" -ne 0 ]]; then
    die "This uninstaller must be run as root. Try: sudo ./scripts/uninstall.sh"
  fi
}

is_test_mode() {
  [[ "${TEST_MODE}" == "1" ]]
}

resolve_install_bin_dir() {
  if [[ -n "${INSTALL_BIN_DIR}" ]]; then
    printf '%s\n' "${INSTALL_BIN_DIR}"
    return
  fi
  if [[ -n "${INSTALL_PREFIX}" ]]; then
    printf '%s/bin\n' "${INSTALL_PREFIX}"
    return
  fi
  printf '%s\n' "${DEFAULT_BIN_DIR}"
}

resolve_root_dir() {
  if [[ -n "${NV_RUN_ROOT}" ]]; then
    printf '%s\n' "${NV_RUN_ROOT}"
    return
  fi
  if [[ -n "${NV_RUN_PREFIX}" ]]; then
    printf '%s\n' "${NV_RUN_PREFIX}"
    return
  fi
  printf '%s\n' "/"
}

get_target_user() {
  if [[ -n "${SUDO_USER-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
    return
  fi
  id -un
}

get_target_group() {
  local user="$1"
  id -gn "$user"
}

get_home_dir() {
  local user="$1"
  local home=""
  if [[ -r /etc/passwd ]]; then
    home="$(awk -F: -v u="$user" '$1==u {print $6; exit}' /etc/passwd)"
  fi
  if [[ -z "$home" ]]; then
    if [[ "$user" == "root" ]]; then
      home="/root"
    else
      home="/home/$user"
    fi
  fi
  printf '%s\n' "$home"
}

check_markers() {
  local bashrc="$1"
  local has_start=0
  local has_end=0

  if grep -Fqx -- "$START_MARKER" "$bashrc"; then
    has_start=1
  fi
  if grep -Fqx -- "$END_MARKER" "$bashrc"; then
    has_end=1
  fi

  if (( has_start == 1 && has_end == 1 )); then
    return 0
  fi
  if (( has_start == 0 && has_end == 0 )); then
    return 1
  fi
  return 2
}

remove_marker_block() {
  local bashrc="$1"
  local mode="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  trap 'rm -f "${tmp_file-}"' EXIT

  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start {inside=1; next}
    $0 == end {inside=0; next}
    inside == 0 {print}
  ' "$bashrc" > "$tmp_file"

  chmod "$mode" "$tmp_file"
  mv -- "$tmp_file" "$bashrc"
  trap - EXIT
}

main() {
  if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
    usage
    exit 0
  fi
  if [[ $# -gt 0 ]]; then
    error "Unknown argument: $1"
    usage
    exit 2
  fi

  require_root

  local install_bin_dir
  install_bin_dir="$(resolve_install_bin_dir)"
  TARGET_BIN="${install_bin_dir}/nvidia-run"

  if [[ -e "$TARGET_BIN" ]]; then
    rm -f -- "$TARGET_BIN"
    info "Removed: ${TARGET_BIN}"
  else
    info "Not found: ${TARGET_BIN}"
  fi

  local target_user target_group target_home bashrc root_dir
  target_user="$(get_target_user)"
  target_group="$(get_target_group "$target_user")"
  root_dir="$(resolve_root_dir)"
  if [[ -n "${TARGET_HOME-}" ]]; then
    target_home="${TARGET_HOME}"
  elif [[ "${root_dir}" != "/" ]]; then
    target_home="${root_dir%/}/home"
  else
    target_home="$(get_home_dir "$target_user")"
  fi

  if [[ ! -d "$target_home" ]]; then
    die "Home directory not found for user: ${target_user}"
  fi

  bashrc="${target_home}/.bashrc"

  if [[ ! -f "$bashrc" ]]; then
    info "No .bashrc found at ${bashrc}; skipping."
    exit 0
  fi

  local mode="0644"
  mode="$(stat -c '%a' "$bashrc" 2>/dev/null || printf '0644')"

  if check_markers "$bashrc"; then
    remove_marker_block "$bashrc" "$mode"
    if ! is_test_mode; then
      chown -- "$target_user":"$target_group" "$bashrc"
    fi
    info "Removed marker block from ${bashrc}"
  else
    local marker_state=$?
    if [[ "$marker_state" -eq 2 ]]; then
      die "Found only one marker in ${bashrc}. Please fix manually before uninstalling."
    fi
    info "No marker block found in ${bashrc}; skipping."
  fi
}

main "$@"
