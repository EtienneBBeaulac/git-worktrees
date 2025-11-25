#!/usr/bin/env zsh
# Unit tests for wt_git_is_repo() repository detection
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_git_is_repo()"

# Setup temp directories
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

NON_GIT_DIR="$TEMP_DIR/not-a-repo"
GIT_DIR="$TEMP_DIR/git-repo"

mkdir -p "$NON_GIT_DIR"
mkdir -p "$GIT_DIR"
git -C "$GIT_DIR" init --quiet

# ============================================================================
# Basic tests
# ============================================================================

test_start "wt_git_is_repo returns true for git repository"
wt_git_is_repo "$GIT_DIR" && test_pass || test_fail

test_start "wt_git_is_repo returns false for non-git directory"
wt_git_is_repo "$NON_GIT_DIR" && test_fail || test_pass

test_start "wt_git_is_repo returns false for nonexistent directory"
wt_git_is_repo "$TEMP_DIR/nonexistent" && test_fail || test_pass

# ============================================================================
# Current directory tests
# ============================================================================

test_start "wt_git_is_repo with no arg checks current directory (in git repo)"
(cd "$GIT_DIR" && wt_git_is_repo) && test_pass || test_fail

test_start "wt_git_is_repo with no arg checks current directory (not in git repo)"
(cd "$NON_GIT_DIR" && wt_git_is_repo) && test_fail || test_pass

# ============================================================================
# Subdirectory tests
# ============================================================================

test_start "wt_git_is_repo returns true for subdirectory of git repo"
mkdir -p "$GIT_DIR/subdir/nested"
wt_git_is_repo "$GIT_DIR/subdir/nested" && test_pass || test_fail

# ============================================================================
# Edge cases
# ============================================================================

test_start "wt_git_is_repo handles paths with spaces"
SPACE_DIR="$TEMP_DIR/dir with spaces"
mkdir -p "$SPACE_DIR"
git -C "$SPACE_DIR" init --quiet
wt_git_is_repo "$SPACE_DIR" && test_pass || test_fail

test_start "wt_git_is_repo with explicit . argument"
(cd "$GIT_DIR" && wt_git_is_repo .) && test_pass || test_fail

# ============================================================================
# Test against the real project repo
# ============================================================================

test_start "wt_git_is_repo detects this project's repo"
wt_git_is_repo "$ROOT_DIR" && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

