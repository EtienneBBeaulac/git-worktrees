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
WT_DIR="$TEST_TMP/repo-open"
add_worktree_branch "$REPO_DIR" "$WT_DIR" feature/os HEAD

STUB_BIN="$TEST_TMP/bin"
install_stubs "$STUB_BIN"
export PATH="$STUB_BIN:$PATH"
export WT_APP=Dummy
export WT_PREFER_XDG_OPEN=1

. "$ROOT_DIR/scripts/wtopen"
cd "$REPO_DIR"

# Remove 'open' to force xdg-open path; keep studio missing
rm -f "$STUB_BIN/open"

wtopen feature/os --no-open >/dev/null 2>&1 || true

# Now call via wtls --fzf --open with stubbed fzf selection
cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/wtls_xdg_in.txt"
printf "%s\n" "enter"
printf "%b\n" "feature/os\t$TEST_TMP/repo-open\tclean"
exit 0
EOF
chmod +x "$STUB_BIN/fzf"

. "$ROOT_DIR/scripts/wtls"
wtls --fzf --open >/dev/null 2>&1 || true

# Ensure our stub 'xdg-open' saw the dir (normalize to physical path)
PHYS_WT=$(cd "$WT_DIR" && pwd -P)
ACTUAL_PATH=$(awk '{print $NF}' "$TEST_TMP/xdgopen_calls.txt" | tail -n 1)
PHYS_ACTUAL=$(cd "$ACTUAL_PATH" && pwd -P)
[[ "$PHYS_ACTUAL" == "$PHYS_WT" ]] || { echo "xdg-open not used"; exit 1; }

echo "os xdg-open test OK"


