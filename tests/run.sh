#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

run() { echo "[TEST] $*"; "$@"; }

# 1) Syntax checks
run zsh -n "$ROOT_DIR/scripts/wt"
run zsh -n "$ROOT_DIR/scripts/wtnew"
run zsh -n "$ROOT_DIR/scripts/wtrm"
run zsh -n "$ROOT_DIR/scripts/wtopen"
run zsh -n "$ROOT_DIR/scripts/wtls"

# 2) Install script dry run and self-test
REPO_RAW="file://$ROOT_DIR" DRY_RUN=1 QUIET=1 NO_SOURCE=1 bash "$ROOT_DIR/install.sh"

# 3) Verify installer would append source lines
TMP_ZSHRC=$(mktemp)
trap 'rm -f "$TMP_ZSHRC"' EXIT
cp -f "$HOME/.zshrc" "$TMP_ZSHRC" || true
HOME_TMP=$(mktemp -d)
trap 'rm -rf "$HOME_TMP"' EXIT
mkdir -p "$HOME_TMP/.zsh/functions"
cp -f "$ROOT_DIR/scripts/"* "$HOME_TMP/.zsh/functions/" 2>/dev/null || true
PREFIX="$HOME_TMP/.zsh/functions" QUIET=1 REPO_RAW="file://$ROOT_DIR" HOME="$HOME_TMP" bash "$ROOT_DIR/install.sh"

# Check presence of lines
for f in wt.zsh wtnew.zsh wtrm.zsh wtopen.zsh wtls.zsh wt-common.zsh; do
  grep -Fq "$f" "$HOME_TMP/.zshrc" || { echo "Missing source for $f"; exit 1; }
done

echo "All tests passed."
