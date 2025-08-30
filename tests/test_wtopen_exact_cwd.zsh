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

# Exact match: require exact when providing a fully specified ref
OUT2=$(wtopen --no-open --exact shared/branch)
# exact still matches since both entries have same short branch; force fzf bypass by cwd
[[ -n "$OUT2" ]]

echo "wtopen exact/cwd test OK"
