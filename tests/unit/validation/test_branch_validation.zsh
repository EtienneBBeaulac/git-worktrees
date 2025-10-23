#!/usr/bin/env zsh
# Unit tests for wt-validation.zsh - Branch name validation
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-validation.zsh"

test_suite_init "wt-validation: Branch Name Validation"

# Valid names
test_start "wt_validate_branch_name accepts valid simple name"
wt_validate_branch_name "feature" && test_pass || test_fail
test_start "wt_validate_branch_name accepts valid with slashes"
wt_validate_branch_name "feature/my-branch" && test_pass || test_fail
test_start "wt_validate_branch_name accepts valid with underscores"
wt_validate_branch_name "feature_123" && test_pass || test_fail
test_start "wt_validate_branch_name accepts valid with numbers"
wt_validate_branch_name "v1.2.3" && test_pass || test_fail

# Invalid names
test_start "wt_validate_branch_name rejects empty string"
wt_validate_branch_name "" && test_fail || test_pass
test_start "wt_validate_branch_name rejects leading dot"
wt_validate_branch_name ".feature" && test_fail || test_pass
test_start "wt_validate_branch_name rejects leading hyphen"
wt_validate_branch_name "-feature" && test_fail || test_pass
test_start "wt_validate_branch_name rejects double dots"
wt_validate_branch_name "feature..bad" && test_fail || test_pass
test_start "wt_validate_branch_name rejects @{"
wt_validate_branch_name "feature@{123}" && test_fail || test_pass
test_start "wt_validate_branch_name rejects spaces"
wt_validate_branch_name "feature name" && test_fail || test_pass
test_start "wt_validate_branch_name rejects tilde"
wt_validate_branch_name "feature~1" && test_fail || test_pass
test_start "wt_validate_branch_name rejects caret"
wt_validate_branch_name "feature^parent" && test_fail || test_pass
test_start "wt_validate_branch_name rejects colon"
wt_validate_branch_name "feature:test" && test_fail || test_pass
test_start "wt_validate_branch_name rejects question mark"
wt_validate_branch_name "feature?" && test_fail || test_pass
test_start "wt_validate_branch_name rejects asterisk"
wt_validate_branch_name "feature*" && test_fail || test_pass
test_start "wt_validate_branch_name rejects .lock suffix"
wt_validate_branch_name "feature.lock" && test_fail || test_pass
test_start "wt_validate_branch_name rejects trailing slash"
wt_validate_branch_name "feature/" && test_fail || test_pass
test_start "wt_validate_branch_name rejects @ alone"
wt_validate_branch_name "@" && test_fail || test_pass

# Error messages
test_start "wt_validate_branch_name_error returns correct message for empty"
msg=$(wt_validate_branch_name_error "")
[[ "$msg" == *"cannot be empty"* ]] && test_pass || test_fail
test_start "wt_validate_branch_name_error returns correct message for leading dot"
msg=$(wt_validate_branch_name_error ".feature")
[[ "$msg" == *"cannot start with '.'"* ]] && test_pass || test_fail

test_suite_summary

