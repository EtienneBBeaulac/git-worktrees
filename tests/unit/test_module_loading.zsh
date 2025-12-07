#!/usr/bin/env zsh
# Unit tests for module loading and source guard
# Verifies that the critical fixes are working

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing module loading and source guard"

# ============================================================================
# Source Guard Tests
# ============================================================================

test_start "Source guard prevents double loading"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  [[ "$__WT_LIB_LOADED" == "1" ]] || exit 1
  
  # Source again - should return early
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  [[ "$__WT_LIB_LOADED" == "1" ]] || exit 1
) && test_pass || test_fail

test_start "__WT_LIB_DIR is set correctly"
(
  unset __WT_LIB_LOADED __WT_LIB_DIR
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  [[ "$__WT_LIB_DIR" == "$ROOT_DIR/scripts/lib" ]] || exit 1
) && test_pass || test_fail

# ============================================================================
# Required Module Loading Tests
# ============================================================================

test_start "Recovery module is loaded (not stub)"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  # The real implementation checks WT_NO_RECOVERY env var
  # The stub always returns 1
  # So if recovery is enabled (default), we get the real implementation
  wt_recovery_enabled || exit 1
) && test_pass || test_fail

test_start "Validation module is loaded (not stub)"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  # Real implementation sanitizes; stub just returns input unchanged
  local result=$(wt_sanitize_branch_name "my@bad..branch")
  [[ "$result" != "my@bad..branch" ]] || exit 1
) && test_pass || test_fail

test_start "Discovery module is loaded (not stub)"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  # Real implementation outputs text; stub is a no-op
  local output=$(wt_show_contextual_help branch_selection 2>&1)
  [[ -n "$output" ]] || exit 1
) && test_pass || test_fail

test_start "Transaction functions are real implementations"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/lib/wt-common.zsh"
  # Check function body - real implementation has actual code
  local body=$(typeset -f wt_transaction_begin)
  [[ "$body" == *"mkdir"* ]] || exit 1  # Real impl creates dirs
) && test_pass || test_fail

# ============================================================================
# Module Failure Tests
# ============================================================================

test_start "Missing module causes loud failure"
(
  unset __WT_LIB_LOADED
  # Create temp dir with only wt-common.zsh, missing other modules
  local tmp=$(mktemp -d)
  cp "$ROOT_DIR/scripts/lib/wt-common.zsh" "$tmp/"
  
  # Sourcing should fail because modules are missing
  local output
  output=$(source "$tmp/wt-common.zsh" 2>&1) && exit 1  # Should fail
  [[ "$output" == *"FATAL"* ]] || exit 1  # Should have FATAL error
  rm -rf "$tmp"
) && test_pass || test_fail

# ============================================================================
# Script Loading Tests
# ============================================================================

test_start "Scripts source wt-common.zsh correctly"
(
  for script in wt wtnew wtrm wtopen wtls; do
    unset __WT_LIB_LOADED
    source "$ROOT_DIR/scripts/$script"
    [[ "$__WT_LIB_LOADED" == "1" ]] || exit 1
    typeset -f "$script" >/dev/null || exit 1
  done
) && test_pass || test_fail

test_start "Scripts have all module functions available"
(
  unset __WT_LIB_LOADED
  source "$ROOT_DIR/scripts/wt"
  
  # Check key functions from each module are available
  typeset -f wt_recovery_enabled >/dev/null || exit 1  # recovery
  typeset -f wt_validate_branch_name >/dev/null || exit 1  # validation
  typeset -f wt_show_hints >/dev/null || exit 1  # discovery
) && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

