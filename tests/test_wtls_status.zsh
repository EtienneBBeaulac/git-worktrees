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

# Make DIRTY_DIR dirty
print -r -- "x" >> "$DIRTY_DIR/file.txt"

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtls"

cd "$REPO_DIR"

OUT=$(wtls)
print -r -- "$OUT" | grep -Fq $'feature/clean' || { echo "missing clean row"; exit 1; }
print -r -- "$OUT" | grep -Fq $'feature/dirty' || { echo "missing dirty row"; exit 1; }
# status words present
print -r -- "$OUT" | grep -Fq "clean" || { echo "missing clean status"; exit 1; }
print -r -- "$OUT" | grep -Fq "dirty" || { echo "missing dirty status"; exit 1; }

echo "wtls status test OK"
