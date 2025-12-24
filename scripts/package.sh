#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/package.sh [--help]

Creates dist/nvidia-prime-runner-<version>.tar.gz from the repository.
USAGE
}

error() {
  printf 'Error: %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ $# -gt 0 ]]; then
  die "Unknown argument: $1"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "${script_dir}/.." && pwd)"

version=""
if [[ -f "${root_dir}/bin/nvidia-run" ]]; then
  version="$(awk -F'"' '/^VERSION=/{print $2; exit}' "${root_dir}/bin/nvidia-run")"
fi
if [[ -z "$version" && -f "${root_dir}/CHANGELOG.md" ]]; then
  version="$(awk '/^## v[0-9]/{print $2; exit}' "${root_dir}/CHANGELOG.md")"
  version="${version#v}"
fi
if [[ -z "$version" ]]; then
  die "Version not found in bin/nvidia-run or CHANGELOG.md"
fi

dist_dir="${root_dir}/dist"
mkdir -p -- "$dist_dir"

archive="${dist_dir}/nvidia-prime-runner-${version}.tar.gz"
tar --exclude="./.git" --exclude="./dist" -czf "$archive" -C "$root_dir" .

printf 'Created %s\n' "$archive"
