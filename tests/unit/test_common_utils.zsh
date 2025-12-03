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
echo "=== Testing editor detection functions ==="

# Test wt_get_installed_editors returns something (on most systems)
assert_fn_exists "wt_get_installed_editors" "wt_get_installed_editors exists"
assert_fn_exists "wt_is_editor_installed" "wt_is_editor_installed exists"
assert_fn_exists "wt_test_editor" "wt_test_editor exists"
assert_fn_exists "wt_detect_editor" "wt_detect_editor exists"

# Test that vim is usually detected (it's on most systems)
((TESTS_RUN++))
if command -v vim >/dev/null 2>&1; then
  if wt_is_editor_installed "vim"; then
    ((TESTS_PASSED++))
    echo "✅ PASS: wt_is_editor_installed detects vim"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: wt_is_editor_installed should detect vim"
  fi
else
  ((TESTS_PASSED++))
  echo "✅ PASS: vim not installed, skip detection test"
fi

# Test wt_test_editor
((TESTS_RUN++))
if wt_test_editor "vim" 2>/dev/null || ! command -v vim >/dev/null 2>&1; then
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_test_editor works correctly"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: wt_test_editor should return true for vim if installed"
fi

# Test WT_KNOWN_EDITORS array exists and has entries
((TESTS_RUN++))
if (( ${#WT_KNOWN_EDITORS[@]} > 0 )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: WT_KNOWN_EDITORS has ${#WT_KNOWN_EDITORS[@]} entries"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: WT_KNOWN_EDITORS should have entries"
fi

# Test that Android Studio is first in detection order (alphabetically)
((TESTS_RUN++))
first_editor="${WT_KNOWN_EDITORS[1]%%|*}"
if [[ "$first_editor" == "Android Studio" ]]; then
  ((TESTS_PASSED++))
  echo "✅ PASS: Android Studio is first in WT_KNOWN_EDITORS"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: Expected 'Android Studio' first, got '$first_editor'"
fi

echo ""
echo "=== Testing new helper functions exist ==="

assert_fn_exists "wt_copy_to_clipboard" "wt_copy_to_clipboard exists"
assert_fn_exists "wt_open_in_terminal" "wt_open_in_terminal exists"

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
echo "=== Smoke test: wt_copy_to_clipboard ==="

# Test clipboard function exists and returns appropriate exit code
((TESTS_RUN++))
wt_copy_to_clipboard "test" 2>/dev/null
clip_exit=$?
# Exit 0 = clipboard tool found, Exit 1 = no clipboard tool (both acceptable)
if (( clip_exit <= 1 )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_copy_to_clipboard executes cleanly (exit: $clip_exit)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: wt_copy_to_clipboard returned unexpected exit code: $clip_exit"
fi

echo ""
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed:    $TESTS_PASSED"
echo "Failed:    $TESTS_FAILED"
echo "=========================================="

(( TESTS_FAILED > 0 )) && exit 1
exit 0

