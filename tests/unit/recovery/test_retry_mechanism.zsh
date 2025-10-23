#!/usr/bin/env zsh
# Unit tests for wt-recovery.zsh - Retry mechanism
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-recovery.zsh"

test_suite_init "wt-recovery: Retry Mechanism"

# Test: Basic retry succeeds on first attempt
test_start "wt_retry succeeds immediately"
call_count=0
test_command() { ((call_count++)); return 0; }
if wt_retry 3 test_command; then
  test_pass
else
  test_fail "Should succeed on first attempt"
fi
assert_equals 1 $call_count "Should call once"

# Test: Retry succeeds on second attempt
test_start "wt_retry succeeds on second attempt"
call_count=0
test_command_fail_once() {
  ((call_count++))
  (( call_count > 1 ))
}
if wt_retry 3 test_command_fail_once 2>/dev/null; then
  test_pass
else
  test_fail "Should succeed on second attempt"
fi
assert_equals 2 $call_count "Should call twice"

# Test: Retry fails after max attempts
test_start "wt_retry fails after max attempts"
call_count=0
test_command_always_fail() {
  ((call_count++))
  return 1
}
if wt_retry 3 test_command_always_fail 2>/dev/null; then
  test_fail "Should fail after max attempts"
else
  test_pass
fi
assert_equals 3 $call_count "Should call three times"

# Test: Retry with zero attempts
test_start "wt_retry with 0 attempts returns immediately"
call_count=0
if wt_retry 0 test_command 2>/dev/null; then
  test_fail "Should not succeed with 0 attempts"
else
  test_pass
fi
assert_equals 0 $call_count "Should not call command"

# Test: Retry preserves exit code
test_start "wt_retry preserves final exit code"
test_command_exit_42() { return 42; }
wt_retry 2 test_command_exit_42 2>/dev/null || exit_code=$?
assert_equals 1 $exit_code "Should return 1 (standard retry failure)"

test_suite_summary

