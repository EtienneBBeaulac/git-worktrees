#!/usr/bin/env zsh
# Unit tests for wt-recovery.zsh - Error diagnosis
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-recovery.zsh"

test_suite_init "wt-recovery: Error Diagnosis"

# Test: Diagnose network errors
test_start "wt_diagnose_error detects network_failure"
output="fatal: Could not resolve host: github.com"
result=$(wt_diagnose_error "git fetch" "$output" 1)
assert_equals "network_failure" "$result"
test_pass

test_start "wt_diagnose_error detects network unreachable"
output="fatal: Network is unreachable"
result=$(wt_diagnose_error "git push" "$output" 1)
assert_equals "network_failure" "$result"
test_pass

# Test: Diagnose permission errors
test_start "wt_diagnose_error detects permission_denied"
output="fatal: Permission denied (publickey)"
result=$(wt_diagnose_error "git clone" "$output" 128)
assert_equals "permission_denied" "$result"
test_pass

# Test: Diagnose disk space errors
test_start "wt_diagnose_error detects disk_space"
output="fatal: No space left on device"
result=$(wt_diagnose_error "git add" "$output" 128)
assert_equals "disk_space" "$result"
test_pass

# Test: Diagnose already exists errors
test_start "wt_diagnose_error detects already_exists"
output="fatal: 'worktrees/feature' already exists"
result=$(wt_diagnose_error "git worktree add" "$output" 128)
assert_equals "already_exists" "$result"
test_pass

# Test: Diagnose already checked out
test_start "wt_diagnose_error detects already_checked_out"
output="fatal: 'feature' is already checked out at '/path/to/worktree'"
result=$(wt_diagnose_error "git worktree add" "$output" 128)
assert_equals "already_checked_out" "$result"
test_pass

# Test: Diagnose invalid name
test_start "wt_diagnose_error detects invalid_name"
output="fatal: 'feat@#$' is not a valid branch name"
result=$(wt_diagnose_error "git branch" "$output" 128)
assert_equals "invalid_name" "$result"
test_pass

# Test: Diagnose not found
test_start "wt_diagnose_error detects not_found"
output="error: pathspec 'nonexistent' did not match any file(s) known to git"
result=$(wt_diagnose_error "git checkout" "$output" 1)
assert_equals "not_found" "$result"
test_pass

# Test: Diagnose dirty worktree
test_start "wt_diagnose_error detects dirty_worktree"
output="error: Your local changes to the following files would be overwritten by checkout"
result=$(wt_diagnose_error "git checkout" "$output" 1)
assert_equals "dirty_worktree" "$result"
test_pass

# Test: Unknown errors
test_start "wt_diagnose_error returns unknown for unrecognized errors"
output="Something completely unexpected happened"
result=$(wt_diagnose_error "git status" "$output" 1)
assert_equals "unknown" "$result"
test_pass

# Test: Error messages
test_start "wt_error_message returns correct message for network_failure"
msg=$(wt_error_message "network_failure")
[[ "$msg" == *"Network connection failed"* ]] || test_fail "Wrong message: $msg"
test_pass

test_start "wt_error_message returns correct message for permission_denied"
msg=$(wt_error_message "permission_denied")
[[ "$msg" == *"Permission denied"* ]] || test_fail "Wrong message: $msg"
test_pass

test_start "wt_error_message returns correct message for already_exists"
msg=$(wt_error_message "already_exists")
[[ "$msg" == *"already exists"* ]] || test_fail "Wrong message: $msg"
test_pass

test_start "wt_error_message returns generic message for unknown"
msg=$(wt_error_message "unknown")
[[ "$msg" == *"An error occurred"* ]] || test_fail "Wrong message: $msg"
test_pass

test_suite_summary

