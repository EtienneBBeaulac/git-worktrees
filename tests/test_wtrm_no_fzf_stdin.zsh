#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"
. "$ROOT_DIR/tests/lib/input.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
WT_DIR="$TEST_TMP/repo-to-remove"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/rm HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtrm"

cd "$REPO_DIR"

# prune-only smoke
wtrm --prune-only >/dev/null 2>&1 || { echo "prune-only failed"; exit 1; }

# --no-fzf path prompt: feed path via stdin
run_with_input "$WT_DIR\n" zsh -fc "wtrm --no-fzf" || true
[[ ! -d "$WT_DIR" ]] || { echo "no-fzf stdin removal failed"; exit 1; }

echo "wtrm no-fzf stdin test OK"
