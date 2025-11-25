#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
. "$ROOT_DIR/scripts/lib/wt-common.zsh"

PORCELAIN=$'worktree /tmp/a\nbranch refs/heads/main\n\nworktree /tmp/b\nbranch refs/heads/feature/x\n\nworktree /tmp/det\ndetached\n\n'

# include_detached=0
OUT0=$(wt_parse_worktrees_porcelain 0 "$PORCELAIN")
[[ $(printf "%s\n" "$OUT0" | wc -l | tr -d ' ') == 2 ]]
[[ "$(printf "%s\n" "$OUT0" | sed -n '1p')" == $'main	/tmp/a' ]]
[[ "$(printf "%s\n" "$OUT0" | sed -n '2p')" == $'feature/x	/tmp/b' ]]

# include_detached=1
OUT1=$(wt_parse_worktrees_porcelain 1 "$PORCELAIN")
[[ $(printf "%s\n" "$OUT1" | wc -l | tr -d ' ') == 3 ]]
[[ "$(printf "%s\n" "$OUT1" | sed -n '3p')" == $'(detached)	/tmp/det' ]]

echo "parse porcelain unit OK"
