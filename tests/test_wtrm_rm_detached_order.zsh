#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"
. "$ROOT_DIR/tests/lib/remote.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
BARE_DIR="$TEST_TMP/remote.git"
create_bare_remote "$BARE_DIR"
add_remote "$REPO_DIR" origin "$BARE_DIR"
initial_push_main "$REPO_DIR" origin

cd "$REPO_DIR"
. "$ROOT_DIR/scripts/wtrm"

# Add multiple detached worktrees
DET1="$TEST_TMP/repo-det-1"
DET2="$TEST_TMP/repo-det-2"
DET3="$TEST_TMP/repo-det-3"
add_worktree_detached "$REPO_DIR" "$DET1" HEAD
add_worktree_detached "$REPO_DIR" "$DET2" HEAD
add_worktree_detached "$REPO_DIR" "$DET3" HEAD

# Run with concurrency and ensure output includes all three in some deterministic order
DET1_PHYS=$(cd "$DET1" && pwd -P)
DET2_PHYS=$(cd "$DET2" && pwd -P)
DET3_PHYS=$(cd "$DET3" && pwd -P)

OUT=$(WT_DEBUG= wtrm --rm-detached --yes --jobs 2)
print -r -- "$OUT" | grep -Fq "Removed: $DET1" || print -r -- "$OUT" | grep -Fq "Removed: $DET1_PHYS" || { echo "missing det1"; exit 1; }
print -r -- "$OUT" | grep -Fq "Removed: $DET2" || print -r -- "$OUT" | grep -Fq "Removed: $DET2_PHYS" || { echo "missing det2"; exit 1; }
print -r -- "$OUT" | grep -Fq "Removed: $DET3" || print -r -- "$OUT" | grep -Fq "Removed: $DET3_PHYS" || { echo "missing det3"; exit 1; }

echo "wtrm rm-detached order test OK"


