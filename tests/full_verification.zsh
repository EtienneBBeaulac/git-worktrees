#!/usr/bin/env zsh
# Automated Full Verification Suite
# Runs ALL possible automated tests before pushing

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         FULL AUTOMATED VERIFICATION SUITE                    ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_FAILURES=0

# Test 1: Syntax validation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Syntax Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SYNTAX_FAILED=0
for script in scripts/* scripts/lib/* scripts/bin/*; do
  [[ -f "$script" ]] || continue
  [[ "$script" == *.zsh ]] || [[ "$script" == */wt* ]] || continue
  
  if zsh -fn "$script" 2>&1; then
    echo "  ✓ $script"
  else
    echo "  ✗ $script FAILED"
    ((SYNTAX_FAILED++))
  fi
done

if [[ $SYNTAX_FAILED -eq 0 ]]; then
  echo "✅ SYNTAX VALIDATION: PASSED"
else
  echo "❌ SYNTAX VALIDATION: FAILED ($SYNTAX_FAILED files)"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 2: Module loading
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Module Loading"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if zsh -c "source scripts/lib/wt-common.zsh && typeset -f wt_retry && typeset -f wt_validate_branch_name && typeset -f wt_cheatsheet" >/dev/null 2>&1; then
  echo "  ✓ wt-recovery.zsh"
  echo "  ✓ wt-validation.zsh"
  echo "  ✓ wt-discovery.zsh"
  echo "✅ MODULE LOADING: PASSED"
else
  echo "❌ MODULE LOADING: FAILED"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 3: Legacy test suite
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: Legacy Test Suite (Backward Compatibility)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bash tests/run.sh 2>&1 | tee /tmp/legacy_tests.log | grep -E "(OK|FAIL)" | tail -5; then
  LEGACY_FAILED=$(grep -c "FAIL" /tmp/legacy_tests.log 2>/dev/null || true)
  if [[ -z "$LEGACY_FAILED" || "$LEGACY_FAILED" == "0" ]]; then
    echo "✅ LEGACY TESTS: PASSED"
  else
    echo "❌ LEGACY TESTS: FAILED ($LEGACY_FAILED failures)"
    ((TOTAL_FAILURES++))
  fi
else
  echo "❌ LEGACY TESTS: EXECUTION FAILED"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 4: Unit tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Unit Tests (Phase 1 Modules)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
UNIT_PASSED=0
UNIT_FAILED=0

# Test recovery module functions
if zsh -c "source scripts/lib/wt-recovery.zsh >/dev/null 2>&1 && 
  wt_diagnose_error 'test' 'already exists' 1 | grep -q 'already_exists' &&
  wt_diagnose_error 'test' 'Network is unreachable' 1 | grep -q 'network_failure' &&
  wt_diagnose_error 'test' 'not a valid branch name' 1 | grep -q 'invalid_name'" 2>/dev/null; then
  echo "  ✓ Error diagnosis patterns"
  ((UNIT_PASSED++))
else
  echo "  ✗ Error diagnosis patterns"
  ((UNIT_FAILED++))
fi

# Test validation module functions
VALID_TEST=$(zsh -c "source scripts/lib/wt-validation.zsh >/dev/null 2>&1 && wt_validate_branch_name 'valid-branch' && echo 'ok'" 2>/dev/null)
INVALID_TEST=$(zsh -c "source scripts/lib/wt-validation.zsh >/dev/null 2>&1 && wt_validate_branch_name 'invalid@branch' && echo 'ok'" 2>/dev/null)
SANITIZE_TEST=$(zsh -c "source scripts/lib/wt-validation.zsh >/dev/null 2>&1 && wt_sanitize_branch_name 'my bad@branch!'" 2>/dev/null)
if [[ "$VALID_TEST" == "ok" && -z "$INVALID_TEST" && "$SANITIZE_TEST" == "my-bad-branch" ]]; then
  echo "  ✓ Branch validation and sanitization"
  ((UNIT_PASSED++))
else
  echo "  ✗ Branch validation and sanitization"
  ((UNIT_FAILED++))
fi

# Test discovery module functions
if zsh -c "source scripts/lib/wt-discovery.zsh >/dev/null 2>&1 &&
  wt_cheatsheet commands | grep -q 'CORE COMMANDS'" 2>/dev/null; then
  echo "  ✓ Help system and cheatsheet"
  ((UNIT_PASSED++))
else
  echo "  ✗ Help system and cheatsheet"
  ((UNIT_FAILED++))
fi

if [[ $UNIT_FAILED -eq 0 ]]; then
  echo "✅ UNIT TESTS: PASSED ($UNIT_PASSED tests)"
