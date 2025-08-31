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
WT_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/fast main

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtls"

cd "$REPO_DIR"

# Fast via flag
OUT=$(wtls --fast)
print -r -- "$OUT" | grep -Fq $'feature/fast' || { echo "missing branch"; exit 1; }
# Should show clean/dirty but not necessarily ↑/↓
print -r -- "$OUT" | grep -Eq "clean|dirty" || { echo "missing status"; exit 1; }

# Fast via env
WT_FAST=1 OUT2=$(wtls)
print -r -- "$OUT2" | grep -Fq $'feature/fast' || { echo "missing branch (env)"; exit 1; }
print -r -- "$OUT2" | grep -Eq "clean|dirty" || { echo "missing status (env)"; exit 1; }

echo "wtls fast mode test OK"


