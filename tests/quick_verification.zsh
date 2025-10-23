#!/usr/bin/env zsh
# Quick Automated Verification Suite
# Fast automated tests before manual testing

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         QUICK AUTOMATED VERIFICATION                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_FAILURES=0

# Test 1: Syntax validation
echo "1. Syntax Validation..."
SYNTAX_FAILED=0
for script in scripts/wt* scripts/lib/*.zsh scripts/bin/wt*; do
  [[ -f "$script" ]] || continue
  zsh -fn "$script" 2>&1 || ((SYNTAX_FAILED++))
done

if [[ $SYNTAX_FAILED -eq 0 ]]; then
  echo "   ✅ All scripts valid"
else
  echo "   ❌ $SYNTAX_FAILED scripts failed"
  ((TOTAL_FAILURES++))
fi

# Test 2: Module loading
echo "2. Module Loading..."
if zsh -c "source scripts/lib/wt-common.zsh >/dev/null 2>&1" ; then
  echo "   ✅ Modules load correctly"
else
  echo "   ❌ Module loading failed"
  ((TOTAL_FAILURES++))
fi

# Test 3: Legacy tests
echo "3. Legacy Tests (Backward Compatibility)..."
if bash tests/run.sh 2>&1 | grep -q "OK"; then
  echo "   ✅ Legacy tests passed"
else
  echo "   ❌ Legacy tests failed"
  ((TOTAL_FAILURES++))
fi

# Test 4: Basic function tests
echo "4. Core Function Tests..."
FUNC_PASSED=0
FUNC_FAILED=0

# Test error diagnosis
if zsh -c "source scripts/lib/wt-recovery.zsh >/dev/null 2>&1 && [[ \$(wt_diagnose_error 'test' 'already exists' 1) == 'already_exists' ]]" 2>/dev/null; then
  ((FUNC_PASSED++))
else
  ((FUNC_FAILED++))
fi

# Test branch validation
if zsh -c "source scripts/lib/wt-validation.zsh >/dev/null 2>&1 && wt_validate_branch_name 'valid-branch'" 2>/dev/null; then
  ((FUNC_PASSED++))
else
  ((FUNC_FAILED++))
fi

# Test branch sanitization
SANITIZED=$(zsh -c "source scripts/lib/wt-validation.zsh >/dev/null 2>&1 && wt_sanitize_branch_name 'my bad@branch!'" 2>/dev/null || echo "")
if [[ "$SANITIZED" == "my-bad-branch" ]]; then
  ((FUNC_PASSED++))
else
  ((FUNC_FAILED++))
fi

if [[ $FUNC_FAILED -eq 0 ]]; then
  echo "   ✅ Core functions work ($FUNC_PASSED/3)"
else
  echo "   ⚠️  Some functions failed ($FUNC_PASSED/3 passed)"
  ((TOTAL_FAILURES++))
fi

# Test 5: wtnew integration
echo "5. wtnew Integration..."
TEST_ROOT=$(mktemp -d)
cd "$TEST_ROOT"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add .
git commit -q -m "init"

source "$ROOT_DIR/scripts/wtnew"

WT_PATH="$TEST_ROOT/wt-test"
if wtnew --name "test" --base "main" --no-open --dir "$WT_PATH" >/dev/null 2>&1 && [[ -d "$WT_PATH" ]]; then
  echo "   ✅ wtnew creates worktrees"
else
  echo "   ❌ wtnew failed"
  ((TOTAL_FAILURES++))
fi

cd "$ROOT_DIR"
rm -rf "$TEST_ROOT"

# Test 6: Graceful degradation
echo "6. Graceful Degradation..."
TEST_ROOT=$(mktemp -d)
cd "$TEST_ROOT"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add .
git commit -q -m "init"

source "$ROOT_DIR/scripts/wtnew"

WT_PATH="$TEST_ROOT/wt-compat"
if WT_NO_RECOVERY=1 wtnew --name "compat" --base "main" --no-open --dir "$WT_PATH" >/dev/null 2>&1 && [[ -d "$WT_PATH" ]]; then
  echo "   ✅ Works without recovery modules"
else
  echo "   ❌ Graceful degradation failed"
  ((TOTAL_FAILURES++))
fi

cd "$ROOT_DIR"
rm -rf "$TEST_ROOT"

echo ""
echo "═══════════════════════════════════════════════════════════════"

if [[ $TOTAL_FAILURES -eq 0 ]]; then
  echo "✅ ALL AUTOMATED TESTS PASSED!"
  echo ""
  echo "Next: Run manual verification"
  echo "  $ zsh tests/manual_verification.zsh"
  echo ""
  exit 0
else
  echo "❌ $TOTAL_FAILURES TEST(S) FAILED"
  echo ""
  echo "Please fix failures before proceeding."
  echo ""
  exit 1
fi

