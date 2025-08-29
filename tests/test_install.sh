#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.zsh/functions"
: > "$TMP_HOME/.zshrc"

PREFIX="$TMP_HOME/.zsh/functions" QUIET=1 REPO_RAW="file://$ROOT_DIR" HOME="$TMP_HOME" bash "$ROOT_DIR/install.sh"

for f in wt.zsh wtnew.zsh wtrm.zsh wtopen.zsh wtls.zsh wt-common.zsh; do
  grep -Fq "$f" "$TMP_HOME/.zshrc" || { echo "Missing source for $f"; exit 1; }
done

echo "install test OK"
