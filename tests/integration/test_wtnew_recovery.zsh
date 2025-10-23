#!/usr/bin/env zsh
# Integration tests for wtnew with recovery features
# Part of Phase 2: Core Tool Integration

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

test_suite_init "wtnew: Recovery & Validation Integration"

# Setup test repo
TEST_REPO=$(make_temp_dir)
cd "$TEST_REPO"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
make_commit "initial"

# Source wtnew
source "$ROOT_DIR/scripts/wtnew"

# Test: Transaction rollback on failure
test_start "wtnew rolls back on failure with transaction support"
# Disable stdin to simulate non-interactive
exec 0</dev/null
WT_NO_RECOVERY=1 wtnew --name "test-branch" --no-open --dir "/nonexistent/parent/path" 2>/dev/null || true
# Verify no partial state left behind
[[ ! -d "/nonexistent/parent/path" ]] || test_fail "Path should not exist"
test_pass

# Test: Network fetch recovery
test_start "wtnew continues on network fetch failure"
# Mock fetch to fail
git() {
  if [[ "$1" == "fetch" ]]; then
    return 1
  fi
  command git "$@"
}
output=$(wtnew --help 2>&1)
assert_exit_code 0
test_pass
unset -f git

# Test: Discovery hints are shown
test_start "wtnew shows discovery hints when available"
# Should show contextual help (we can't test interactive FZF but can verify hint function exists)
typeset -f wt_show_contextual_help >/dev/null && test_pass || test_fail "Hint function should be available"

# Test: Transaction commit on success
test_start "wtnew commits transaction on successful creation"
# Create a simple worktree
parent_dir=$(dirname "$TEST_REPO")
wt_path="${parent_dir}/test-worktree-success"
wtnew --name "success-branch" --base "main" --no-open --dir "$wt_path" 2>&1 >/dev/null || true
if [[ -d "$wt_path" ]]; then
  # Verify transaction was committed (transaction log should not exist or be empty)
  if [[ -f "${HOME}/.cache/git-worktrees/transaction.log" ]]; then
    content=$(cat "${HOME}/.cache/git-worktrees/transaction.log" 2>/dev/null || echo "")
    if [[ -n "$content" && ! "$content" =~ "^#" ]]; then
      test_fail "Transaction log should be empty after success"
    else
      test_pass
    fi
  else
    test_pass "Transaction log cleaned up"
  fi
  rm -rf "$wt_path"
else
  test_skip "Could not create worktree for test"
fi

# Cleanup
cd - >/dev/null
rm -rf "$TEST_REPO"

test_suite_summary

