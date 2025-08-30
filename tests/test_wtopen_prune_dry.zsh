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
WT_DIR="$TEST_TMP/repo-open"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/open2 HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtopen"

cd "$REPO_DIR"

# prune-stale should run without error
wtopen --prune-stale >/dev/null 2>&1 || { echo "prune-stale failed"; exit 1; }

# dry-run shows which directory would be opened
OUT=$(wtopen feature/open2 --dry-run --no-open)
print -r -- "$OUT" | grep -Fq "DRY-RUN: would open $WT_DIR" || { echo "dry-run output mismatch"; exit 1; }

echo "wtopen prune/dry-run test OK"
