#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"
. "$ROOT_DIR/tests/lib/remote.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

# repo and bare remote
REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
BARE_DIR="$TEST_TMP/remote.git"
create_bare_remote "$BARE_DIR"
add_remote "$REPO_DIR" origin "$BARE_DIR"
initial_push_main "$REPO_DIR" origin

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wtnew"

cd "$REPO_DIR"
WT_DIR="$TEST_TMP/repo-feature-push"
WT_APP=Dummy wtnew -n feature/push -b main --push --no-open -d "$WT_DIR"

# Assert upstream set (or push attempted)
UPSTREAM=$(git -C "$WT_DIR" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
[[ -n "$UPSTREAM" ]] || { echo "upstream not set"; exit 1; }

echo "wtnew push/upstream test OK"
