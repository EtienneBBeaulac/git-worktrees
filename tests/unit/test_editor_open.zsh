#!/usr/bin/env zsh
# Unit tests for wt_open_in_editor() IDE opening logic
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_open_in_editor()"

# Setup temp directory with project structures
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create test directories
PLAIN_DIR="$TEMP_DIR/plain"
IDEA_DIR="$TEMP_DIR/idea-project"
GRADLE_DIR="$TEMP_DIR/gradle-project"
GRADLE_KTS_DIR="$TEMP_DIR/gradle-kts-project"

mkdir -p "$PLAIN_DIR"
mkdir -p "$IDEA_DIR/.idea"
mkdir -p "$GRADLE_DIR"
echo "" > "$GRADLE_DIR/settings.gradle"
mkdir -p "$GRADLE_KTS_DIR"
echo "" > "$GRADLE_KTS_DIR/settings.gradle.kts"

# We can't easily test actual editor launching, but we can test the logic
# by using WT_PREFER_XDG_OPEN which triggers xdg-open (which we'll stub)

# Stub xdg-open to record what it was called with
CALL_LOG="$TEMP_DIR/call_log"
: > "$CALL_LOG"

# Create a fake xdg-open
FAKE_BIN="$TEMP_DIR/bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/xdg-open" <<'SCRIPT'
#!/bin/sh
echo "$1" >> "$CALL_LOG"
SCRIPT
chmod +x "$FAKE_BIN/xdg-open"
export PATH="$FAKE_BIN:$PATH"
export CALL_LOG
export WT_PREFER_XDG_OPEN=1

# ============================================================================
# Tests (via xdg-open stub)
# ============================================================================

test_start "wt_open_in_editor opens plain directory"
: > "$CALL_LOG"
wt_open_in_editor "$PLAIN_DIR" "TestEditor"
result=$(cat "$CALL_LOG")
[[ "$result" == "$PLAIN_DIR" ]] && test_pass || test_fail "Expected '$PLAIN_DIR', got '$result'"

test_start "wt_open_in_editor returns early when app is 'none'"
: > "$CALL_LOG"
wt_open_in_editor "$PLAIN_DIR" "none"
result=$(cat "$CALL_LOG")
[[ -z "$result" ]] && test_pass || test_fail "Should not call xdg-open for 'none'"

test_start "wt_open_in_editor returns early when app is empty"
: > "$CALL_LOG"
# Override wt_get_editor to return empty
wt_get_editor() { echo ""; }
wt_open_in_editor "$PLAIN_DIR" ""
result=$(cat "$CALL_LOG")
[[ -z "$result" ]] && test_pass || test_fail "Should not call xdg-open for empty app"

# Note: The project file detection tests would require removing WT_PREFER_XDG_OPEN
# and mocking `open -a` which is harder to do. The detection logic is tested
# implicitly through E2E tests.

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

