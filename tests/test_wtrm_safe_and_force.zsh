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
CLEAN_DIR="$TEST_TMP/repo-clean"
add_worktree_branch "$REPO_DIR" "$CLEAN_DIR" feature/clean HEAD
DIRTY_DIR="$TEST_TMP/repo-dirty"
add_worktree_branch "$REPO_DIR" "$DIRTY_DIR" feature/dirty HEAD

# Make DIRTY_DIR dirty and ahead of upstream (no upstream set) to trigger safety
print -r -- "x" >> "$DIRTY_DIR/file.txt"

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtrm"

cd "$REPO_DIR"

# Refuses dirty without --force
set +e
wtrm -d "$DIRTY_DIR"
RC=$?
set -e
[[ $RC -ne 0 ]] || { echo "wtrm should have refused dirty worktree"; exit 1; }

# Force removes dirty
set +e
wtrm -d "$DIRTY_DIR" --force
RC=$?
set -e
[[ $RC -eq 0 ]] || { echo "wtrm --force failed"; exit 1; }
[[ ! -d "$DIRTY_DIR" ]] || { echo "dirty dir still exists"; exit 1; }

# Removes clean dir without force
set +e
wtrm -d "$CLEAN_DIR"
RC=$?
set -e
[[ $RC -eq 0 ]] || { echo "wtrm clean removal failed"; exit 1; }
[[ ! -d "$CLEAN_DIR" ]] || { echo "clean dir still exists"; exit 1; }

echo "wtrm safe/force test OK"
