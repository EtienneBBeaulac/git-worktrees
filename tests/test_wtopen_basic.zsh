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
BR_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$BR_DIR" feature/open HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtopen"

cd "$REPO_DIR"

# --list prints rows (normalize path differences like /var vs /private/var)
OUT=$(wtopen --list)
print -r -- "$OUT" | grep -Fq "feature/open"
PHYS_DIR=$(cd "$BR_DIR" && pwd -P)
print -r -- "$OUT" | grep -Fq "$PHYS_DIR"

# --no-open prints path (normalize)
PATH_OUT=$(wtopen feature/open --no-open)
PHYS_OUT=$(cd "$PATH_OUT" && pwd -P)
PHYS_BR=$(cd "$BR_DIR" && pwd -P)
assert_eq "$PHYS_OUT" "$PHYS_BR"

echo "wtopen basic test OK"
