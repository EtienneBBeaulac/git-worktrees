#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

redact() {
  sed -E 's#/private/[^ ]+#<PATH>#g; s#/var/folders/[^ ]+#<PATH>#g; s/[0-9a-f]{7,40}/<SHA>/g'
}

check_help() {
  local cmd="$1"
  local out
  out=$(zsh -fc "$cmd --help" || true)
  [[ -n "$out" ]] || { echo "no output for $cmd --help"; return 1; }
  printf "%s\n" "$out" | redact >/dev/null
}

check_help "$ROOT_DIR/scripts/wt"
check_help "$ROOT_DIR/scripts/wtnew"
check_help "$ROOT_DIR/scripts/wtopen"
check_help "$ROOT_DIR/scripts/wtrm"
check_help "$ROOT_DIR/scripts/wtls"

echo "help snapshots OK"


