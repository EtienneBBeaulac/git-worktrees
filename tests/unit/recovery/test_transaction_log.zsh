#!/usr/bin/env zsh
# Unit tests for wt-recovery.zsh - Transaction log
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-recovery.zsh"

test_suite_init "wt-recovery: Transaction Log"

# Setup
TEST_CACHE_DIR=$(make_temp_dir)
WT_TRANSACTION_LOG="$TEST_CACHE_DIR/transaction.log"

# Test: Begin transaction
test_start "wt_transaction_begin creates log file"
wt_transaction_begin
assert_file_exists "$WT_TRANSACTION_LOG"
test_pass

# Test: Record actions
test_start "wt_transaction_record appends to log"
wt_transaction_begin
wt_transaction_record "worktree_add" "/path/to/worktree"
wt_transaction_record "branch_create" "feature/test"
content=$(cat "$WT_TRANSACTION_LOG")
[[ "$content" == *"worktree_add|/path/to/worktree"* ]] || test_fail "Missing worktree_add"
[[ "$content" == *"branch_create|feature/test"* ]] || test_fail "Missing branch_create"
test_pass

# Test: Commit transaction
test_start "wt_transaction_commit removes log file"
wt_transaction_begin
wt_transaction_record "test_action" "test_details"
assert_file_exists "$WT_TRANSACTION_LOG"
wt_transaction_commit
assert_file_not_exists "$WT_TRANSACTION_LOG"
test_pass

# Test: Transaction active flag
test_start "WT_TRANSACTION_ACTIVE flag is set correctly"
[[ $WT_TRANSACTION_ACTIVE -eq 0 ]] || test_fail "Should start inactive"
wt_transaction_begin
[[ $WT_TRANSACTION_ACTIVE -eq 1 ]] || test_fail "Should be active after begin"
wt_transaction_commit
[[ $WT_TRANSACTION_ACTIVE -eq 0 ]] || test_fail "Should be inactive after commit"
test_pass

# Test: Record only when active
test_start "wt_transaction_record is no-op when inactive"
rm -f "$WT_TRANSACTION_LOG"
WT_TRANSACTION_ACTIVE=0
wt_transaction_record "test_action" "should_not_appear"
[[ ! -f "$WT_TRANSACTION_LOG" ]] || test_fail "Should not create log when inactive"
test_pass

# Test: Rollback with mock Git operations
test_start "wt_transaction_rollback processes log in reverse"
test_repo=$(make_temp_dir)
cd "$test_repo"
git init -q
make_commit "initial"

wt_transaction_begin
test_branch="test_branch_$$"
git branch "$test_branch" 2>/dev/null
wt_transaction_record "branch_create" "$test_branch"

# Rollback should delete the branch
wt_transaction_rollback 2>/dev/null

# Check branch is gone
if git show-ref --verify --quiet "refs/heads/$test_branch"; then
  test_fail "Branch should be deleted"
else
  test_pass
fi

cd - > /dev/null
rm -rf "$test_repo"

# Cleanup
rm -rf "$TEST_CACHE_DIR"

test_suite_summary

