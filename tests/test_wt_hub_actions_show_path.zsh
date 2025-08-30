#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"
. "$ROOT_DIR/tests/lib/stubs.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
WT_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/act HEAD

# fzf stub: first fzf selects branch row; second fzf in actions selects "Show path"
STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
COUNT_FILE="${TEST_TMP:-/tmp}/fzf_hub_actions_count"
IN_NUM=1
if [[ -f "$COUNT_FILE" ]]; then IN_NUM=$(( $(cat "$COUNT_FILE") + 1 )); fi
echo -n "$IN_NUM" > "$COUNT_FILE"
IN_FILE="${TEST_TMP:-/tmp}/fzf_hub_actions_in_${IN_NUM}.txt"
cat > "$IN_FILE"
if [[ "$IN_NUM" == "1" ]]; then
  printf "%s\n" "ctrl-a"
  printf "%b\n" "feature/act\t$TEST_TMP/repo-feature"
  exit 0
else
  printf "%s\n" "Show path"
  exit 0
fi
EOF
chmod +x "$STUB_BIN/fzf"

export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy

. "$ROOT_DIR/scripts/wt"
cd "$REPO_DIR"

# Capture output
OUT=$(WT_FZF_HEIGHT=10 WT_FZF_OPTS= WT_DEBUG=1 wt --start list 2>/dev/null || true)
print -r -- "$OUT" | grep -Fq "$WT_DIR" || { echo "Show path did not print worktree path"; exit 1; }

echo "wt hub actions Show path test OK"
