#!/usr/bin/env zsh
# Unit tests for wt_worktree_parse/get/create structured data functions
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_worktree_* structured data functions"

# Sample worktree line (tab-delimited): branch\tpath\tbare\tdetached\tsha
SAMPLE_LINE=$'main\t/path/to/worktree\t0\t0\tabc123'
DETACHED_LINE=$'(detached)\t/path/detached\t0\t1\tdef456'
BARE_LINE=$'(bare)\t/path/bare\t1\t0\t'

# ============================================================================
# wt_worktree_get tests
# ============================================================================

test_start "wt_worktree_get extracts branch field"
result=$(wt_worktree_get "$SAMPLE_LINE" branch)
[[ "$result" == "main" ]] && test_pass || test_fail "Expected 'main', got '$result'"

test_start "wt_worktree_get extracts path field"
result=$(wt_worktree_get "$SAMPLE_LINE" path)
[[ "$result" == "/path/to/worktree" ]] && test_pass || test_fail "Expected '/path/to/worktree', got '$result'"

test_start "wt_worktree_get extracts bare field"
result=$(wt_worktree_get "$SAMPLE_LINE" bare)
[[ "$result" == "0" ]] && test_pass || test_fail "Expected '0', got '$result'"

test_start "wt_worktree_get extracts detached field"
result=$(wt_worktree_get "$SAMPLE_LINE" detached)
[[ "$result" == "0" ]] && test_pass || test_fail "Expected '0', got '$result'"

test_start "wt_worktree_get extracts sha field"
result=$(wt_worktree_get "$SAMPLE_LINE" sha)
[[ "$result" == "abc123" ]] && test_pass || test_fail "Expected 'abc123', got '$result'"

test_start "wt_worktree_get returns error for invalid field"
if wt_worktree_get "$SAMPLE_LINE" invalid_field 2>/dev/null; then
  test_fail "Should have returned error"
else
  test_pass
fi

# ============================================================================
# wt_worktree_parse tests
# ============================================================================

test_start "wt_worktree_parse sets branch variable"
wt_worktree_parse "$SAMPLE_LINE" TEST
[[ "$TEST_branch" == "main" ]] && test_pass || test_fail "Expected 'main', got '$TEST_branch'"

test_start "wt_worktree_parse sets path variable"
[[ "$TEST_path" == "/path/to/worktree" ]] && test_pass || test_fail

test_start "wt_worktree_parse sets bare variable"
[[ "$TEST_bare" == "0" ]] && test_pass || test_fail

test_start "wt_worktree_parse sets detached variable"
[[ "$TEST_detached" == "0" ]] && test_pass || test_fail

test_start "wt_worktree_parse sets sha variable"
[[ "$TEST_sha" == "abc123" ]] && test_pass || test_fail

test_start "wt_worktree_parse with default prefix WT"
wt_worktree_parse "$DETACHED_LINE"
[[ "$WT_branch" == "(detached)" ]] && test_pass || test_fail

# ============================================================================
# wt_worktree_create tests
# ============================================================================

test_start "wt_worktree_create creates valid line"
result=$(wt_worktree_create "feature/x" "/tmp/wt" "0" "0" "sha789")
[[ "$result" == $'feature/x\t/tmp/wt\t0\t0\tsha789' ]] && test_pass || test_fail

test_start "wt_worktree_create uses defaults for optional fields"
result=$(wt_worktree_create "main" "/tmp/main")
expected=$'main\t/tmp/main\t0\t0\t'
[[ "$result" == "$expected" ]] && test_pass || test_fail "Expected '$expected', got '$result'"

# ============================================================================
# wt_worktree_is_detached tests
# ============================================================================

test_start "wt_worktree_is_detached returns true for detached"
wt_worktree_is_detached "$DETACHED_LINE" && test_pass || test_fail

test_start "wt_worktree_is_detached returns false for attached"
wt_worktree_is_detached "$SAMPLE_LINE" && test_fail || test_pass

# ============================================================================
# wt_worktree_is_bare tests
# ============================================================================

test_start "wt_worktree_is_bare returns true for bare"
wt_worktree_is_bare "$BARE_LINE" && test_pass || test_fail

test_start "wt_worktree_is_bare returns false for non-bare"
wt_worktree_is_bare "$SAMPLE_LINE" && test_fail || test_pass

# ============================================================================
# Round-trip test
# ============================================================================

test_start "Round-trip: create then parse produces same values"
created=$(wt_worktree_create "test/branch" "/test/path" "0" "1" "abc")
wt_worktree_parse "$created" RT
[[ "$RT_branch" == "test/branch" && "$RT_path" == "/test/path" && "$RT_detached" == "1" ]] && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

