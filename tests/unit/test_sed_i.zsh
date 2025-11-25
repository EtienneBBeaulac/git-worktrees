#!/usr/bin/env zsh
# Unit tests for wt_sed_i() cross-platform sed wrapper
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_sed_i()"

# Setup temp file for tests
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

# Test 1: Basic substitution
test_start "wt_sed_i performs basic substitution"
echo "hello world" > "$TEMP_FILE"
wt_sed_i 's/world/zsh/' "$TEMP_FILE"
[[ "$(cat "$TEMP_FILE")" == "hello zsh" ]] && test_pass || test_fail "Expected 'hello zsh'"

# Test 2: Multiple lines
test_start "wt_sed_i works with multiple lines"
printf "line1\nline2\nline3\n" > "$TEMP_FILE"
wt_sed_i 's/line2/REPLACED/' "$TEMP_FILE"
[[ "$(sed -n '2p' "$TEMP_FILE")" == "REPLACED" ]] && test_pass || test_fail

# Test 3: Pattern with special characters (using | delimiter)
test_start "wt_sed_i handles patterns with special delimiters"
echo "KEY=old_value" > "$TEMP_FILE"
wt_sed_i 's|^KEY=.*|KEY=new_value|' "$TEMP_FILE"
[[ "$(cat "$TEMP_FILE")" == "KEY=new_value" ]] && test_pass || test_fail

# Test 4: No match doesn't corrupt file
test_start "wt_sed_i preserves file when no match"
echo "original content" > "$TEMP_FILE"
wt_sed_i 's/nonexistent/replacement/' "$TEMP_FILE"
[[ "$(cat "$TEMP_FILE")" == "original content" ]] && test_pass || test_fail

# Test 5: Empty file handling
test_start "wt_sed_i handles empty file"
: > "$TEMP_FILE"
wt_sed_i 's/anything/something/' "$TEMP_FILE"
[[ ! -s "$TEMP_FILE" ]] && test_pass || test_fail "File should remain empty"

# Test 6: Global replacement
test_start "wt_sed_i with global flag"
echo "aaa bbb aaa" > "$TEMP_FILE"
wt_sed_i 's/aaa/XXX/g' "$TEMP_FILE"
[[ "$(cat "$TEMP_FILE")" == "XXX bbb XXX" ]] && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

