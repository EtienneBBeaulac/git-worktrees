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

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtnew"

cd "$REPO_DIR"
set +e
OUT=$(wtnew -n 'bad branch !@#' -b main --no-open 2>&1)
RC=$?
set -e
[[ $RC -ne 0 ]] || { echo "wtnew invalid branch should fail"; exit 1; }
print -r -- "$OUT" | grep -Fqi "Invalid branch name" || { echo "error message mismatch"; exit 1; }

echo "invalid branch error test OK"


