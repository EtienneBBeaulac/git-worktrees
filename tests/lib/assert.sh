#!/usr/bin/env bash
set -euo pipefail

fail() { echo "ASSERT: $*"; exit 1; }
assert_file_exists() { [[ -f "$1" ]] || fail "file missing: $1"; }
assert_dir_exists() { [[ -d "$1" ]] || fail "dir missing: $1"; }
assert_contains() { grep -Fq "$2" "$1" || fail "missing [$2] in $1"; }
assert_not_contains() { ! grep -Fq "$2" "$1" || fail "unexpected [$2] in $1"; }
assert_eq() { [[ "$1" == "$2" ]] || fail "expected [$1] == [$2]"; }
assert_tab_row() {
  local file="$1" prefix="$2"
  awk -F '\t' -v p="$prefix" '$1==p{found=1} END{exit found?0:1}' "$file" || fail "tab row not found: $prefix in $file"
}
