#!/usr/bin/env bash
set -euo pipefail

run_with_input() {
  local input="$1"; shift
  printf "%b" "$input" | "$@"
}

run_expect_fail() {
  set +e
  "$@"
  local rc=$?
  set -e
  [[ $rc -ne 0 ]] || { echo "expected failure but got rc=0"; return 1; }
}
