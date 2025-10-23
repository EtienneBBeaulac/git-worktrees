#!/usr/bin/env zsh
# Unit tests for wt-recovery.zsh - Session state management
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-recovery.zsh"

test_suite_init "wt-recovery: Session State"

# Setup
TEST_SESSION_DIR=$(make_temp_dir)
WT_SESSION_DIR="$TEST_SESSION_DIR"

# Test: Save and restore session
test_start "wt_save_session creates session file"
wt_save_session "test_tool" "branch=feature/test" "action=create"
session_file="$WT_SESSION_DIR/test_tool_last.json"
assert_file_exists "$session_file"
test_pass

test_start "wt_restore_session retrieves saved values"
wt_save_session "test_tool2" "branch=main" "path=/tmp/test"
output=$(wt_restore_session "test_tool2")
[[ "$output" == *"branch=main"* ]] || test_fail "Missing branch"
[[ "$output" == *"path=/tmp/test"* ]] || test_fail "Missing path"
test_pass

# Test: Session freshness
test_start "wt_session_is_recent returns true for fresh session"
wt_save_session "test_tool3" "key=value"
if wt_session_is_recent "test_tool3"; then
  test_pass
else
  test_fail "Session should be recent"
fi

test_start "wt_session_is_recent returns false for old session"
# Create old session by manually setting old timestamp
wt_save_session "test_tool_old" "key=value"
old_file="$WT_SESSION_DIR/test_tool_old_last.json"
# Modify timestamp to be 2 hours old
sed -i.bak 's/"timestamp": [0-9]*/"timestamp": '$(($(date +%s) - 7200))'/' "$old_file"
if wt_session_is_recent "test_tool_old"; then
  test_fail "Session should not be recent"
else
  test_pass
fi

# Test: Clear session
test_start "wt_clear_session removes session file"
wt_save_session "test_tool_clear" "key=value"
clear_file="$WT_SESSION_DIR/test_tool_clear_last.json"
assert_file_exists "$clear_file"
wt_clear_session "test_tool_clear"
assert_file_not_exists "$clear_file"
test_pass

# Test: Non-existent session
test_start "wt_restore_session fails for non-existent session"
if wt_restore_session "nonexistent_tool" 2>/dev/null; then
  test_fail "Should fail for non-existent session"
else
  test_pass
fi

# Test: Session with special characters
test_start "wt_save_session handles special characters in values"
wt_save_session "test_special" 'path=/path/with "quotes"' 'msg=hello\nworld'
output=$(wt_restore_session "test_special")
[[ "$output" == *"path=/path"* ]] || test_fail "Lost special chars"
test_pass

# Cleanup
rm -rf "$TEST_SESSION_DIR"

test_suite_summary

