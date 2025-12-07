#!/usr/bin/env zsh
# Integration test for install.sh
# Verifies that install creates the correct structure with all modules

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing install.sh structure"

# Create isolated test environment
TEST_TMP=$(mktemp -d)
trap "rm -rf '$TEST_TMP'" EXIT

# ============================================================================
# Install Tests
# ============================================================================

test_start "install.sh runs successfully"
(
  HOME="$TEST_TMP" REPO_RAW="file://$ROOT_DIR" bash "$ROOT_DIR/install.sh" --yes --quiet >/dev/null 2>&1
) && test_pass || test_fail

INSTALL_DIR="$TEST_TMP/.zsh/functions/git-worktrees"

test_start "Install directory exists"
[[ -d "$INSTALL_DIR" ]] && test_pass || test_fail

test_start "lib/ subdirectory exists"
[[ -d "$INSTALL_DIR/lib" ]] && test_pass || test_fail

# ============================================================================
# Main Scripts Tests
# ============================================================================

test_start "wt script installed"
[[ -f "$INSTALL_DIR/wt" ]] && test_pass || test_fail

test_start "wtnew script installed"
[[ -f "$INSTALL_DIR/wtnew" ]] && test_pass || test_fail

test_start "wtrm script installed"
[[ -f "$INSTALL_DIR/wtrm" ]] && test_pass || test_fail

test_start "wtopen script installed"
[[ -f "$INSTALL_DIR/wtopen" ]] && test_pass || test_fail

test_start "wtls script installed"
[[ -f "$INSTALL_DIR/wtls" ]] && test_pass || test_fail

# ============================================================================
# Library Module Tests (Critical Fix Verification)
# ============================================================================

test_start "wt-common.zsh installed"
[[ -f "$INSTALL_DIR/lib/wt-common.zsh" ]] && test_pass || test_fail

test_start "wt-recovery.zsh installed (was missing before fix)"
[[ -f "$INSTALL_DIR/lib/wt-recovery.zsh" ]] && test_pass || test_fail

test_start "wt-validation.zsh installed (was missing before fix)"
[[ -f "$INSTALL_DIR/lib/wt-validation.zsh" ]] && test_pass || test_fail

test_start "wt-discovery.zsh installed (was missing before fix)"
[[ -f "$INSTALL_DIR/lib/wt-discovery.zsh" ]] && test_pass || test_fail

# ============================================================================
# Functional Tests
# ============================================================================

test_start "Installed scripts can be sourced"
(
  source "$INSTALL_DIR/wt"
  typeset -f wt >/dev/null
) && test_pass || test_fail

test_start "Modules are loaded (not stubs) after install"
(
  source "$INSTALL_DIR/wt"
  # Real wt_recovery_enabled returns 0 by default
  # Stub returns 1
  wt_recovery_enabled
) && test_pass || test_fail

test_start "Validation module works after install"
(
  source "$INSTALL_DIR/wtnew"
  local result=$(wt_sanitize_branch_name "bad@name..here")
  [[ "$result" != "bad@name..here" ]]  # Should be sanitized
) && test_pass || test_fail

test_start "Discovery module works after install"
(
  source "$INSTALL_DIR/wtopen"
  local output=$(wt_show_contextual_help branch_selection 2>&1)
  [[ -n "$output" ]]  # Should produce output
) && test_pass || test_fail

# ============================================================================
# .zshrc Integration Tests
# ============================================================================

test_start ".zshrc updated with correct paths"
(
  grep -q "git-worktrees/wt" "$TEST_TMP/.zshrc"
) && test_pass || test_fail

test_start ".zshrc sources from correct location"
(
  # The source lines should reference the new path structure
  grep -q "~/.zsh/functions/git-worktrees/wt" "$TEST_TMP/.zshrc" || \
  grep -q "\$HOME/.zsh/functions/git-worktrees/wt" "$TEST_TMP/.zshrc"
) && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

