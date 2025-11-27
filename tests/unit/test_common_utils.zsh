#!/usr/bin/env zsh
# Unit tests for common utilities in wt-common.zsh

# Source the library
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../../scripts/lib/wt-common.zsh"

# Test counters
typeset -g TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

assert_fn_exists() {
  local fn="$1" msg="$2"
  ((TESTS_RUN++))
  if typeset -f "$fn" >/dev/null 2>&1; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg - function '$fn' not found"
  fi
}

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  ((TESTS_RUN++))
  if [[ "$expected" == "$actual" ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Expected: $expected"
    echo "   Actual:   $actual"
  fi
}

echo "=== Testing utility functions exist ==="

assert_fn_exists "wt_git_fetch_with_timeout" "wt_git_fetch_with_timeout exists"
assert_fn_exists "wt_fetch_remotes_safe" "wt_fetch_remotes_safe exists"
assert_fn_exists "wt_editor_selection_menu" "wt_editor_selection_menu exists"
assert_fn_exists "wt_change_editor_interactive" "wt_change_editor_interactive exists"
assert_fn_exists "wt_escape_single_quotes" "wt_escape_single_quotes exists"
assert_fn_exists "wt_shell_quote" "wt_shell_quote exists"
assert_fn_exists "wt_cd_command" "wt_cd_command exists"
assert_fn_exists "wt_shell_command" "wt_shell_command exists"

echo ""
echo "=== Testing wt_editor_selection_menu returns correct values ==="

# Test that menu parsing works by simulating input
test_editor_choice() {
  local choice="$1" expected="$2"
  local actual
  actual=$(echo "$choice" | wt_editor_selection_menu 2>/dev/null | tail -1)
  assert_eq "$expected" "$actual" "Choice $choice returns $expected"
}

test_editor_choice "1" "Android Studio"
test_editor_choice "2" "Visual Studio Code"
test_editor_choice "3" "Cursor"
test_editor_choice "4" "IntelliJ IDEA"
test_editor_choice "5" "PyCharm"
test_editor_choice "6" "WebStorm"
test_editor_choice "7" "Sublime Text"
test_editor_choice "8" "vim"
test_editor_choice "9" "none"

echo ""
echo "=== Smoke test: wt_git_fetch_with_timeout ==="

# Smoke test: verify function executes without crashing
# Both success (in git repo) and failure (outside repo/network issues) are acceptable
# Exit codes > 128 indicate crashes/signals which should fail the test
((TESTS_RUN++))
wt_git_fetch_with_timeout 1 2>/dev/null
fetch_exit=$?
if (( fetch_exit <= 128 )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_git_fetch_with_timeout executes cleanly (exit: $fetch_exit)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: wt_git_fetch_with_timeout crashed with signal (exit: $fetch_exit)"
fi

echo ""
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed:    $TESTS_PASSED"
echo "Failed:    $TESTS_FAILED"
echo "=========================================="

(( TESTS_FAILED > 0 )) && exit 1
exit 0

