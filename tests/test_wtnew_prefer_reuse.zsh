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
SLOT_DIR="$TEST_TMP/reuse-slot"
add_worktree_branch "$REPO_DIR" "$SLOT_DIR" base/slot HEAD

export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
# We'll stub fzf to force-select our desired slot; create two clean slots
SECOND_DIR="$TEST_TMP/reuse-slot-2"
add_worktree_branch "$REPO_DIR" "$SECOND_DIR" base/slot2 HEAD

STUB_BIN="$TEST_TMP/bin"
. "$ROOT_DIR/tests/lib/stubs.sh"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"

. "$ROOT_DIR/scripts/wtnew"

cd "$REPO_DIR"
# Prefer reusing SLOT_DIR for a new branch; stub fzf to emit SLOT_DIR line
cat > "$STUB_BIN/fzf" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/wtnew_reuse_fzf_in.txt"
printf "%s\n" "base/slot                                      $SLOT_DIR"
exit 0
EOF
chmod +x "$STUB_BIN/fzf"

WTNEW_PREFER_REUSE=1 WT_APP=Dummy wtnew -n feature/reuse -b main --no-open

# Assert SLOT_DIR switched to feature/reuse
CUR=$(git -C "$SLOT_DIR" rev-parse --abbrev-ref HEAD)
[[ "$CUR" == "feature/reuse" ]] || { echo "prefer-reuse did not switch slot"; exit 1; }

echo "wtnew prefer-reuse test OK"


