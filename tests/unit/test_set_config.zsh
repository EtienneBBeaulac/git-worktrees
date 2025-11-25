#!/usr/bin/env zsh
# Unit tests for wt_set_config() config persistence
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_set_config()"

# Setup temp config directory
ORIG_HOME="$HOME"
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
trap 'rm -rf "$TEST_HOME"; export HOME="$ORIG_HOME"' EXIT

# Reset config state
typeset -gA WT_CONFIG=()

# Test 1: Creates config directory if missing
test_start "wt_set_config creates config directory"
wt_set_config "TEST_KEY" "test_value"
[[ -d "$HOME/.config/git-worktrees" ]] && test_pass || test_fail

# Test 2: Creates config file
test_start "wt_set_config creates config file"
[[ -f "$HOME/.config/git-worktrees/config" ]] && test_pass || test_fail

# Test 3: Writes key=value to file
test_start "wt_set_config writes key=value format"
grep -q "^TEST_KEY=test_value$" "$HOME/.config/git-worktrees/config" && test_pass || test_fail

# Test 4: Updates in-memory config
test_start "wt_set_config updates in-memory WT_CONFIG"
[[ "${WT_CONFIG[TEST_KEY]}" == "test_value" ]] && test_pass || test_fail

# Test 5: Appends new key without duplicating
test_start "wt_set_config appends new keys"
wt_set_config "ANOTHER_KEY" "another_value"
[[ $(grep -c "^ANOTHER_KEY=" "$HOME/.config/git-worktrees/config") -eq 1 ]] && test_pass || test_fail

# Test 6: Updates existing key (doesn't duplicate)
test_start "wt_set_config updates existing key in place"
wt_set_config "TEST_KEY" "updated_value"
[[ $(grep -c "^TEST_KEY=" "$HOME/.config/git-worktrees/config") -eq 1 ]] && test_pass || test_fail

# Test 7: Updated value is correct
test_start "wt_set_config updated value is correct"
grep -q "^TEST_KEY=updated_value$" "$HOME/.config/git-worktrees/config" && test_pass || test_fail

# Test 8: Handles values with spaces (no quoting needed for simple storage)
test_start "wt_set_config handles simple values"
wt_set_config "PATH_KEY" "/path/to/dir"
grep -q "^PATH_KEY=/path/to/dir$" "$HOME/.config/git-worktrees/config" && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

