#!/usr/bin/env zsh
# Test Phase 2: Config management

set -e

echo "Testing Phase 2: Config management"

# Setup
SCRIPT_DIR="${0:A:h}/../scripts"
source "${SCRIPT_DIR}/lib/wt-common.zsh"
source "${SCRIPT_DIR}/wt"

# Test 1: wt_init_config function exists
echo -n "  • wt_init_config exists... "
if typeset -f wt_init_config >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 2: wt_load_full_config function exists
echo -n "  • wt_load_full_config exists... "
if typeset -f wt_load_full_config >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 3: wt_detect_editor function exists
echo -n "  • wt_detect_editor exists... "
if typeset -f wt_detect_editor >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 4: wt_get_editor function exists
echo -n "  • wt_get_editor exists... "
if typeset -f wt_get_editor >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 5: Config file creation
echo -n "  • Config can be created... "
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
if wt_init_config 2>&1 | grep -q "Created config file"; then
  if [[ -f "$TEST_HOME/.config/git-worktrees/config" ]]; then
    echo "✓"
  else
    echo "✗ FAILED (file not created)"
    rm -rf "$TEST_HOME"
    exit 1
  fi
else
  echo "✗ FAILED"
  rm -rf "$TEST_HOME"
  exit 1
fi

# Test 6: Config contains expected sections
echo -n "  • Config has required sections... "
if grep -q "\[editor\]" "$TEST_HOME/.config/git-worktrees/config" 2>/dev/null || \
   grep -q "editor=" "$TEST_HOME/.config/git-worktrees/config"; then
  if grep -q "behavior.autoopen" "$TEST_HOME/.config/git-worktrees/config" && \
     grep -q "ui.fzfheight" "$TEST_HOME/.config/git-worktrees/config"; then
    echo "✓"
  else
    echo "✗ FAILED (missing sections)"
    rm -rf "$TEST_HOME"
    exit 1
  fi
else
  echo "✗ FAILED (no editor section)"
  rm -rf "$TEST_HOME"
  exit 1
fi

# Cleanup
rm -rf "$TEST_HOME"

echo ""
echo "Phase 2 config tests: PASSED ✓"

