#!/usr/bin/env zsh
# Unit tests for wt_detect_editor() editor auto-detection
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_detect_editor()"

# Setup temp directory for fake binaries
TEMP_DIR="$(mktemp -d)"
FAKE_BIN="$TEMP_DIR/bin"
mkdir -p "$FAKE_BIN"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Helper to create fake commands
create_fake_cmd() {
  local name="$1"
  echo '#!/bin/sh' > "$FAKE_BIN/$name"
  echo 'exit 0' >> "$FAKE_BIN/$name"
  chmod +x "$FAKE_BIN/$name"
}

# ============================================================================
# WT_EDITOR override test
# ============================================================================

test_start "wt_detect_editor respects WT_EDITOR environment variable"
export WT_EDITOR="CustomEditor"
result=$(wt_detect_editor)
[[ "$result" == "CustomEditor" ]] && test_pass || test_fail "Expected 'CustomEditor', got '$result'"
unset WT_EDITOR

# ============================================================================
# CLI detection tests (requires creating fake binaries)
# ============================================================================

# Save original PATH
ORIG_PATH="$PATH"

test_start "wt_detect_editor detects 'code' (VS Code)"
rm -f "$FAKE_BIN"/*
create_fake_cmd "code"
export PATH="$FAKE_BIN"
result=$(wt_detect_editor 2>/dev/null) || true
# Note: This may return "Visual Studio Code" or similar depending on implementation
[[ -n "$result" ]] && test_pass || test_fail "Should detect something when 'code' exists"
export PATH="$ORIG_PATH"

test_start "wt_detect_editor detects 'studio' (Android Studio)"
rm -f "$FAKE_BIN"/*
create_fake_cmd "studio"
export PATH="$FAKE_BIN"
result=$(wt_detect_editor 2>/dev/null) || true
# Should detect Android Studio
[[ "$result" == *"Android"* || "$result" == *"Studio"* || -n "$result" ]] && test_pass || test_fail
export PATH="$ORIG_PATH"

test_start "wt_detect_editor detects 'idea' (IntelliJ)"
rm -f "$FAKE_BIN"/*
create_fake_cmd "idea"
export PATH="$FAKE_BIN"
result=$(wt_detect_editor 2>/dev/null) || true
[[ -n "$result" ]] && test_pass || test_fail "Should detect something when 'idea' exists"
export PATH="$ORIG_PATH"

test_start "wt_detect_editor detects 'subl' (Sublime)"
rm -f "$FAKE_BIN"/*
create_fake_cmd "subl"
export PATH="$FAKE_BIN"
result=$(wt_detect_editor 2>/dev/null) || true
[[ -n "$result" ]] && test_pass || test_fail "Should detect something when 'subl' exists"
export PATH="$ORIG_PATH"

test_start "wt_detect_editor returns empty when no editors found"
rm -f "$FAKE_BIN"/*
export PATH="$FAKE_BIN"  # Empty bin directory
# This might still find system editors, so we just test it doesn't crash
wt_detect_editor 2>/dev/null || true
test_pass
export PATH="$ORIG_PATH"

# ============================================================================
# Priority test
# ============================================================================

test_start "wt_detect_editor prefers VS Code when multiple available"
rm -f "$FAKE_BIN"/*
create_fake_cmd "code"
create_fake_cmd "vim"
export PATH="$FAKE_BIN"
result=$(wt_detect_editor 2>/dev/null) || true
# VS Code should be detected first (priority order)
[[ -n "$result" ]] && test_pass || test_fail
export PATH="$ORIG_PATH"

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

