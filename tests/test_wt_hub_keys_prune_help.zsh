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
WT_DIR="$TEST_TMP/repo-key"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/key HEAD

STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy

. "$ROOT_DIR/scripts/wt"
cd "$REPO_DIR"

# First: ctrl-p (prune) smoke
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/fzf_keys_prune_in.txt"
printf "%s\n" "ctrl-p"
printf "%b\n" "feature/key\t$TEST_TMP/repo-key"
exit 0
EOF
chmod +x "$STUB_BIN/fzf"
wt --start list >/dev/null 2>&1 || true

# Second: ctrl-h (help) capture output
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/fzf_keys_help_in.txt"
printf "%s\n" "ctrl-h"
printf "%b\n" "feature/key\t$TEST_TMP/repo-key"
exit 0
EOF
chmod +x "$STUB_BIN/fzf"

OUT=$(wt --start list || true)
print -r -- "$OUT" | grep -Fq "wt hub" || { echo "help output not shown"; exit 1; }

echo "wt hub keys prune/help test OK"


