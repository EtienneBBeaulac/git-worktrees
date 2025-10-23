#!/usr/bin/env zsh
# Unit tests for wt-validation.zsh - Git reference checks
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-validation.zsh"

test_suite_init "wt-validation: Git Reference Checks"

# Setup test repo
test_repo=$(make_temp_dir)
cd "$test_repo"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
make_commit "initial"

# Create test branches
git branch feature/test 2>/dev/null
git branch develop 2>/dev/null

# Test ref_exists
test_start "wt_ref_exists returns true for existing branch"
wt_ref_exists "feature/test" && test_pass || test_fail

test_start "wt_ref_exists returns false for non-existent branch"
wt_ref_exists "nonexistent" && test_fail || test_pass

test_start "wt_ref_exists returns true for HEAD"
wt_ref_exists "HEAD" && test_pass || test_fail

# Test branch_exists
test_start "wt_branch_exists returns true for existing branch"
wt_branch_exists "feature/test" && test_pass || test_fail

test_start "wt_branch_exists returns false for non-existent branch"
wt_branch_exists "nonexistent" && test_fail || test_pass

# Test branch_checked_out
test_start "wt_branch_checked_out returns true for checked out branch"
# Current branch should be main or master
current=$(git branch --show-current)
wt_branch_checked_out "$current" && test_pass || test_fail

test_start "wt_branch_checked_out returns false for non-checked-out branch"
wt_branch_checked_out "feature/test" && test_fail || test_pass

# Cleanup
cd - >/dev/null
rm -rf "$test_repo"

test_suite_summary

