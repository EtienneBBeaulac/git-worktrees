#!/usr/bin/env zsh
# Unit tests for shell quoting utilities in wt-common.zsh

# Source the library
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../../scripts/lib/wt-common.zsh"

# Test counters
typeset -g TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

# Assertion: check that a shell command is syntactically valid
assert_valid_shell() {
  local cmd="$1" msg="$2"
  ((TESTS_RUN++))
  # Use zsh -n to check syntax without executing
  if echo "$cmd" | zsh -n 2>/dev/null; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Command: $cmd"
    echo "   Error: Invalid shell syntax"
  fi
}

# Assertion: check that eval'ing a command produces expected result
assert_eval_eq() {
  local cmd="$1" expected="$2" msg="$3"
  ((TESTS_RUN++))
  local actual
  actual="$(eval "$cmd" 2>/dev/null)"
  if [[ "$actual" == "$expected" ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Command:  $cmd"
    echo "   Expected: $expected"
    echo "   Actual:   $actual"
  fi
}

# Simple equality check
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

echo "=== Testing wt_shell_quote - syntax validity ==="

# Test various problematic strings produce valid shell
assert_valid_shell "echo $(wt_shell_quote "simple")" "Simple string"
assert_valid_shell "echo $(wt_shell_quote "with spaces")" "String with spaces"
assert_valid_shell "echo $(wt_shell_quote "it's quoted")" "String with single quote"
assert_valid_shell "echo $(wt_shell_quote "multiple'quotes'here")" "Multiple single quotes"
assert_valid_shell "echo $(wt_shell_quote "quote at end'")" "Quote at end"
assert_valid_shell "echo $(wt_shell_quote "'quote at start")" "Quote at start"
assert_valid_shell "echo $(wt_shell_quote "has \$dollar")" "String with dollar sign"
assert_valid_shell "echo $(wt_shell_quote 'has `backtick`')" "String with backticks"
assert_valid_shell "echo $(wt_shell_quote 'has "double" quotes')" "String with double quotes"

echo ""
echo "=== Testing wt_shell_quote - value preservation ==="

# Test that eval produces the original string
assert_eval_eq "echo $(wt_shell_quote "simple")" "simple" "Simple string preserved"
assert_eval_eq "echo $(wt_shell_quote "with spaces")" "with spaces" "Spaces preserved"
assert_eval_eq "echo $(wt_shell_quote "it's quoted")" "it's quoted" "Single quote preserved"
assert_eval_eq "echo $(wt_shell_quote "/path/to/user's/dir")" "/path/to/user's/dir" "Path with quote preserved"

echo ""
echo "=== Testing wt_cd_command ==="

assert_valid_shell "$(wt_cd_command "/simple/path")" "Simple cd command"
assert_valid_shell "$(wt_cd_command "/path/with spaces")" "cd with spaces"
assert_valid_shell "$(wt_cd_command "/user's/project")" "cd with quote"
assert_valid_shell "$(wt_cd_command "/complex'path with\"special\$chars")" "cd with complex path"

echo ""
echo "=== Testing wt_shell_command ==="

assert_valid_shell "$(wt_shell_command git status)" "Simple git status"
assert_valid_shell "$(wt_shell_command git commit -m "my message")" "Git commit with message"
assert_valid_shell "$(wt_shell_command git push -u origin "feature/my branch")" "Git push with spaces"
assert_valid_shell "$(wt_shell_command echo "it's here")" "Echo with quote"
assert_valid_shell "$(wt_shell_command git branch -D "user's-branch")" "Git branch with quote"

echo ""
echo "=== Testing wt_shell_command - smart quoting ==="

# Simple args shouldn't be quoted
result="$(wt_shell_command git status)"
assert_eq "git status" "$result" "Simple args not quoted"

result="$(wt_shell_command git push origin main)"
assert_eq "git push origin main" "$result" "Multiple simple args not quoted"

echo ""
echo "=== Integration: end-to-end command execution ==="

# Create a temp file and verify we can cd to paths with special chars
test_dir="/tmp/wt-test-quote's dir"
mkdir -p "$test_dir" 2>/dev/null || true

if [[ -d "$test_dir" ]]; then
  cd_cmd="$(wt_cd_command "$test_dir")"
  ((TESTS_RUN++))
  if eval "$cd_cmd" 2>/dev/null && [[ "$(pwd)" == "$test_dir" ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: cd to directory with quote actually works"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: cd to directory with quote failed"
  fi
  cd - >/dev/null
  rmdir "$test_dir" 2>/dev/null || true
else
  echo "⚠️  SKIP: Could not create test directory"
fi

echo ""
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed:    $TESTS_PASSED"
echo "Failed:    $TESTS_FAILED"
echo "=========================================="

(( TESTS_FAILED > 0 )) && exit 1
exit 0
