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
WT_DIR="$TEST_TMP/repo-feature-upstream-only"
# create a new branch without --push
WT_APP=Dummy wtnew -n feature/upstream-only -b main --no-open -d "$WT_DIR"

# Assert upstream remote/merge config exists
UP_REMOTE=$(git -C "$WT_DIR" config --get "branch.feature/upstream-only.remote" || true)
UP_MERGE=$(git -C "$WT_DIR" config --get "branch.feature/upstream-only.merge" || true)
[[ -n "$UP_REMOTE" ]] || { echo "upstream remote not set"; exit 1; }
[[ -n "$UP_MERGE" ]] || { echo "upstream merge not set"; exit 1; }
[[ "$UP_REMOTE" == "origin" ]] || { echo "unexpected upstream remote: $UP_REMOTE"; exit 1; }
[[ "$UP_MERGE" == "refs/heads/feature/upstream-only" ]] || { echo "unexpected upstream merge: $UP_MERGE"; exit 1; }

echo "wtnew upstream-no-push test OK"



