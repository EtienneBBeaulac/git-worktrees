#!/usr/bin/env zsh
# Unit tests for wt-validation.zsh - Branch name sanitization
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-validation.zsh"

test_suite_init "wt-validation: Branch Name Sanitization"

# Test sanitization
test_start "wt_sanitize_branch_name keeps valid name unchanged"
result=$(wt_sanitize_branch_name "feature/test")
assert_equals "feature/test" "$result"
test_pass

test_start "wt_sanitize_branch_name replaces spaces with hyphens"
result=$(wt_sanitize_branch_name "my feature branch")
assert_equals "my-feature-branch" "$result"
test_pass

test_start "wt_sanitize_branch_name removes leading dots"
result=$(wt_sanitize_branch_name ".feature")
assert_equals "feature" "$result"
test_pass

test_start "wt_sanitize_branch_name removes leading hyphens"
result=$(wt_sanitize_branch_name "-feature")
assert_equals "feature" "$result"
test_pass

test_start "wt_sanitize_branch_name replaces double dots"
result=$(wt_sanitize_branch_name "feature..test")
assert_equals "feature-test" "$result"
test_pass

test_start "wt_sanitize_branch_name replaces @{"
result=$(wt_sanitize_branch_name "feature@{123}")
assert_equals "feature-123" "$result"
test_pass

test_start "wt_sanitize_branch_name replaces invalid chars"
result=$(wt_sanitize_branch_name "feature~1^2:3?4*5")
assert_equals "feature-1-2-3-4-5" "$result"
test_pass

test_start "wt_sanitize_branch_name removes trailing slash"
result=$(wt_sanitize_branch_name "feature/")
assert_equals "feature" "$result"
test_pass

test_start "wt_sanitize_branch_name removes .lock suffix"
result=$(wt_sanitize_branch_name "feature.lock")
assert_equals "feature" "$result"
test_pass

test_start "wt_sanitize_branch_name converts @ to at"
result=$(wt_sanitize_branch_name "@")
assert_equals "at" "$result"
test_pass

test_start "wt_sanitize_branch_name provides default for empty result"
result=$(wt_sanitize_branch_name "...")
assert_equals "branch" "$result"
test_pass

test_suite_summary

