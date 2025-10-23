#!/usr/bin/env zsh
# Test Phase 2: Subcommand dispatch

set -e

echo "Testing Phase 2: Subcommand dispatch"

# Setup
SCRIPT_DIR="${0:A:h}/../scripts"
source "${SCRIPT_DIR}/wt"

# Test 1: wt help works
echo -n "  • wt help... "
output=$(wt help 2>&1)
if echo "$output" | grep -q "git-worktrees - Manage Git worktrees"; then
  echo "✓"
else
  echo "✗ FAILED"
  echo "$output"
  exit 1
fi

# Test 2: wt --help works (short form)
echo -n "  • wt --help... "
output=$(wt --help 2>&1)
if echo "$output" | grep -q "Subcommands:"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 3: wt --version works
echo -n "  • wt --version... "
output=$(wt --version 2>&1)
if echo "$output" | grep -q "git-worktrees wt v"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 4: wt config works
echo -n "  • wt config responds... "
output=$(wt config 2>&1)
if echo "$output" | grep -q "Config file:" || \
   echo "$output" | grep -q "No config file found" || \
   echo "$output" | grep -q "wt config init"; then
  echo "✓"
else
  echo "✗ FAILED"
  echo "$output"
  exit 1
fi

# Test 5: Subcommand aliases work (n, rm, o, ls)
echo -n "  • Short aliases registered... "
# Just check that the case statement would match these
if grep -q "new|n)" "${SCRIPT_DIR}/wt" && \
   grep -q "remove|rm)" "${SCRIPT_DIR}/wt" && \
   grep -q "open|o)" "${SCRIPT_DIR}/wt" && \
   grep -q "list|ls)" "${SCRIPT_DIR}/wt"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

echo ""
echo "Phase 2 subcommand tests: PASSED ✓"

