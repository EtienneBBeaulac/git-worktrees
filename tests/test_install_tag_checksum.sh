#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.zsh/functions"
: > "$TMP_HOME/.zshrc"

# Create a fake checksum file that matches local files
CSUM_FILE="$TMP_HOME/SHA256SUMS"
(
  cd "$ROOT_DIR"
  for p in scripts/wt scripts/wtnew scripts/wtrm scripts/wtopen scripts/wtls scripts/lib/wt-common.zsh; do
    h=$(shasum -a 256 "$p" | awk '{print $1}')
    printf "%s  %s\n" "$h" "$p"
    # also provide basename variant
    b=$(basename "$p")
    printf "%s  %s\n" "$h" "$b"
  done
) > "$CSUM_FILE"

# Dry-run ensures no error path on checksum; then run full
PREFIX="$TMP_HOME/.zsh/functions" QUIET=1 HOME="$TMP_HOME" REPO_RAW="file://$ROOT_DIR" bash "$ROOT_DIR/install.sh" --checksum-file "$CSUM_FILE" --dry-run
PREFIX="$TMP_HOME/.zsh/functions" QUIET=1 HOME="$TMP_HOME" REPO_RAW="file://$ROOT_DIR" bash "$ROOT_DIR/install.sh" --checksum-file "$CSUM_FILE"

# Spot-check
for f in wt.zsh wtnew.zsh wtrm.zsh wtopen.zsh wtls.zsh wt-common.zsh; do
  grep -Fq "$f" "$TMP_HOME/.zshrc" || { echo "Missing source for $f"; exit 1; }
  test -f "$TMP_HOME/.zsh/functions/$f" || { echo "Missing installed file $f"; exit 1; }
done

echo "installer tag+checksum test OK"
