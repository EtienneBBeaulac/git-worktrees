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
BR_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$BR_DIR" feature/open HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtopen"

cd "$REPO_DIR"

# --list prints rows
OUT=$(wtopen --list)
print -r -- "$OUT" | grep -Fq "feature/open"
print -r -- "$OUT" | grep -Fq "$BR_DIR"

# --no-open prints path
PATH_OUT=$(wtopen feature/open --no-open)
assert_eq "$PATH_OUT" "$BR_DIR"

echo "wtopen basic test OK"
