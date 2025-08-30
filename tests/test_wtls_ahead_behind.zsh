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

WT_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/ab main

# Make branch ahead by one commit
commit_change "$WT_DIR" file.txt ahead

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtls"

cd "$REPO_DIR"
OUT=$(wtls)
print -r -- "$OUT" | grep -Fq "feature/ab" || { echo "missing branch"; exit 1; }
print -r -- "$OUT" | grep -Eiq "↑[0-9]+" || { echo "missing ahead marker"; exit 1; }

echo "wtls ahead/behind test OK"
