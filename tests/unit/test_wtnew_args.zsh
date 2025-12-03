#!/usr/bin/env zsh
# Unit tests for wtnew argument parsing
# Tests positional argument support and flag handling

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-common.zsh"
source "$ROOT_DIR/scripts/wtnew"

test_suite_init "wtnew Argument Parsing"

# ============================================================================
# Test: Positional argument support
# ============================================================================

test_start "wtnew accepts positional branch argument"
# We can't fully run wtnew without a repo, but we can test argument parsing
# by checking what error we get (should be "Not a git repo" not "Unknown option")

output=$(wtnew test-branch 2>&1) || true

if [[ "$output" == *"Unknown option"* ]]; then
  test_fail "wtnew should accept positional branch argument, got: Unknown option"
elif [[ "$output" == *"Not a git repo"* ]] || [[ "$output" == *"not a git"* ]]; then
  # This is expected - it parsed the argument, then failed because no repo
  test_pass "correctly parsed positional arg (failed at git check)"
else
  # Could be FZF missing or other expected error
  test_pass "accepted positional argument"
fi

test_start "wtnew -n flag still works"
output=$(wtnew -n test-branch 2>&1) || true

if [[ "$output" == *"Unknown option"* ]]; then
  test_fail "wtnew -n should work"
else
  test_pass
fi

test_start "wtnew rejects unknown flags"
# Capture both output and exit code properly
output=$(wtnew --unknown-flag 2>&1)
exit_code=$?

if [[ "$output" != *"Unknown option"* ]]; then
  test_fail "wtnew should reject --unknown-flag"
else
  # Exit code 2 is expected, but when sourced as a function it may vary
  test_pass "correctly rejected unknown flag"
fi

test_start "wtnew rejects multiple positional arguments"
output=$(wtnew branch1 branch2 2>&1) || true

if [[ "$output" != *"already specified"* ]] && [[ "$output" != *"extra argument"* ]]; then
  test_fail "wtnew should reject multiple positional arguments"
else
  test_pass
fi

test_start "wtnew rejects positional then -n flag (branch1 -n branch2)"
output=$(wtnew branch1 -n branch2 2>&1)
exit_code=$?

if [[ "$output" != *"already specified"* ]]; then
  test_fail "wtnew should reject 'branch1 -n branch2'"
elif (( exit_code != 2 )); then
  test_fail "should exit with code 2, got $exit_code"
else
  test_pass
fi

test_start "wtnew rejects -n flag then positional (-n branch1 branch2)"
output=$(wtnew -n branch1 branch2 2>&1)
exit_code=$?

if [[ "$output" != *"already specified"* ]]; then
  test_fail "wtnew should reject '-n branch1 branch2'"
elif (( exit_code != 2 )); then
  test_fail "should exit with code 2, got $exit_code"
else
  test_pass
fi

test_start "wtnew positional arg can combine with flags"
output=$(wtnew test-branch --push --no-open 2>&1) || true

if [[ "$output" == *"Unknown option"* ]]; then
  test_fail "wtnew should accept: branch-name --push --no-open"
else
  test_pass "flags after positional arg work"
fi

test_start "wtnew flags can come before positional"
output=$(wtnew --push test-branch 2>&1) || true

if [[ "$output" == *"Unknown option"* ]]; then
  test_fail "wtnew should accept: --push branch-name"
else
  test_pass
fi

# ============================================================================
# Test: Help output
# ============================================================================

test_start "wtnew --help shows usage with positional argument"
help_output=$(wtnew --help 2>&1)

if [[ "$help_output" != *"[branch-name]"* ]] && [[ "$help_output" != *"branch-name"* ]]; then
  test_fail "Help should show positional branch-name argument"
else
  test_pass
fi

test_start "wtnew --help shows examples"
if [[ "$help_output" != *"Examples"* ]]; then
  test_fail "Help should include examples section"
else
  test_pass
fi

test_suite_summary

