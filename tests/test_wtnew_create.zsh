#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"

# Source wtnew
. "$ROOT_DIR/scripts/wtnew"

cd "$REPO_DIR"

# Compute default dir and pass it to avoid interactive prompt
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
DEFAULT_DIR="$(dirname "$REPO_DIR")/${REPO_NAME}-feature-wtnew-test"
WT_APP=Dummy wtnew -n feature/wtnew-test -b main --no-open -d "$DEFAULT_DIR"

# Assert worktree directory created (default sibling)
assert_dir_exists "$DEFAULT_DIR"

# Assert branch exists and is checked out there
assert_file_exists "$DEFAULT_DIR/.git"
CURRENT_BRANCH=$(git -C "$DEFAULT_DIR" rev-parse --abbrev-ref HEAD)
assert_eq "$CURRENT_BRANCH" "feature/wtnew-test"

echo "wtnew create test OK"
