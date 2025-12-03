#!/usr/bin/env zsh
# Unit tests for wt_msg_*() output helper functions
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

# Test helpers
PASSED=0
FAILED=0

test_start() { echo -n "  $1... "; }
test_pass() { echo "✓"; ((PASSED++)) || true; }
test_fail() { echo "✗ ${1:-}"; ((FAILED++)) || true; }

echo "Testing wt_msg_*() output helpers"

# ============================================================================
# wt_msg_error tests
# ============================================================================

test_start "wt_msg_error outputs to stderr"
result=$(wt_msg_error "test error" 2>&1 >/dev/null) || true
[[ -n "$result" ]] && test_pass || test_fail "Should output to stderr"

test_start "wt_msg_error includes message text"
result=$(wt_msg_error "specific message" 2>&1) || true
[[ "$result" == *"specific message"* ]] && test_pass || test_fail

test_start "wt_msg_error includes error emoji"
result=$(wt_msg_error "test" 2>&1) || true
[[ "$result" == *"❌"* ]] && test_pass || test_fail

test_start "wt_msg_error returns non-zero by default"
if wt_msg_error "test" 2>/dev/null; then
  test_fail "Should return non-zero"
else
  test_pass
fi

test_start "wt_msg_error returns specified exit code"
wt_msg_error "test" 42 2>/dev/null || exit_code=$?
[[ ${exit_code:-0} -eq 42 ]] && test_pass || test_fail "Expected 42, got ${exit_code:-0}"

# ============================================================================
# wt_msg_warn tests
# ============================================================================

test_start "wt_msg_warn outputs to stderr"
result=$(wt_msg_warn "test warning" 2>&1 >/dev/null)
[[ -n "$result" ]] && test_pass || test_fail

test_start "wt_msg_warn includes warning emoji"
result=$(wt_msg_warn "test" 2>&1)
[[ "$result" == *"⚠"* ]] && test_pass || test_fail

test_start "wt_msg_warn includes message text"
result=$(wt_msg_warn "warning text" 2>&1)
[[ "$result" == *"warning text"* ]] && test_pass || test_fail

# ============================================================================
# wt_msg_success tests
# ============================================================================

test_start "wt_msg_success outputs to stdout"
result=$(wt_msg_success "test success" 2>/dev/null)
[[ -n "$result" ]] && test_pass || test_fail

test_start "wt_msg_success includes success emoji"
result=$(wt_msg_success "test")
[[ "$result" == *"✅"* ]] && test_pass || test_fail

test_start "wt_msg_success includes message text"
result=$(wt_msg_success "success text")
[[ "$result" == *"success text"* ]] && test_pass || test_fail

# ============================================================================
# wt_msg_info tests
# ============================================================================

test_start "wt_msg_info outputs to stderr"
result=$(wt_msg_info "test info" 2>&1 >/dev/null)
[[ -n "$result" ]] && test_pass || test_fail

test_start "wt_msg_info includes info emoji"
result=$(wt_msg_info "test" 2>&1)
[[ "$result" == *"ℹ"* ]] && test_pass || test_fail

test_start "wt_msg_info includes message text"
result=$(wt_msg_info "info text" 2>&1)
[[ "$result" == *"info text"* ]] && test_pass || test_fail

# ============================================================================
# wt_msg_status tests
# ============================================================================

test_start "wt_msg_status outputs to stdout"
result=$(wt_msg_status "test status" 2>/dev/null)
[[ -n "$result" ]] && test_pass || test_fail

test_start "wt_msg_status includes rocket emoji"
result=$(wt_msg_status "test")
[[ "$result" == *"🚀"* ]] && test_pass || test_fail

test_start "wt_msg_status includes message text"
result=$(wt_msg_status "status text")
[[ "$result" == *"status text"* ]] && test_pass || test_fail

echo ""
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]] || exit 1

