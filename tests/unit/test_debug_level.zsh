#!/usr/bin/env zsh
# Unit tests for wt_get_debug_level() debug level parsing
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_get_debug_level()"

# Each test runs in a fresh subshell to avoid cache pollution

# Test 1: Default returns 0
test_start "wt_get_debug_level returns 0 by default"
result=$(unset WT_DEBUG WT_DEBUG_LEVEL_CACHE; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "0" ]] && test_pass || test_fail "Expected '0', got '$result'"

# Test 2: WT_DEBUG=1 returns 1
test_start "wt_get_debug_level returns 1 for WT_DEBUG=1"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=1; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected '1', got '$result'"

# Test 3: WT_DEBUG=true returns 1
test_start "wt_get_debug_level returns 1 for WT_DEBUG=true"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=true; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected '1', got '$result'"

# Test 4: WT_DEBUG=on returns 1
test_start "wt_get_debug_level returns 1 for WT_DEBUG=on"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=on; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected '1', got '$result'"

# Test 5: WT_DEBUG=yes returns 1
test_start "wt_get_debug_level returns 1 for WT_DEBUG=yes"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=yes; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected '1', got '$result'"

# Test 6: WT_DEBUG=2 returns 2
test_start "wt_get_debug_level returns 2 for WT_DEBUG=2"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=2; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "2" ]] && test_pass || test_fail "Expected '2', got '$result'"

# Test 7: WT_DEBUG=verbose returns 2
test_start "wt_get_debug_level returns 2 for WT_DEBUG=verbose"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=verbose; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "2" ]] && test_pass || test_fail "Expected '2', got '$result'"

# Test 8: WT_DEBUG=0 returns 0
test_start "wt_get_debug_level returns 0 for WT_DEBUG=0"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=0; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "0" ]] && test_pass || test_fail "Expected '0', got '$result'"

# Test 9: Case insensitive (TRUE)
test_start "wt_get_debug_level is case insensitive"
result=$(unset WT_DEBUG_LEVEL_CACHE; export WT_DEBUG=TRUE; source "$ROOT_DIR/scripts/lib/wt-common.zsh"; wt_get_debug_level)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected '1', got '$result'"

# Test 10: Cache is used on subsequent calls
test_start "wt_get_debug_level uses cache"
result=$(
  unset WT_DEBUG_LEVEL_CACHE
  export WT_DEBUG=1
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  wt_get_debug_level >/dev/null  # First call sets cache
  export WT_DEBUG=2              # Change env
  wt_get_debug_level             # Should return cached value
)
[[ "$result" == "1" ]] && test_pass || test_fail "Expected cached '1', got '$result'"

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

