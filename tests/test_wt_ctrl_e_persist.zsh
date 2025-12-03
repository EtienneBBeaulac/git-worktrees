#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT_DIR/tests/lib/assert.sh"
. "$ROOT_DIR/tests/lib/stubs.sh"
. "$ROOT_DIR/tests/lib/git_helpers.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy
export WT_DEBUG=1

REPO_DIR="$TEST_TMP/repo"
create_repo "$REPO_DIR"

# Create an additional worktree so wt hub shows FZF picker
WORKTREE_DIR="$TEST_TMP/repo-feature"
add_worktree_branch "$REPO_DIR" "$WORKTREE_DIR" "feature/test" HEAD

# Isolate HOME so we don't touch the user's config
export HOME="$TEST_TMP/home"
mkdir -p "$HOME"

# Source wt from repo
. "$ROOT_DIR/scripts/wt"

# Work inside the repo
cd "$REPO_DIR"

CFG_DIR="$HOME/.config/git-worktrees"
CFG_FILE="$CFG_DIR/config"  # Modern config location (not legacy 'hub')
rm -rf "$CFG_DIR" || true

# Replace fzf with a custom 2-step stub: 1) ctrl-e on a row, 2) cancel
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
COUNT_FILE="${TEST_TMP:-/tmp}/fzf_ctrl_e_count"
IN_NUM=1
if [[ -f "$COUNT_FILE" ]]; then IN_NUM=$(( $(cat "$COUNT_FILE") + 1 )); fi
echo -n "$IN_NUM" > "$COUNT_FILE"
cat > "${TEST_TMP:-/tmp}/fzf_ctrl_e_in_${IN_NUM}.txt"
if [[ "$IN_NUM" == "1" ]]; then
  printf "%s\n" "ctrl-e"
  printf "%b\n" "main\t(dummy)"
  exit 0
else
  exit 1
fi
EOF
chmod +x "$STUB_BIN/fzf"

set +e
wt --start list
set -e

assert_file_exists "$CFG_FILE"
assert_contains "$CFG_FILE" "WT_ENTER_BEHAVIOR=menu"

# Reset and toggle back to open
rm -f "$TEST_TMP/fzf_ctrl_e_count"
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
COUNT_FILE="${TEST_TMP:-/tmp}/fzf_ctrl_e_count"
IN_NUM=1
if [[ -f "$COUNT_FILE" ]]; then IN_NUM=$(( $(cat "$COUNT_FILE") + 1 )); fi
echo -n "$IN_NUM" > "$COUNT_FILE"
cat > "${TEST_TMP:-/tmp}/fzf_ctrl_e_in_${IN_NUM}.txt"
if [[ "$IN_NUM" == "1" ]]; then
  printf "%s\n" "ctrl-e"
  printf "%b\n" "main\t(dummy)"
  exit 0
else
  exit 1
fi
EOF
chmod +x "$STUB_BIN/fzf"

set +e
wt --start list
set -e

assert_contains "$CFG_FILE" "WT_ENTER_BEHAVIOR=open"

echo "wt ctrl-e persist test OK"
