#!/usr/bin/env zsh
# Baseline regression test - all existing flags still work
# This ensures we don't break any documented CLI interfaces

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

test_suite_init "Baseline: All existing flags work"

# Test: wt flags
test_start "wt --start list"
if timeout 2 "$ROOT_DIR/scripts/wt" --start list </dev/null >/dev/null 2>&1 || [[ $? == 124 ]]; then
  test_pass
else
  test_fail "wt --start list should work"
fi

test_start "wt --help"
if "$ROOT_DIR/scripts/wt" --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wt --help should work"
fi

# Test: wtnew flags
test_start "wtnew --help"
if "$ROOT_DIR/scripts/wtnew" --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wtnew --help should work"
fi

# Test: wtls flags
test_start "wtls --help"
if "$ROOT_DIR/scripts/wtls" --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wtls --help should work"
fi

# Test: wtopen flags
test_start "wtopen --help"
if "$ROOT_DIR/scripts/wtopen" --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wtopen --help should work"
fi

# Test: wtrm flags
test_start "wtrm --help"
if "$ROOT_DIR/scripts/wtrm" --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wtrm --help should work"
fi

test_suite_summary

