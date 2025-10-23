#!/usr/bin/env zsh
# Integration test: Verify all modules work together
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

# Source wt-common which should load all new modules
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

test_suite_init "Integration: All Modules"

# Test: All modules are loaded
test_start "Recovery module functions are available"
typeset -f wt_retry >/dev/null && \
typeset -f wt_diagnose_error >/dev/null && \
typeset -f wt_save_session >/dev/null && \
test_pass || test_fail

test_start "Validation module functions are available"
typeset -f wt_validate_branch_name >/dev/null && \
typeset -f wt_sanitize_branch_name >/dev/null && \
typeset -f wt_fuzzy_match_branch >/dev/null && \
test_pass || test_fail

test_start "Discovery module functions are available"
typeset -f wt_show_contextual_help >/dev/null && \
typeset -f wt_cheatsheet >/dev/null && \
typeset -f wt_show_examples >/dev/null && \
test_pass || test_fail

# Test: Cross-module integration
test_start "Validation sanitization works end-to-end"
result=$(wt_sanitize_branch_name "my invalid@branch!")
[[ -n "$result" ]] || test_fail "Sanitization returned empty"
wt_validate_branch_name "$result" || test_fail "Sanitized name is still invalid"
test_pass

test_start "Error diagnosis and message generation work together"
error_output="fatal: Permission denied"
error_type=$(wt_diagnose_error "test" "$error_output" 1)
assert_equals "permission_denied" "$error_type"
message=$(wt_error_message "$error_type")
[[ "$message" == *"Permission"* ]] || test_fail "Message doesn't match error type"
test_pass

test_start "Session management works with temp directory"
TEST_SESSION_DIR=$(make_temp_dir)
WT_SESSION_DIR="$TEST_SESSION_DIR"
wt_save_session "test_tool" "key1=value1" "key2=value2"
output=$(wt_restore_session "test_tool")
[[ "$output" == *"key1=value1"* ]] || test_fail "Session restore failed"
rm -rf "$TEST_SESSION_DIR"
test_pass

test_start "Discovery features are accessible"
output=$(wt_cheatsheet commands 2>&1)
[[ "$output" == *"wt"* ]] || test_fail "Cheatsheet doesn't show commands"
output=$(wt_show_examples wtnew 2>&1)
[[ "$output" == *"wtnew"* ]] || test_fail "Examples don't show for wtnew"
test_pass

# Test: Original wt-common functions still work
test_start "Original wt_short_ref still works"
result=$(wt_short_ref "refs/heads/feature/test")
assert_equals "feature/test" "$result"
test_pass

test_start "Original wt_parse_worktrees_porcelain still works"
porcelain="worktree /path/to/worktree
branch refs/heads/main
"
result=$(wt_parse_worktrees_porcelain 0 "$porcelain")
[[ "$result" == *"main"* ]] || test_fail "Parse failed"
[[ "$result" == *"/path/to/worktree"* ]] || test_fail "Path missing"
test_pass

test_suite_summary

