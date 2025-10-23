#!/usr/bin/env zsh
# Baseline regression test - existing wtnew behavior
# This test ensures existing wtnew functionality continues to work

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

test_suite_init "Baseline: wtnew basic functionality"

# Setup
test_setup_repo
cd "$REPO_DIR"

# Source wtnew function
source "$ROOT_DIR/scripts/wtnew"

# Test: wtnew --help works
test_start "wtnew --help exits with 0"
if wtnew --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "wtnew --help should work"
fi

# Test: wtnew creates worktree
test_start "wtnew creates worktree with -n and -b"
test_dir="$TEST_TMP/wt-test"
if output=$(wtnew -n test-branch -b main -d "$test_dir" --no-open 2>&1); then
  if [[ -d "$test_dir" ]]; then
    test_pass
  else
    test_fail "Worktree directory should exist"
  fi
else
  test_fail "wtnew should create worktree"
  echo "Output: $output"
fi

# Test: branch was created
test_start "wtnew creates git branch"
if git show-ref --verify --quiet "refs/heads/test-branch"; then
  test_pass
else
  test_fail "Branch should be created"
fi

# Test: worktree is registered
test_start "wtnew registers worktree"
if git worktree list | grep -q "$test_dir"; then
  test_pass
else
  test_fail "Worktree should be registered"
fi

# Cleanup
test_cleanup

test_suite_summary
