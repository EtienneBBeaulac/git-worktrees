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
WT_DIR="$TEST_TMP/repo-open-me"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/open-me HEAD

STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy

. "$ROOT_DIR/scripts/wtls"
cd "$REPO_DIR"

# Stub fzf to select our row then return
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/wtls_fzf_in.txt"
printf "%s\n" "enter"
printf "%b\n" "feature/open-me\t$TEST_TMP/repo-open-me\tclean"
exit 0
EOF
chmod +x "$STUB_BIN/fzf"

wtls --fzf --open >/dev/null 2>&1 || true
# Normalize both expected and actual to physical paths
PHYS_WT=$(cd "$WT_DIR" && pwd -P)
ACTUAL_PATH=$(awk '{print $NF}' "$TEST_TMP/open_calls.txt" | tail -n 1)
PHYS_ACTUAL=$(cd "$ACTUAL_PATH" && pwd -P)
[[ "$PHYS_ACTUAL" == "$PHYS_WT" ]] || { echo "wtls fzf open did not call open"; exit 1; }

echo "wtls fzf open test OK"


