#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
# Normalize environment for deterministic behavior
export LC_ALL=C LANG=C TZ=UTC
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TEMPLATE_DIR=/dev/null
# Ensure HOME exists during tests
export HOME=${HOME:-"$ROOT_DIR/.tmp_home"}
mkdir -p "$HOME" >/dev/null 2>&1 || true

run() { echo "[TEST] $*"; "$@"; }

# 1) Syntax checks
run zsh -fn "$ROOT_DIR/scripts/wt"
run zsh -fn "$ROOT_DIR/scripts/wtnew"
run zsh -fn "$ROOT_DIR/scripts/wtrm"
run zsh -fn "$ROOT_DIR/scripts/wtopen"
run zsh -fn "$ROOT_DIR/scripts/wtls"

# 1b) Unit tests for helpers
run zsh "$ROOT_DIR/tests/unit/common_short_ref.zsh"
run zsh "$ROOT_DIR/tests/unit/common_parse_porcelain.zsh"

if [[ -n "${FAST_ONLY:-}" ]]; then
  echo
  echo "Running fast subset…"
  zsh "$ROOT_DIR/tests/test_wt_fastpath_open.zsh"
  zsh "$ROOT_DIR/tests/test_wtnew_create.zsh"
  echo "Fast subset completed."
  exit 0
fi

# 2) Install script dry run and self-test
REPO_RAW="file://$ROOT_DIR" DRY_RUN=1 QUIET=1 NO_SOURCE=1 bash "$ROOT_DIR/install.sh"

# 3) Verify installer would append source lines
TMP_ZSHRC=$(mktemp)
trap 'rm -f "$TMP_ZSHRC"' EXIT
if [[ -f "$HOME/.zshrc" ]]; then
  cp -f "$HOME/.zshrc" "$TMP_ZSHRC" 2>/dev/null || true
fi
HOME_TMP=$(mktemp -d)
trap 'rm -rf "$HOME_TMP"' EXIT
mkdir -p "$HOME_TMP/.zsh/functions"
cp -f "$ROOT_DIR/scripts/"* "$HOME_TMP/.zsh/functions/" 2>/dev/null || true
PREFIX="$HOME_TMP/.zsh/functions" QUIET=1 REPO_RAW="file://$ROOT_DIR" HOME="$HOME_TMP" bash "$ROOT_DIR/install.sh"

# Check presence of lines
for f in wt.zsh wtnew.zsh wtrm.zsh wtopen.zsh wtls.zsh wt-common.zsh; do
  grep -Fq "$f" "$HOME_TMP/.zshrc" || { echo "Missing source for $f"; exit 1; }
fi

echo "All tests passed."
echo
echo "Running focused behavior tests…"
zsh "$ROOT_DIR/tests/test_wt_show_detached.zsh"
zsh "$ROOT_DIR/tests/test_wt_fastpath_open.zsh"
zsh "$ROOT_DIR/tests/test_wt_ctrl_e_persist.zsh"
zsh "$ROOT_DIR/tests/test_wt_hub_actions_show_path.zsh"
zsh "$ROOT_DIR/tests/test_wt_hub_keys_prune_help.zsh"
zsh "$ROOT_DIR/tests/test_wtnew_create.zsh"
zsh "$ROOT_DIR/tests/test_wtnew_prefer_reuse.zsh"
zsh "$ROOT_DIR/tests/test_wtopen_basic.zsh"
zsh "$ROOT_DIR/tests/test_wtopen_prune_dry.zsh"
zsh "$ROOT_DIR/tests/test_wtrm_safe_and_force.zsh"
zsh "$ROOT_DIR/tests/test_wtrm_no_fzf_stdin.zsh"
zsh "$ROOT_DIR/tests/test_wtrm_rm_detached_order.zsh"
zsh "$ROOT_DIR/tests/test_wtls_status.zsh"
zsh "$ROOT_DIR/tests/test_wtls_status_fast.zsh"
zsh "$ROOT_DIR/tests/test_wtnew_push_upstream.zsh"
zsh "$ROOT_DIR/tests/test_wtopen_exact_cwd.zsh"
zsh "$ROOT_DIR/tests/test_wtrm_delete_branch_and_rm_detached.zsh"
zsh "$ROOT_DIR/tests/test_wtls_ahead_behind.zsh"
zsh "$ROOT_DIR/tests/test_wtls_fzf_open.zsh"
bash "$ROOT_DIR/tests/test_help_snapshots.sh"
zsh "$ROOT_DIR/tests/test_error_non_git_dir.zsh"
zsh "$ROOT_DIR/tests/test_error_invalid_branch.zsh"
zsh "$ROOT_DIR/tests/test_os_xdg_open.zsh"
bash "$ROOT_DIR/tests/test_install_curl_fail.sh"
bash "$ROOT_DIR/tests/test_install_yes_flag.sh"
bash "$ROOT_DIR/tests/test_install_tag_checksum.sh"
