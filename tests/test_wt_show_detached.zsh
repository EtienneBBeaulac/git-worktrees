#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/stubs.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"

TEST_TMP=$(mktemp -d)
export TEST_TMP
trap 'rm -rf "$TEST_TMP"' EXIT

# Create a git repo with one normal branch and one detached worktree
REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"
WORKTREE_BRANCH="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$WORKTREE_BRANCH" feature/test HEAD
WORKTREE_DETACHED="$TEST_TMP/repo-detached"
add_worktree_detached "$REPO_DIR" "$WORKTREE_DETACHED" HEAD

# Stub fzf to capture input and simulate selecting the toggle first, then no selection
STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"

# Create stub fzf
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
COUNT_FILE="${TEST_TMP:-/tmp}/fzf_count"
IN_NUM=1
if [[ -f "$COUNT_FILE" ]]; then IN_NUM=$(( $(cat "$COUNT_FILE") + 1 )); fi
echo -n "$IN_NUM" > "$COUNT_FILE"
IN_FILE="${TEST_TMP:-/tmp}/fzf_call${IN_NUM}_in.txt"
cat > "$IN_FILE"
if [[ "$IN_NUM" == "1" ]]; then
  # Select the toggle row
  printf "%s\n" "enter"
  printf "%b\n" "🧵 Show detached…\t(toggle)"
  exit 0
else
  # Simulate cancel/no-selection on second run
  exit 1
fi
EOF
chmod +x "$STUB_BIN/fzf"

# Source wt from repo and run in the repo with isolated HOME
export HOME="$TEST_TMP/home"
mkdir -p "$HOME"
. "$ROOT_DIR/scripts/wt"
cd "$REPO_DIR"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy

set +e
WT_DEBUG=1 wt --start list
RC=$?
set -e

# Validate fzf was called twice
[[ -f "$TEST_TMP/fzf_call1_in.txt" ]] || { echo "fzf not invoked"; exit 1; }
[[ -f "$TEST_TMP/fzf_call2_in.txt" ]] || { echo "toggle did not re-run wt"; exit 1; }

# Check second call includes a detached row
# Show debug on failure; assert a detached row by splitting on tabs
if ! awk -F '\t' 'BEGIN{ok=0} $1=="(detached)"{ok=1} END{exit ok?0:1}' "$TEST_TMP/fzf_call2_in.txt"; then
  echo "--- fzf_call1_in.txt ---"; cat "$TEST_TMP/fzf_call1_in.txt" || true
  echo "--- fzf_call2_in.txt ---"; cat "$TEST_TMP/fzf_call2_in.txt" || true
  echo "second fzf input missing detached entries"; exit 1
fi

echo "show-detached toggle test OK"
