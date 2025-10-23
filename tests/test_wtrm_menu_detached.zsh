#!/usr/bin/env zsh
# Test: wtrm interactive picker with "Remove all detached" option

set -e
ROOT_DIR="${0:A:h:h}"
cd "$ROOT_DIR"

# Source test helpers
source "$ROOT_DIR/scripts/wtrm"
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

TEST_TMP=$(mktemp -d)
trap "rm -rf '$TEST_TMP'" EXIT

echo "Test: wtrm menu includes 'Remove all detached' option"

# Create test repo with worktrees
REPO_DIR="$TEST_TMP/repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo "initial" > README.md
git add README.md
git commit -q -m "Initial commit"

# Create some detached worktrees
DET1="$TEST_TMP/det1"
DET2="$TEST_TMP/det2"
git worktree add --detach "$DET1" HEAD >/dev/null 2>&1
git worktree add --detach "$DET2" HEAD >/dev/null 2>&1

# Create a regular branch worktree
BRANCH_WT="$TEST_TMP/branch-wt"
git worktree add -b feature "$BRANCH_WT" >/dev/null 2>&1

# Test 1: Verify wtrm picks up detached worktrees
echo "Test 1: Verify detached worktrees exist"
PORCELAIN="$(git worktree list --porcelain 2>/dev/null)"
TABLE="$(wt_parse_worktrees_table "$PORCELAIN")"
DET_COUNT="$(printf "%s\n" "$TABLE" | awk -F'|' '$2=="(detached)"' | wc -l | tr -d ' ')"

if [[ "$DET_COUNT" -ge 2 ]]; then
  echo "  ✅ PASS: Found $DET_COUNT detached worktrees"
else
  echo "  ❌ FAIL: Expected at least 2 detached worktrees, found $DET_COUNT"
  exit 1
fi

# Test 2: Verify bulk removal option is offered (would need fzf to fully test)
echo "Test 2: Verify has_detached logic"
HAS_DETACHED=0
if printf "%s\n" "$TABLE" | awk -F'|' '$2=="(detached)"' | grep -q .; then
  HAS_DETACHED=1
fi

if [[ "$HAS_DETACHED" -eq 1 ]]; then
  echo "  ✅ PASS: has_detached flag set correctly"
else
  echo "  ❌ FAIL: has_detached should be 1"
  exit 1
fi

# Test 3: Actually remove detached worktrees using --rm-detached
echo "Test 3: Remove detached worktrees via --rm-detached"
wtrm --rm-detached --yes >/dev/null 2>&1

# Verify they're gone
PORCELAIN_AFTER="$(git worktree list --porcelain 2>/dev/null)"
TABLE_AFTER="$(wt_parse_worktrees_table "$PORCELAIN_AFTER")"
DET_COUNT_AFTER="$(printf "%s\n" "$TABLE_AFTER" | awk -F'|' '$2=="(detached)"' | wc -l | tr -d ' ')"

if [[ "$DET_COUNT_AFTER" -eq 0 ]]; then
  echo "  ✅ PASS: All detached worktrees removed"
else
  echo "  ❌ FAIL: Still have $DET_COUNT_AFTER detached worktrees"
  exit 1
fi

# Verify regular branch worktree still exists
if [[ -d "$BRANCH_WT" ]]; then
  echo "  ✅ PASS: Regular branch worktree preserved"
else
  echo "  ❌ FAIL: Regular branch worktree was removed"
  exit 1
fi

echo "✅ All tests passed!"

