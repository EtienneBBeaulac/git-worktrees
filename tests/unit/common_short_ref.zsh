#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
. "$ROOT_DIR/scripts/lib/wt-common.zsh"

# refs/heads
[[ "$(wt_short_ref refs/heads/feature/x)" == "feature/x" ]]
# refs/remotes
[[ "$(wt_short_ref refs/remotes/origin/feature/x)" == "feature/x" ]]
# remotes/
[[ "$(wt_short_ref remotes/upstream/feature/x)" == "feature/x" ]]
# passthrough
[[ "$(wt_short_ref feature/x)" == "feature/x" ]]

echo "short_ref unit OK"
