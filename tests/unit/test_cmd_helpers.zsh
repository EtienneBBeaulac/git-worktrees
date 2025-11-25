#!/usr/bin/env zsh
# Unit tests for wt_has_cmd() and wt_run() command helpers
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_has_cmd() and wt_run()"

# ============================================================================
# wt_has_cmd tests
# ============================================================================

test_start "wt_has_cmd detects functions"
# wt_short_ref is defined in wt-common.zsh
wt_has_cmd wt_short_ref && test_pass || test_fail

test_start "wt_has_cmd detects PATH commands"
# git should be available
wt_has_cmd git && test_pass || test_fail

test_start "wt_has_cmd returns false for nonexistent command"
wt_has_cmd nonexistent_command_xyz_123 && test_fail || test_pass

test_start "wt_has_cmd detects built-in zsh commands"
wt_has_cmd echo && test_pass || test_fail

# Define a test function
test_func_for_has_cmd() { echo "test"; }

test_start "wt_has_cmd detects locally defined functions"
wt_has_cmd test_func_for_has_cmd && test_pass || test_fail

# ============================================================================
# wt_run tests
# ============================================================================

test_start "wt_run executes existing command"
result=$(wt_run echo "hello" 2>&1)
[[ "$result" == "hello" ]] && test_pass || test_fail "Expected 'hello', got '$result'"

test_start "wt_run executes functions"
result=$(wt_run wt_short_ref "refs/heads/main" 2>&1)
[[ "$result" == "main" ]] && test_pass || test_fail "Expected 'main', got '$result'"

test_start "wt_run returns error for missing command"
if wt_run nonexistent_xyz 2>/dev/null; then
  test_fail "Should have returned error"
else
  test_pass
fi

test_start "wt_run outputs error message for missing command"
result=$(wt_run nonexistent_xyz 2>&1)
[[ "$result" == *"not available"* ]] && test_pass || test_fail "Expected error message"

test_start "wt_run passes arguments correctly"
test_args_func() { echo "$#:$1:$2"; }
result=$(wt_run test_args_func "arg1" "arg2" 2>&1)
[[ "$result" == "2:arg1:arg2" ]] && test_pass || test_fail "Expected '2:arg1:arg2', got '$result'"

test_start "wt_run preserves exit code of command"
failing_cmd() { return 42; }
wt_run failing_cmd 2>/dev/null
exit_code=$?
[[ $exit_code -eq 42 ]] && test_pass || test_fail "Expected exit code 42, got $exit_code"

test_start "wt_run with empty args"
empty_test() { echo "empty"; }
result=$(wt_run empty_test 2>&1)
[[ "$result" == "empty" ]] && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

