#!/usr/bin/env zsh
# Test Phase 2: Better error messages

set -e

echo "Testing Phase 2: Error message helpers"

# Setup
SCRIPT_DIR="${0:A:h}/../scripts"
source "${SCRIPT_DIR}/lib/wt-common.zsh"

# Test 1: wt_error_not_git_repo function exists
echo -n "  • wt_error_not_git_repo exists... "
if typeset -f wt_error_not_git_repo >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 2: wt_error_not_git_repo shows helpful message
echo -n "  • wt_error_not_git_repo shows help... "
output=$(wt_error_not_git_repo 2>&1)
if echo "$output" | grep -q "This command must be run from inside a git repository" && \
   echo "$output" | grep -q "git init" && \
   echo "$output" | grep -q "git clone"; then
  echo "✓"
else
  echo "✗ FAILED"
  echo "$output"
  exit 1
fi

# Test 3: wt_error_fzf_missing function exists
echo -n "  • wt_error_fzf_missing exists... "
if typeset -f wt_error_fzf_missing >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 4: wt_error_fzf_missing shows install instructions
echo -n "  • wt_error_fzf_missing shows install... "
output=$(wt_error_fzf_missing 2>&1)
if echo "$output" | grep -q "install fzf" && \
   echo "$output" | grep -q "brew install fzf"; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 5: wt_error_branch_exists function exists
echo -n "  • wt_error_branch_exists exists... "
if typeset -f wt_error_branch_exists >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED"
  exit 1
fi

# Test 6: wt_error_branch_exists shows suggestions
echo -n "  • wt_error_branch_exists shows suggestions... "
output=$(wt_error_branch_exists "feature" 2>&1)
if echo "$output" | grep -q "Branch 'feature' already exists" && \
   echo "$output" | grep -q "wt open feature" && \
   echo "$output" | grep -q "Did you mean:"; then
  echo "✓"
else
  echo "✗ FAILED"
  echo "$output"
  exit 1
fi

echo ""
echo "Phase 2 error message tests: PASSED ✓"

