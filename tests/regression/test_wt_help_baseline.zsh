#!/usr/bin/env zsh
# Baseline regression test - existing wt --help behavior
# This test ensures we don't break existing documented behavior

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

test_suite_init "Baseline: wt --help"

# Source the wt function
source "$ROOT_DIR/scripts/wt"

# Test: --help flag works
test_start "wt --help exits with 0"
if output=$(wt --help 2>&1); then
  test_pass
else
  test_fail "wt --help should exit 0"
fi

# Test: help contains usage
test_start "wt --help contains 'Usage'"
assert_output_contains "$output" "Usage:" "Help should contain 'Usage:'"

# Test: help mentions --start option
test_start "wt --help mentions --start"
assert_output_contains "$output" "--start" "Help should mention --start"

# Test: help mentions subcommands  
test_start "wt --help mentions subcommands"
if [[ "$output" == *"Subcommands:"* ]] || [[ "$output" == *"new"* ]]; then
  test_pass
else
  test_fail "Help should mention subcommands"
fi

test_suite_summary
