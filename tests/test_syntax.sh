#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

zsh -n "$ROOT_DIR/scripts/wt"
zsh -n "$ROOT_DIR/scripts/wtnew"
zsh -n "$ROOT_DIR/scripts/wtrm"
zsh -n "$ROOT_DIR/scripts/wtopen"
zsh -n "$ROOT_DIR/scripts/wtls"

echo "syntax OK"
