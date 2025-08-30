#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

# Two repos with the same branch name
REPO_A="$TEST_TMP/repoA"
REPO_B="$TEST_TMP/repoB"
create_repo "$REPO_A"
create_repo "$REPO_B"
A_DIR="$TEST_TMP/repoA-feature"
B_DIR="$TEST_TMP/repoB-feature"
add_worktree_branch "$REPO_A" "$A_DIR" shared/branch HEAD
add_worktree_branch "$REPO_B" "$B_DIR" shared/branch HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtopen"

# Exact match should resolve without fzf to the single match if cwd is in A
cd "$REPO_A"
OUT=$(wtopen --no-open --cwd shared/branch)
[[ "$OUT" == "$A_DIR" ]] || { echo "cwd preference failed"; exit 1; }

# Exact match without --cwd may yield multiple matches; allow either a path or a guidance message
set +e
OUT2=$(wtopen --no-open --exact shared/branch 2>&1)
RC=$?
set -e
if [[ $RC -eq 0 ]]; then
  [[ -n "$OUT2" ]] || { echo "exact returned empty"; exit 1; }
else
  print -r -- "$OUT2" | grep -Fq "Multiple worktrees match" || { echo "unexpected exact failure: $OUT2"; exit 1; }
fi

echo "wtopen exact/cwd test OK"
