#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.zsh/functions"
: > "$TMP_HOME/.zshrc"

set -x
PREFIX="$TMP_HOME/.zsh/functions" QUIET=1 HOME="$TMP_HOME" bash "$ROOT_DIR/install.sh" --yes --dry-run
PREFIX="$TMP_HOME/.zsh/functions" QUIET=1 HOME="$TMP_HOME" bash "$ROOT_DIR/install.sh" --yes
set +x

grep -Fq 'wt.zsh' "$TMP_HOME/.zshrc" || { echo "Missing wt.zsh source line"; exit 1; }

echo "installer --yes flag test OK"