else
  echo "❌ UNIT TESTS: FAILED ($UNIT_PASSED passed, $UNIT_FAILED failed)"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 5: Integration - wtnew
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: Integration - wtnew"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_ROOT=$(mktemp -d)
cd "$TEST_ROOT"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add .
git commit -q -m "init"

source "$ROOT_DIR/scripts/wtnew"

WTNEW_FAILED=0

# Test: wtnew --help
if wtnew --help >/dev/null 2>&1; then
  echo "  ✓ wtnew --help works"
else
  echo "  ✗ wtnew --help failed"
  ((WTNEW_FAILED++))
fi

# Test: Basic worktree creation
WT_PATH="$TEST_ROOT/worktrees/test1"
if wtnew --name "test1" --base "main" --no-open --dir "$WT_PATH" >/dev/null 2>&1; then
  if [[ -d "$WT_PATH" ]]; then
    echo "  ✓ Basic worktree creation"
  else
    echo "  ✗ Worktree directory not created"
    ((WTNEW_FAILED++))
  fi
else
  echo "  ✗ Basic worktree creation failed"
  ((WTNEW_FAILED++))
fi

# Test: Path exists error handling
mkdir -p "$TEST_ROOT/worktrees/test-exists"
if ! wtnew --name "test-exists" --dir "$TEST_ROOT/worktrees/test-exists" --no-open 2>&1 | grep -q "already exists"; then
  echo "  ✗ Path exists error not detected"
  ((WTNEW_FAILED++))
else
  echo "  ✓ Path exists error detected"
fi

cd "$ROOT_DIR"
rm -rf "$TEST_ROOT"

if [[ $WTNEW_FAILED -eq 0 ]]; then
  echo "✅ WTNEW INTEGRATION: PASSED"
else
  echo "❌ WTNEW INTEGRATION: FAILED ($WTNEW_FAILED failures)"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 6: Integration - wtrm
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: Integration - wtrm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_ROOT=$(mktemp -d)
cd "$TEST_ROOT"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add .
git commit -q -m "init"

source "$ROOT_DIR/scripts/wtrm"

WTRM_FAILED=0

# Test: wtrm --help
if wtrm --help >/dev/null 2>&1; then
  echo "  ✓ wtrm --help works"
else
  echo "  ✗ wtrm --help failed"
  ((WTRM_FAILED++))
fi

# Test: wtrm --prune-only
if wtrm --prune-only >/dev/null 2>&1; then
  echo "  ✓ wtrm --prune-only works"
else
  echo "  ✗ wtrm --prune-only failed"
  ((WTRM_FAILED++))
fi

cd "$ROOT_DIR"
rm -rf "$TEST_ROOT"

if [[ $WTRM_FAILED -eq 0 ]]; then
  echo "✅ WTRM INTEGRATION: PASSED"
else
  echo "❌ WTRM INTEGRATION: FAILED ($WTRM_FAILED failures)"
  ((TOTAL_FAILURES++))
fi
echo ""

# Test 7: Graceful degradation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 7: Graceful Degradation (WT_NO_RECOVERY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_ROOT=$(mktemp -d)
cd "$TEST_ROOT"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add .
git commit -q -m "init"

source "$ROOT_DIR/scripts/wtnew"

WT_PATH="$TEST_ROOT/worktrees/compat"
if WT_NO_RECOVERY=1 wtnew --name "compat" --base "main" --no-open --dir "$WT_PATH" >/dev/null 2>&1; then
  if [[ -d "$WT_PATH" ]]; then
    echo "  ✓ Works without recovery modules"
    echo "✅ GRACEFUL DEGRADATION: PASSED"
  else
    echo "  ✗ Failed without recovery modules"
    echo "❌ GRACEFUL DEGRADATION: FAILED"
    ((TOTAL_FAILURES++))
  fi
else
  echo "  ✗ Failed without recovery modules"
  echo "❌ GRACEFUL DEGRADATION: FAILED"
  ((TOTAL_FAILURES++))
fi

cd "$ROOT_DIR"
rm -rf "$TEST_ROOT"
echo ""

# Final Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║                  VERIFICATION SUMMARY                        ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [[ $TOTAL_FAILURES -eq 0 ]]; then
  echo "✅ ALL AUTOMATED TESTS PASSED!"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "NEXT STEP: Run manual verification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Run: zsh tests/manual_verification.zsh"
  echo ""
  echo "This will test interactive features that cannot be automated."
  echo ""
  exit 0
else
  echo "❌ $TOTAL_FAILURES TEST CATEGORIES FAILED"
  echo ""
  echo "Please fix failures above before proceeding."
  echo ""
  exit 1
fi

