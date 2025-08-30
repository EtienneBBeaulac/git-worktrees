#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

. "$ROOT_DIR/scripts/wt"
. "$ROOT_DIR/scripts/wtopen"

set +e
OUT1=$(cd "$TMP" && wt 2>&1)
RC1=$?
OUT2=$(cd "$TMP" && wtopen --list 2>&1)
RC2=$?
set -e

echo "$OUT1" | grep -Fq "Not a git repo" || { echo "wt did not report non-git repo"; exit 1; }
[[ $RC1 -ne 0 ]] || { echo "wt should fail in non-git dir"; exit 1; }
echo "$OUT2" | grep -Fq "Not a git repo" || { echo "wtopen did not report non-git repo"; exit 1; }
[[ $RC2 -ne 0 ]] || { echo "wtopen should fail in non-git dir"; exit 1; }

echo "non-git dir error test OK"


