#!/usr/bin/env zsh
# Unit tests for wt_load_config() and wt_get_config()
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_load_config() and wt_get_config()"

# Setup temp config directory
ORIG_HOME="$HOME"
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
trap 'rm -rf "$TEST_HOME"; export HOME="$ORIG_HOME"' EXIT

CONFIG_DIR="$HOME/.config/git-worktrees"
CONFIG_FILE="$CONFIG_DIR/config"

# ============================================================================
# wt_load_config tests
# ============================================================================

# Reset for each test
reset_config() {
  typeset -gA WT_CONFIG=()
  rm -rf "$CONFIG_DIR"
}

test_start "wt_load_config handles missing config file gracefully"
reset_config
wt_load_config 2>/dev/null && test_pass || test_fail

test_start "wt_load_config reads key=value pairs"
reset_config
mkdir -p "$CONFIG_DIR"
echo "TEST_KEY=test_value" > "$CONFIG_FILE"
wt_load_config
[[ "${WT_CONFIG[TEST_KEY]}" == "test_value" ]] && test_pass || test_fail "Expected 'test_value'"

test_start "wt_load_config reads multiple keys"
reset_config
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<'EOF'
KEY1=value1
KEY2=value2
KEY3=value3
EOF
wt_load_config
[[ "${WT_CONFIG[KEY1]}" == "value1" && "${WT_CONFIG[KEY2]}" == "value2" && "${WT_CONFIG[KEY3]}" == "value3" ]] && test_pass || test_fail

test_start "wt_load_config ignores comment lines"
reset_config
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<'EOF'
# This is a comment
KEY=value
# Another comment
EOF
wt_load_config
[[ "${WT_CONFIG[KEY]}" == "value" && -z "${WT_CONFIG[#]:-}" ]] && test_pass || test_fail

test_start "wt_load_config ignores empty lines"
reset_config
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<'EOF'

KEY=value

EOF
wt_load_config
[[ "${WT_CONFIG[KEY]}" == "value" ]] && test_pass || test_fail

test_start "wt_load_config trims whitespace from keys"
reset_config
mkdir -p "$CONFIG_DIR"
echo "  SPACED_KEY  =value" > "$CONFIG_FILE"
wt_load_config
[[ "${WT_CONFIG[SPACED_KEY]}" == "value" ]] && test_pass || test_fail "Key with spaces not trimmed correctly"

test_start "wt_load_config handles values with equals signs"
reset_config
mkdir -p "$CONFIG_DIR"
echo "KEY=value=with=equals" > "$CONFIG_FILE"
wt_load_config
[[ "${WT_CONFIG[KEY]}" == "value=with=equals" ]] && test_pass || test_fail

# ============================================================================
# wt_get_config tests
# ============================================================================

test_start "wt_get_config returns value for existing key"
reset_config
WT_CONFIG[EXISTING]=found
result=$(wt_get_config EXISTING)
[[ "$result" == "found" ]] && test_pass || test_fail "Expected 'found', got '$result'"

test_start "wt_get_config returns empty for missing key"
reset_config
result=$(wt_get_config NONEXISTENT)
[[ -z "$result" ]] && test_pass || test_fail "Expected empty"

test_start "wt_get_config returns default for missing key"
reset_config
result=$(wt_get_config NONEXISTENT "default_value")
[[ "$result" == "default_value" ]] && test_pass || test_fail "Expected 'default_value'"

test_start "wt_get_config prefers existing value over default"
reset_config
WT_CONFIG[KEY]=actual
result=$(wt_get_config KEY "default")
[[ "$result" == "actual" ]] && test_pass || test_fail "Expected 'actual', got '$result'"

test_start "wt_get_config with empty default"
reset_config
result=$(wt_get_config MISSING "")
[[ -z "$result" ]] && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

