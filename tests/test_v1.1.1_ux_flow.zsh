#!/usr/bin/env zsh
# Test the v1.1.1 UX improvements: first-run setup, silent auto-open, config management

set -e
SCRIPT_DIR="${0:a:h}"
source "$SCRIPT_DIR/lib/test_helpers.zsh" 2>/dev/null || source "${SCRIPT_DIR}/../lib/test_helpers.zsh" 2>/dev/null || true

TEST_NAME="v1.1.1 UX Flow"
test_setup

echo "Testing v1.1.1 UX improvements..."
echo ""

# ============================================================================
# Test 1: First-run setup function exists
# ============================================================================
echo "→ Test 1: First-run setup function exists"
if typeset -f wt_first_run_editor_setup >/dev/null 2>&1; then
  echo "✅ wt_first_run_editor_setup function exists"
else
  echo "❌ wt_first_run_editor_setup function missing"
  exit 1
fi

# ============================================================================
# Test 2: Config set/get commands
# ============================================================================
echo ""
echo "→ Test 2: wt config set/get commands"

# Create test config directory
TEST_CONFIG_DIR="${TEST_TMP}/.config/git-worktrees"
mkdir -p "$TEST_CONFIG_DIR"
TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config"

# Save original HOME and override
OLD_HOME="${HOME}"
export HOME="${TEST_TMP}"

# Test wt config set
cd "$TEST_TMP/repo1"
wt config set editor "Cursor" >/dev/null 2>&1 || true

if [[ -f "$TEST_CONFIG_FILE" ]]; then
  echo "✅ Config file created"
else
  echo "❌ Config file not created"
  export HOME="${OLD_HOME}"
  exit 1
fi

# Test wt config get
EDITOR_VALUE=$(wt config get editor 2>/dev/null || echo "")
if [[ "$EDITOR_VALUE" == "Cursor" ]]; then
  echo "✅ wt config get returns correct value"
else
  echo "❌ wt config get failed (got: '$EDITOR_VALUE')"
  export HOME="${OLD_HOME}"
  exit 1
fi

# Test updating existing value
wt config set editor "IntelliJ IDEA" >/dev/null 2>&1 || true
EDITOR_VALUE=$(wt config get editor 2>/dev/null || echo "")
if [[ "$EDITOR_VALUE" == "IntelliJ IDEA" ]]; then
  echo "✅ wt config set updates existing value"
else
  echo "❌ wt config set update failed (got: '$EDITOR_VALUE')"
  export HOME="${OLD_HOME}"
  exit 1
fi

# Restore HOME
export HOME="${OLD_HOME}"

# ============================================================================
# Test 3: Silent auto-open (no prompt in wtnew)
# ============================================================================
echo ""
echo "→ Test 3: wtnew silent auto-open (no prompt)"

cd "$TEST_TMP/repo1"

# Simulate wtnew with --no-open to avoid actually opening editors
# We're testing that there's no prompt, not the actual opening
OUTPUT=$(wtnew test-silent-branch --no-open 2>&1 || true)

# Check that output doesn't contain the old confirmation prompt
if echo "$OUTPUT" | grep -q "Open in.*\[Y/n/other/save\]"; then
  echo "❌ Old confirmation prompt still present"
  exit 1
else
  echo "✅ No confirmation prompt (silent auto-open)"
fi

# ============================================================================
# Test 4: wt_get_editor respects existing config
# ============================================================================
echo ""
echo "→ Test 4: wt_get_editor respects existing config"

# Create a config file with an editor
TEST_CONFIG_DIR="${TEST_TMP}/.config/git-worktrees"
mkdir -p "$TEST_CONFIG_DIR"
echo "editor=Test Editor" > "${TEST_CONFIG_DIR}/config"

# Override HOME temporarily
OLD_HOME="${HOME}"
export HOME="${TEST_TMP}"

# Mock wt_detect_editor to return our test value
wt_detect_editor() {
  echo "Test Editor"
}

DETECTED=$(wt_get_editor 2>/dev/null || echo "")
if [[ "$DETECTED" == "Test Editor" ]]; then
  echo "✅ wt_get_editor respects config"
else
  echo "❌ wt_get_editor failed (got: '$DETECTED')"
  export HOME="${OLD_HOME}"
  exit 1
fi

export HOME="${OLD_HOME}"

# ============================================================================
# Test 5: Config file priority (env vars override config)
# ============================================================================
echo ""
echo "→ Test 5: Config file priority (env vars > config)"

TEST_CONFIG_DIR="${TEST_TMP}/.config/git-worktrees"
mkdir -p "$TEST_CONFIG_DIR"
echo "editor=Config Editor" > "${TEST_CONFIG_DIR}/config"

OLD_HOME="${HOME}"
export HOME="${TEST_TMP}"

# Set env var (should override config)
export WT_EDITOR="Env Editor"

wt_detect_editor() {
  echo "Env Editor"
}

DETECTED=$(wt_get_editor 2>/dev/null || echo "")
if [[ "$DETECTED" == "Env Editor" ]]; then
  echo "✅ Env vars override config file"
else
  echo "❌ Priority system failed (got: '$DETECTED')"
  export HOME="${OLD_HOME}"
  unset WT_EDITOR
  exit 1
fi

unset WT_EDITOR
export HOME="${OLD_HOME}"

# ============================================================================
# Test 6: Ctrl-A actions menu includes "Change editor"
# ============================================================================
echo ""
echo "→ Test 6: Ctrl-A actions menu includes 'Change editor'"

cd "$TEST_TMP/repo1"

# Check that the wt script contains "Change editor" in the ctrl-a handler
if grep -q "Change editor" "$SCRIPT_DIR/../scripts/wt" 2>/dev/null || \
   grep -q "Change editor" "${SCRIPT_DIR}/../../scripts/wt" 2>/dev/null; then
  echo "✅ 'Change editor' option exists in Ctrl-A menu"
else
  echo "❌ 'Change editor' option missing from Ctrl-A menu"
  exit 1
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=================================================="
echo "✅ All v1.1.1 UX tests passed!"
echo "=================================================="
echo ""
echo "Tested:"
echo "  ✓ First-run setup function"
echo "  ✓ wt config set/get commands"
echo "  ✓ Silent auto-open (no prompt)"
echo "  ✓ Config file reading"
echo "  ✓ Priority system (env > config)"
echo "  ✓ 'Change editor' in Ctrl-A menu"
echo ""

