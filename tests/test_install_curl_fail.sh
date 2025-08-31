#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT

# Simulate curl failure by pointing to a bogus URL; expect non-zero return
export HOME="$TMP_HOME"
export REPO_RAW="https://invalid.example.invalid/git-worktrees"

set +e
bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
RC=$?
set -e

[[ $RC -ne 0 ]] || { echo "installer should fail on curl error"; exit 1; }
echo "installer curl failure test OK"


