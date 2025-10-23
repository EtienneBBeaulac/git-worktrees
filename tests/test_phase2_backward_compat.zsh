#!/usr/bin/env zsh
# Test Phase 2: Backward compatibility

set -e

echo "Testing Phase 2: Backward compatibility"

SCRIPT_DIR="${0:A:h}/../scripts"

# Test 1: Old command files still exist
echo -n "  • wtnew script exists... "
if [[ -f "${SCRIPT_DIR}/wtnew" ]]; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo -n "  • wtrm script exists... "
if [[ -f "${SCRIPT_DIR}/wtrm" ]]; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo -n "  • wtopen script exists... "
if [[ -f "${SCRIPT_DIR}/wtopen" ]]; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo -n "  • wtls script exists... "
if [[ -f "${SCRIPT_DIR}/wtls" ]]; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 2: Old commands have --version flag
echo -n "  • wtnew --version works... "
source "${SCRIPT_DIR}/wtnew"
output=$(wtnew --version 2>&1)
if echo "$output" | grep -q "git-worktrees wtnew v"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 3: wt script still has original hub behavior
echo -n "  • wt hub logic intact... "
if grep -q "Interactive Hub Logic" "${SCRIPT_DIR}/wt" || \
   grep -q "Build list.*branch.*path" "${SCRIPT_DIR}/wt"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 4: Subcommands dispatch to old commands
echo -n "  • wt new dispatches to wtnew... "
if grep -q "wtnew.*\$@" "${SCRIPT_DIR}/wt"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo -n "  • wt remove dispatches to wtrm... "
if grep -q "wtrm.*\$@" "${SCRIPT_DIR}/wt"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo ""
echo "Phase 2 backward compatibility tests: PASSED ✓"

