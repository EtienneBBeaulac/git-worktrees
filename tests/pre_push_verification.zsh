#!/usr/bin/env zsh
# Fast Pre-Push Verification
# Only tests what we can verify quickly

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            PRE-PUSH VERIFICATION                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

FAILURES=0

# 1. Syntax
echo "[1/5] Syntax Validation..."
zsh -fn scripts/wt && zsh -fn scripts/wtnew && zsh -fn scripts/wtrm && \
zsh -fn scripts/lib/wt-common.zsh && zsh -fn scripts/lib/wt-recovery.zsh && \
zsh -fn scripts/lib/wt-validation.zsh && zsh -fn scripts/lib/wt-discovery.zsh && \
echo "      ✅ PASS" || { echo "      ❌ FAIL"; ((FAILURES++)); }

# 2. Legacy Tests
echo "[2/5] Legacy Tests..."
if bash tests/run.sh 2>&1 | tail -1 | grep -q "OK"; then
  echo "      ✅ PASS"
else
  echo "      ❌ FAIL"
  ((FAILURES++))
fi

# 3. wtnew Basic Test
echo "[3/5] wtnew Basic Test..."
TEMP=$(mktemp -d)
WT_DIR=$(mktemp -d)
(
  cd "$TEMP"
  git init -q
  git config user.email "t@t.com"
  git config user.name "T"
  echo "x" > f
  git add .
  git commit -q -m "x"
  source "$ROOT_DIR/scripts/wtnew"
  wtnew --name "test" --no-open --dir "$WT_DIR" >/dev/null 2>&1
  [[ -d "$WT_DIR/.git" ]]
) && echo "      ✅ PASS" || { echo "      ❌ FAIL"; ((FAILURES++)); }
rm -rf "$TEMP" "$WT_DIR"

# 4. wtrm Basic Test
echo "[4/5] wtrm Basic Test..."
TEMP=$(mktemp -d)
(
  cd "$TEMP"
  git init -q
  git config user.email "t@t.com"
  git config user.name "T"
  echo "x" > f
  git add .
  git commit -q -m "x"
  source "$ROOT_DIR/scripts/wtrm"
  wtrm --help >/dev/null 2>&1
) && echo "      ✅ PASS" || { echo "      ❌ FAIL"; ((FAILURES++)); }
rm -rf "$TEMP"

# 5. Graceful Degradation
echo "[5/5] Graceful Degradation..."
TEMP=$(mktemp -d)
WT_DIR=$(mktemp -d)
(
  cd "$TEMP"
  git init -q
  git config user.email "t@t.com"
  git config user.name "T"
  echo "x" > f
  git add .
  git commit -q -m "x"
  source "$ROOT_DIR/scripts/wtnew"
  WT_NO_RECOVERY=1 wtnew --name "test" --no-open --dir "$WT_DIR" >/dev/null 2>&1
  [[ -d "$WT_DIR/.git" ]]
) && echo "      ✅ PASS" || { echo "      ❌ FAIL"; ((FAILURES++)); }
rm -rf "$TEMP" "$WT_DIR"

echo ""
echo "══════════════════════════════════════════════════════════════"
if [[ $FAILURES -eq 0 ]]; then
  echo "✅ ALL AUTOMATED TESTS PASSED (5/5)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "READY FOR MANUAL VERIFICATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Run: zsh tests/manual_verification.zsh"
  echo ""
  echo "This will test interactive features (~5 min)"
  echo ""
  exit 0
else
  echo "❌ FAILED: $FAILURES/5"
  echo ""
  exit 1
fi

