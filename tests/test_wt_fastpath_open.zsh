#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/stubs.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

# Setup PATH stubs
STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy

# Repo with branch worktree
REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
BR_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$BR_DIR" "feature/x" HEAD

# Isolate HOME and source repo script
export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wt"

# Run wt fast-path: should attempt to open BR_DIR (we don't assert GUI, just that command succeeds)
cd "$REPO_DIR"
wt feature/x >/dev/null 2>&1 || { echo "wt fast-path failed"; exit 1; }

# Ensure our stub 'open' was called with path
. "$(dirname "$0")/lib/assert.sh"
assert_contains "$TEST_TMP/open_calls.txt" "$BR_DIR"

echo "wt fastpath test OK"
