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

# Create merged branch and worktree
MERGED_DIR="$TEST_TMP/repo-merged"
add_worktree_branch "$REPO_DIR" "$MERGED_DIR" feature/merged main
# Merge into main
commit_change "$MERGED_DIR" file.txt merged
git -C "$MERGED_DIR" checkout main -q
# merge-base: since both are from main and we added a commit on feature, simulate merged by fast-forward main
# Create separate commit in repo root main and then delete
cd "$REPO_DIR"
. "$ROOT_DIR/scripts/wtrm"

# Add a detached worktree
DET_DIR="$TEST_TMP/repo-det"
add_worktree_detached "$REPO_DIR" "$DET_DIR" HEAD

# rm-detached in bulk
set +e
wtrm --rm-detached --yes --jobs 2
set -e
[[ ! -d "$DET_DIR" ]] || { echo "rm-detached failed"; exit 1; }

# Now try delete-branch for merged branch worktree
set +e
wtrm -d "$MERGED_DIR" --delete-branch --force
RC=$?
set -e
[[ $RC -eq 0 ]] || { echo "wtrm delete-branch failed"; exit 1; }

echo "wtrm delete-branch/rm-detached test OK"
