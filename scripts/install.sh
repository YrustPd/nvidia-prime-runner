#!/usr/bin/env bash
set -euo pipefail

START_MARKER="# >>> NVIDIA-RUN START >>>"
END_MARKER="# <<< NVIDIA-RUN END <<<"
DEFAULT_BIN_DIR="/usr/local/bin"
TEST_MODE="${TEST_MODE:-0}"
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-}"
DOWNLOAD_URL="https://raw.githubusercontent.com/YrustPd/nvidia-prime-runner/main/bin/nvidia-run"
TARGET_BIN=""

usage() {
  cat <<'USAGE'
Usage:
  sudo ./scripts/install.sh [--help]

Installs nvidia-run to /usr/local/bin and adds a marker block to ~/.bashrc.
Creates a timestamped backup of ~/.bashrc before modification.
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
    die "This installer must be run as root. Try: sudo ./scripts/install.sh"
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

download_source_bin() {
  local dest_dir="$1"
  local dest="${dest_dir}/nvidia-run"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$DOWNLOAD_URL" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$DOWNLOAD_URL"
  else
    die "curl or wget is required to download nvidia-run"
  fi

  printf '%s\n' "$dest"
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

backup_bashrc() {
  local bashrc="$1"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local backup="${bashrc}.backup-${ts}"
  local i=1
  while [[ -e "$backup" ]]; do
    backup="${bashrc}.backup-${ts}-${i}"
    i=$((i + 1))
  done
  cp -- "$bashrc" "$backup"
  printf '%s\n' "$backup"
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

append_marker_block() {
  local bashrc="$1"
  local mode="$2"
  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT

  if [[ -f "$bashrc" ]]; then
    cat -- "$bashrc" > "$tmp"
    if [[ -s "$tmp" ]]; then
      printf '\n' >> "$tmp"
    fi
  else
    printf '%s\n' "# ~/.bashrc" > "$tmp"
    printf '%s\n' "# Created by nvidia-prime-runner installer" >> "$tmp"
    printf '\n' >> "$tmp"
  fi

  cat <<'BLOCK' >> "$tmp"
# >>> NVIDIA-RUN START >>>
if [ -n "${NVIDIA_SHELL-}" ]; then
  export DRI_PRIME=1
  export __NV_PRIME_RENDER_OFFLOAD=1
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  if [ -z "${NVIDIA_NO_BANNER-}" ]; then
    printf '%s\n' "[nvidia-run] This terminal session is set to use NVIDIA for GPU-rendered apps (DRI_PRIME=1)."
    printf '%s\n' "[nvidia-run] Verify with: glxinfo -B | grep renderer"
  fi
fi
# <<< NVIDIA-RUN END <<<
BLOCK

  chmod "$mode" "$tmp"
  mv -- "$tmp" "$bashrc"
  trap - EXIT
}

check_deps() {
  local missing=0
  if ! command -v glxinfo >/dev/null 2>&1; then
    missing=1
  fi
  if ! command -v glxgears >/dev/null 2>&1; then
    missing=1
  fi
  if (( missing )); then
    info "Note: glxinfo/glxgears not found. Install 'mesa-utils' to enable verify commands."
  fi
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

  local script_dir root_dir source_bin temp_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  root_dir="$(cd "${script_dir}/.." && pwd)"
  source_bin="${root_dir}/bin/nvidia-run"

  if [[ ! -f "$source_bin" ]]; then
    info "Source CLI not found; downloading nvidia-run."
    temp_dir="$(mktemp -d)"
    source_bin="$(download_source_bin "$temp_dir")"
  fi

  if [[ ! -d "$install_bin_dir" ]]; then
    mkdir -p -- "$install_bin_dir"
  fi

  cp -- "$source_bin" "$TARGET_BIN"
  chmod 0755 "$TARGET_BIN"
  info "Installed: ${TARGET_BIN}"
  if [[ -n "${temp_dir-}" ]]; then
    rm -rf -- "$temp_dir"
  fi

  local target_user target_group target_home bashrc
  target_user="$(get_target_user)"
  target_group="$(get_target_group "$target_user")"
  if [[ -n "${TARGET_HOME-}" ]]; then
    target_home="${TARGET_HOME}"
  else
    target_home="$(get_home_dir "$target_user")"
  fi

  if [[ ! -d "$target_home" ]]; then
    die "Home directory not found for user: ${target_user}"
  fi

  bashrc="${target_home}/.bashrc"

  local mode="0644"
  if [[ -f "$bashrc" ]]; then
    mode="$(stat -c '%a' "$bashrc" 2>/dev/null || printf '0644')"
  fi

  local marker_state
  if [[ -f "$bashrc" ]]; then
    if check_markers "$bashrc"; then
      info "Marker block already present in ${bashrc}; skipping."
    else
      marker_state=$?
      if [[ "$marker_state" -eq 2 ]]; then
        die "Found only one marker in ${bashrc}. Please fix manually before reinstalling."
      fi
      local backup
      backup="$(backup_bashrc "$bashrc")"
      info "Backup created: ${backup}"
      append_marker_block "$bashrc" "$mode"
      if ! is_test_mode; then
        chown -- "$target_user":"$target_group" "$bashrc"
      fi
      info "Updated: ${bashrc}"
    fi
  else
    append_marker_block "$bashrc" "$mode"
    if ! is_test_mode; then
      chown -- "$target_user":"$target_group" "$bashrc"
    fi
    info "Created: ${bashrc}"
  fi

  if ! is_test_mode; then
    check_deps
  fi
}

main "$@"
