#!/usr/bin/env bash
set -euo pipefail

TEST_NAMES=(install uninstall usage)

usage() {
  cat <<'USAGE'
Usage:
  ./tests/run-tests.sh [name]

Runs the bash test suite. Optionally pass a single test name:
  ./tests/run-tests.sh install
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_dir="$script_dir"

run_one() {
  local name="$1"
  local file="${test_dir}/test-${name}.sh"
  if [[ ! -f "$file" ]]; then
    printf 'Unknown test: %s\n' "$name" >&2
    usage
    return 2
  fi
  if bash "$file"; then
    printf 'PASS %s\n' "$name"
    return 0
  fi
  printf 'FAIL %s\n' "$name" >&2
  return 1
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi

if [[ $# -eq 1 ]]; then
  run_one "$1"
  exit $?
fi

passed=0
failed=0

for name in "${TEST_NAMES[@]}"; do
  if run_one "$name"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

printf 'Summary: %d passed, %d failed\n' "$passed" "$failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
