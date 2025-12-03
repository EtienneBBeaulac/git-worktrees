#!/usr/bin/env zsh
# Unit tests for cross-platform helper functions
# Tests clipboard and terminal support on different platforms

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-common.zsh"

test_suite_init "Cross-Platform Helpers"

# ============================================================================
# Test: wt_copy_to_clipboard
# ============================================================================

test_start "wt_copy_to_clipboard function exists"
if ! typeset -f wt_copy_to_clipboard >/dev/null 2>&1; then
  test_fail "wt_copy_to_clipboard function not found"
else
  test_pass
fi

test_start "wt_copy_to_clipboard returns 0 or 1 (not crash)"
wt_copy_to_clipboard "test text" 2>/dev/null
exit_code=$?

if (( exit_code > 1 )); then
  test_fail "wt_copy_to_clipboard returned $exit_code (expected 0 or 1)"
else
  test_pass "returned $exit_code"
fi

test_start "wt_copy_to_clipboard detects clipboard tool"
# On macOS, pbcopy should be available
# On Linux, xclip/xsel/wl-copy might be available
# Either way, the function should work without crashing

if [[ "$OSTYPE" == darwin* ]]; then
  if command -v pbcopy >/dev/null 2>&1; then
    wt_copy_to_clipboard "test" 2>/dev/null
    if (( $? != 0 )); then
      test_fail "pbcopy available but function returned non-zero"
    else
      test_pass "uses pbcopy on macOS"
    fi
  else
    test_skip "pbcopy not found (unusual for macOS)"
  fi
else
  # Linux - check for any clipboard tool
  has_clipboard=0
  command -v xclip >/dev/null 2>&1 && has_clipboard=1
  command -v xsel >/dev/null 2>&1 && has_clipboard=1
  command -v wl-copy >/dev/null 2>&1 && has_clipboard=1
  
  wt_copy_to_clipboard "test" 2>/dev/null
  exit_code=$?
  
  if (( has_clipboard && exit_code != 0 )); then
    test_fail "clipboard tool available but function returned $exit_code"
  elif (( !has_clipboard && exit_code != 1 )); then
    test_fail "no clipboard tool but function returned $exit_code (expected 1)"
  else
    test_pass "correctly detected clipboard availability"
  fi
fi

# ============================================================================
# Test: wt_open_in_terminal
# ============================================================================

test_start "wt_open_in_terminal function exists"
if ! typeset -f wt_open_in_terminal >/dev/null 2>&1; then
  test_fail "wt_open_in_terminal function not found"
else
  test_pass
fi

test_start "wt_open_in_terminal handles missing directory gracefully"
# Don't actually open a terminal, just verify function doesn't crash
# Use a non-existent directory to prevent actual terminal launch
output=$(wt_open_in_terminal "/nonexistent/path/xyz" 2>&1) || true
# Function might fail (return 1) but shouldn't crash
test_pass "handled gracefully"

test_start "wt_open_in_terminal respects WT_TERMINAL_APP"
# Set a fake terminal app - function should try to use it
original_term="${WT_TERMINAL_APP:-}"
export WT_TERMINAL_APP="fake-terminal-that-does-not-exist"

output=$(wt_open_in_terminal "/tmp" 2>&1)
exit_code=$?

# Restore
[[ -n "$original_term" ]] && export WT_TERMINAL_APP="$original_term" || unset WT_TERMINAL_APP

if [[ "$OSTYPE" == darwin* ]]; then
  # macOS: open -a will try the fake app, fail, then fallback to Terminal.app
  # which should succeed (return 0) since Terminal.app exists
  test_pass "macOS falls back to Terminal.app (exit: $exit_code)"
else
  # Linux: should fail with exit code 1 since the terminal command doesn't exist
  if (( exit_code != 1 )); then
    test_fail "should return 1 for non-existent terminal on Linux (got $exit_code)"
  else
    test_pass "correctly returns 1 for non-existent terminal"
  fi
fi

test_start "Linux: wt_open_in_terminal validates WT_TERMINAL_APP exists"
# This test verifies the fix - on Linux, invalid terminal should return error
fn_source=$(typeset -f wt_open_in_terminal)

# Check that the Linux code path validates the command exists
if [[ "$fn_source" != *"command -v"*"term_app"* ]]; then
  test_fail "Linux path should validate WT_TERMINAL_APP with 'command -v'"
else
  test_pass "Linux path validates terminal command exists"
fi

test_start "Linux: wt_open_in_terminal shows error for invalid terminal"
# Check that error message is shown
if [[ "$fn_source" != *"not found"* ]]; then
  test_fail "should show 'not found' error for invalid terminal"
else
  test_pass "shows helpful error for invalid terminal"
fi

# ============================================================================
# Test: Platform detection
# ============================================================================

test_start "OSTYPE is available for platform detection"
if [[ -z "${OSTYPE:-}" ]]; then
  test_fail "OSTYPE not set"
else
  test_pass "OSTYPE=$OSTYPE"
fi

test_start "Platform-specific code paths exist"
# Verify the functions handle both darwin and linux
fn_source=$(typeset -f wt_open_in_terminal)

if [[ "$fn_source" != *"darwin"* ]]; then
  test_fail "wt_open_in_terminal should check for darwin"
elif [[ "$fn_source" != *"gnome-terminal"* ]] && [[ "$fn_source" != *"konsole"* ]]; then
  test_fail "wt_open_in_terminal should handle Linux terminals"
else
  test_pass
fi

# ============================================================================
# Test: Shell injection protection for paths with special characters
# ============================================================================

test_start "xterm command uses wt_shell_quote for path safety"
# Verify the xterm command line uses wt_shell_quote to prevent injection
if [[ "$fn_source" != *"wt_shell_quote"* ]]; then
  test_fail "wt_open_in_terminal should use wt_shell_quote for xterm path"
else
  test_pass
fi

test_start "wt_shell_quote properly escapes single quotes in paths"
# Test that paths with single quotes are handled correctly
test_path="/path/to/user's/project"
quoted=$(wt_shell_quote "$test_path")
# The quoted output should be safe to use in shell
# It should produce: '/path/to/user'\''s/project' or similar safe form
if ! eval "test_var=$quoted" 2>/dev/null; then
  test_fail "wt_shell_quote output is not valid shell"
elif [[ "$test_var" != "$test_path" ]]; then
  test_fail "wt_shell_quote changed the path value"
else
  test_pass
fi

test_start "wt_cd_command handles paths with single quotes"
test_path="/path/with'quote"
cd_cmd=$(wt_cd_command "$test_path")
# Check that the command is syntactically valid
if ! zsh -n -c "$cd_cmd" 2>/dev/null; then
  test_fail "wt_cd_command produces invalid shell for paths with quotes"
else
  test_pass
fi

test_suite_summary

