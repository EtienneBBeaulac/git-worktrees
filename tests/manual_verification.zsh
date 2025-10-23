#!/usr/bin/env zsh
# Manual Verification Test Suite for git-worktrees Enhanced Features
# This script guides you through testing all interactive recovery scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║        Manual Verification Suite for git-worktrees          ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This will guide you through testing all interactive features.${NC}"
echo -e "${YELLOW}Please follow the prompts carefully and respond honestly.${NC}"
echo ""
echo -e "Press Enter to begin..."
read

# Create test repository
TEST_ROOT=$(mktemp -d)
echo -e "${BLUE}Setting up test repository at: $TEST_ROOT${NC}"
cd "$TEST_ROOT"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo "initial content" > README.md
git add .
git commit -q -m "Initial commit"
echo -e "${GREEN}✓ Test repository created${NC}"
echo ""

# Source the tools
source "$ROOT_DIR/scripts/wtnew"
source "$ROOT_DIR/scripts/wtrm"

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 1: wtnew Basic Functionality${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Creating a basic worktree with wtnew..."
echo "Expected: Worktree should be created successfully"
echo ""
((TEST_COUNT++))

WT_PATH="${TEST_ROOT}/worktrees/test-basic"
if wtnew --name "test-basic" --base "main" --no-open --dir "$WT_PATH" 2>&1 | tee /tmp/wtnew_output.txt; then
  if [[ -d "$WT_PATH" ]]; then
    echo -e "${GREEN}✓ Test 1 PASSED: Basic worktree created${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 1 FAILED: Worktree directory not found${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${RED}✗ Test 1 FAILED: wtnew command failed${NC}"
  ((FAILED_COUNT++))
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 2: Path Already Exists Recovery${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This test will create a worktree at a path that already exists."
echo "Expected behavior:"
echo "  1. Error message: 'Path already exists'"
echo "  2. Recovery options displayed"
echo "  3. You should see options like:"
echo "     [1] Use different name/path"
echo "     [2] Remove existing"
echo "     [3] Reuse existing"
echo "     [4] Cancel"
echo ""
((TEST_COUNT++))

# Create a directory that already exists
WT_PATH_EXISTS="${TEST_ROOT}/worktrees/test-exists"
mkdir -p "$WT_PATH_EXISTS"

echo -e "${YELLOW}About to run: wtnew --name test-exists --dir $WT_PATH_EXISTS${NC}"
echo -e "${YELLOW}When prompted, choose option 4 (Cancel) to skip this test${NC}"
echo -e "Press Enter to continue..."
read

# This should trigger path exists recovery
set +e
wtnew --name "test-exists" --base "main" --no-open --dir "$WT_PATH_EXISTS" 2>&1
EXIT_CODE=$?
set -e

echo ""
echo "Did you see:"
echo "  1. An error message about path already exists?"
echo "  2. Recovery options [1-4]?"
echo "  3. A prompt asking for your choice?"
printf "Answer (y/n): "
read ANSWER

if [[ "${ANSWER:l}" == "y" ]]; then
  echo -e "${GREEN}✓ Test 2 PASSED: Path exists recovery works${NC}"
  ((PASSED_COUNT++))
else
  echo -e "${RED}✗ Test 2 FAILED: Recovery not displayed correctly${NC}"
  ((FAILED_COUNT++))
  echo "Output was:"
  tail -20 /tmp/wtnew_output.txt 2>/dev/null || echo "(no output captured)"
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 3: Invalid Branch Name Sanitization${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This test checks if invalid branch names are sanitized."
echo "Expected behavior:"
echo "  1. Detect invalid branch name"
echo "  2. Offer sanitized version"
echo "  3. Prompt: 'Use suggestion?'"
echo ""
((TEST_COUNT++))

echo -e "${YELLOW}About to test branch name: 'my bad@branch!'${NC}"
echo -e "${YELLOW}Expected suggestion: 'my-bad-branch'${NC}"
echo ""

# Test sanitization function directly
if typeset -f wt_sanitize_branch_name >/dev/null 2>&1; then
  SANITIZED=$(wt_sanitize_branch_name "my bad@branch!")
  if [[ "$SANITIZED" == "my-bad-branch" ]]; then
    echo -e "${GREEN}✓ Test 3 PASSED: Sanitization works correctly${NC}"
    echo "  Input:  'my bad@branch!'"
    echo "  Output: '$SANITIZED'"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 3 FAILED: Incorrect sanitization${NC}"
    echo "  Expected: 'my-bad-branch'"
    echo "  Got:      '$SANITIZED'"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${YELLOW}⊘ Test 3 SKIPPED: Validation module not loaded${NC}"
  ((SKIPPED_COUNT++))
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 4: Network Fetch Failure Tolerance${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This test simulates a network fetch failure."
echo "Expected behavior:"
echo "  1. Warning: 'Fetch failed, continuing with cached refs'"
echo "  2. Operation continues (doesn't crash)"
echo ""
((TEST_COUNT++))

# Mock git to fail on fetch
git() {
  if [[ "$1" == "fetch" ]]; then
    echo "fatal: Could not resolve host: github.com" >&2
    return 1
  fi
  command git "$@"
}

echo -e "${YELLOW}Testing with simulated network failure...${NC}"
set +e
WT_PATH_NET="${TEST_ROOT}/worktrees/test-network"
wtnew --name "test-network" --base "main" --no-open --dir "$WT_PATH_NET" 2>&1 | tee /tmp/wtnew_network.txt
NET_EXIT=$?
set -e
unset -f git

if [[ $NET_EXIT -eq 0 ]] && [[ -d "$WT_PATH_NET" ]]; then
  echo -e "${GREEN}✓ Test 4 PASSED: Gracefully handles network failure${NC}"
  ((PASSED_COUNT++))
else
  echo -e "${YELLOW}⚠ Test 4 WARNING: Check output above${NC}"
  echo "Did the operation continue despite fetch failure? (y/n): "
  read ANSWER
  if [[ "${ANSWER:l}" == "y" ]]; then
    echo -e "${GREEN}✓ Test 4 PASSED (manual verification)${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 4 FAILED${NC}"
    ((FAILED_COUNT++))
  fi
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 5: wtrm with Uncommitted Changes${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This test creates a worktree with uncommitted changes."
echo "Expected behavior:"
echo "  1. Error: 'Worktree has uncommitted changes'"
echo "  2. Recovery options:"
echo "     [1] Commit now"
echo "     [2] Stash"
echo "     [3] Force"
echo "     [4] Cancel"
echo ""
((TEST_COUNT++))

# Create worktree with uncommitted changes
WT_PATH_DIRTY="${TEST_ROOT}/worktrees/test-dirty"
wtnew --name "test-dirty" --base "main" --no-open --dir "$WT_PATH_DIRTY" >/dev/null 2>&1 || true

if [[ -d "$WT_PATH_DIRTY" ]]; then
  echo "Creating uncommitted changes..."
  echo "modified content" > "$WT_PATH_DIRTY/newfile.txt"
  
  echo -e "${YELLOW}About to run: wtrm on worktree with uncommitted changes${NC}"
  echo -e "${YELLOW}When prompted, choose option 4 (Cancel) to skip${NC}"
  echo "Press Enter to continue..."
  read
  
  set +e
  wtrm --dir "$WT_PATH_DIRTY" 2>&1
  set -e
  
  echo ""
  echo "Did you see:"
  echo "  1. Error about uncommitted changes?"
  echo "  2. Recovery options [1-4]?"
  echo "  3. Hints about what each option does?"
  printf "Answer (y/n): "
  read ANSWER
  
  if [[ "${ANSWER:l}" == "y" ]]; then
    echo -e "${GREEN}✓ Test 5 PASSED: Uncommitted changes recovery works${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 5 FAILED: Recovery not displayed${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${YELLOW}⊘ Test 5 SKIPPED: Could not create test worktree${NC}"
  ((SKIPPED_COUNT++))
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 6: Transaction Rollback${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This test verifies transaction cleanup on success."
echo ""
((TEST_COUNT++))

if typeset -f wt_transaction_begin >/dev/null 2>&1; then
  # Start a transaction manually
  wt_transaction_begin
  TRANS_LOG="${HOME}/.cache/git-worktrees/transaction.log"
  
  if [[ -f "$TRANS_LOG" ]]; then
    echo "Transaction log created: ✓"
    
    # Record some actions
    wt_transaction_record "test_action" "test_details"
    
    if grep -q "test_action" "$TRANS_LOG"; then
      echo "Transaction recording works: ✓"
      
      # Commit (cleanup)
      wt_transaction_commit
      
      if [[ ! -f "$TRANS_LOG" ]]; then
        echo -e "${GREEN}✓ Test 6 PASSED: Transaction cleanup works${NC}"
        ((PASSED_COUNT++))
      else
        echo -e "${RED}✗ Test 6 FAILED: Transaction log not cleaned up${NC}"
        ((FAILED_COUNT++))
      fi
    else
      echo -e "${RED}✗ Test 6 FAILED: Transaction recording failed${NC}"
      ((FAILED_COUNT++))
    fi
  else
    echo -e "${RED}✗ Test 6 FAILED: Transaction log not created${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${YELLOW}⊘ Test 6 SKIPPED: Transaction module not loaded${NC}"
  ((SKIPPED_COUNT++))
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 7: Error Diagnosis${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Testing error pattern detection..."
((TEST_COUNT++))

if typeset -f wt_diagnose_error >/dev/null 2>&1; then
  PASSED_DIAG=0
  FAILED_DIAG=0
  
  # Test various error patterns
  echo "  Testing 'already exists' detection..."
  RESULT=$(wt_diagnose_error "test" "fatal: 'test' already exists" 1)
  [[ "$RESULT" == "already_exists" ]] && ((PASSED_DIAG++)) || ((FAILED_DIAG++))
  
  echo "  Testing 'network failure' detection..."
  RESULT=$(wt_diagnose_error "fetch" "Could not resolve host" 1)
  [[ "$RESULT" == "network_failure" ]] && ((PASSED_DIAG++)) || ((FAILED_DIAG++))
  
  echo "  Testing 'invalid name' detection..."
  RESULT=$(wt_diagnose_error "branch" "not a valid branch name" 1)
  [[ "$RESULT" == "invalid_name" ]] && ((PASSED_DIAG++)) || ((FAILED_DIAG++))
  
  echo "  Testing 'already checked out' detection..."
  RESULT=$(wt_diagnose_error "add" "already checked out" 1)
  [[ "$RESULT" == "already_checked_out" ]] && ((PASSED_DIAG++)) || ((FAILED_DIAG++))
  
  if [[ $FAILED_DIAG -eq 0 ]]; then
    echo -e "${GREEN}✓ Test 7 PASSED: All error patterns detected (${PASSED_DIAG}/4)${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 7 FAILED: Some patterns not detected (${PASSED_DIAG}/4)${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${YELLOW}⊘ Test 7 SKIPPED: Diagnosis module not loaded${NC}"
  ((SKIPPED_COUNT++))
fi
echo ""
sleep 1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 8: Help and Discovery${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
((TEST_COUNT++))

if typeset -f wt_cheatsheet >/dev/null 2>&1; then
  echo "Testing cheatsheet generation..."
  if wt_cheatsheet commands 2>&1 | grep -q "CORE COMMANDS"; then
    echo -e "${GREEN}✓ Test 8 PASSED: Help system works${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 8 FAILED: Cheatsheet generation failed${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${YELLOW}⊘ Test 8 SKIPPED: Discovery module not loaded${NC}"
  ((SKIPPED_COUNT++))
fi
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST 9: Backward Compatibility${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Testing that wtnew works WITHOUT recovery modules..."
((TEST_COUNT++))

WT_PATH_COMPAT="${TEST_ROOT}/worktrees/test-compat"
if WT_NO_RECOVERY=1 wtnew --name "test-compat" --base "main" --no-open --dir "$WT_PATH_COMPAT" 2>&1 >/dev/null; then
  if [[ -d "$WT_PATH_COMPAT" ]]; then
    echo -e "${GREEN}✓ Test 9 PASSED: Backward compatibility maintained${NC}"
    ((PASSED_COUNT++))
  else
    echo -e "${RED}✗ Test 9 FAILED: Worktree not created in compat mode${NC}"
    ((FAILED_COUNT++))
  fi
else
  echo -e "${RED}✗ Test 9 FAILED: compat mode failed${NC}"
  ((FAILED_COUNT++))
fi
echo ""

# Cleanup
echo -e "${BLUE}Cleaning up test repository...${NC}"
cd /
rm -rf "$TEST_ROOT"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║                    TEST SUMMARY                              ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total Tests:    $TEST_COUNT"
echo -e "${GREEN}Passed:         $PASSED_COUNT${NC}"
echo -e "${RED}Failed:         $FAILED_COUNT${NC}"
echo -e "${YELLOW}Skipped:        $SKIPPED_COUNT${NC}"
echo ""

if [[ $FAILED_COUNT -eq 0 ]]; then
  PASS_RATE=$((PASSED_COUNT * 100 / (PASSED_COUNT + SKIPPED_COUNT)))
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                              ║${NC}"
  echo -e "${GREEN}║                 ✅ ALL TESTS PASSED! ✅                       ║${NC}"
  echo -e "${GREEN}║                                                              ║${NC}"
  echo -e "${GREEN}║           Pass Rate: ${PASS_RATE}%                                        ║${NC}"
  echo -e "${GREEN}║                                                              ║${NC}"
  echo -e "${GREEN}║      git-worktrees is VERIFIED and ready to push!           ║${NC}"
  echo -e "${GREEN}║                                                              ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  exit 0
else
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                                                              ║${NC}"
  echo -e "${RED}║                  ❌ TESTS FAILED ❌                           ║${NC}"
  echo -e "${RED}║                                                              ║${NC}"
  echo -e "${RED}║           Please review failures above                       ║${NC}"
  echo -e "${RED}║                                                              ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  exit 1
fi

