#!/usr/bin/env zsh
# Unit tests for wt hub helper functions
# Tests the internal functions used by the hub

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-common.zsh"
source "$ROOT_DIR/scripts/wt"

test_suite_init "wt Hub Helpers"

# ============================================================================
# Test: _wt_actions_menu function exists
# ============================================================================

test_start "_wt_actions_menu helper function exists"
# The function is defined inside wt(), so we need to check if wt defines it
wt_source=$(typeset -f wt)

if [[ "$wt_source" != *"_wt_actions_menu"* ]]; then
  test_fail "_wt_actions_menu helper should be defined in wt"
else
  test_pass
fi

# ============================================================================
# Test: Actions menu includes Cancel option
# ============================================================================

test_start "Actions menu includes Cancel option"
if [[ "$wt_source" != *'"Cancel"'* ]] && [[ "$wt_source" != *"Cancel"* ]]; then
  test_fail "Actions menu should include Cancel option"
else
  test_pass
fi

# ============================================================================
# Test: Hub uses cross-platform helpers
# ============================================================================

test_start "wt hub uses wt_copy_to_clipboard"
if [[ "$wt_source" != *"wt_copy_to_clipboard"* ]]; then
  test_fail "wt hub should use wt_copy_to_clipboard helper"
else
  test_pass
fi

test_start "wt hub uses wt_open_in_terminal"
if [[ "$wt_source" != *"wt_open_in_terminal"* ]]; then
  test_fail "wt hub should use wt_open_in_terminal helper"
else
  test_pass
fi

# ============================================================================
# Test: Ctrl-H re-launches hub
# ============================================================================

test_start "Ctrl-H handler re-launches hub"
# Check that ctrl-h case re-runs wt
if [[ "$wt_source" != *"ctrl-h)"* ]]; then
  test_fail "ctrl-h case not found"
elif [[ "$wt_source" != *"read -r"* ]]; then
  # The help should wait for user input before re-launching
  test_fail "ctrl-h should wait for user input"
else
  test_pass
fi

# ============================================================================
# Test: All expected key bindings are in --expect=
# ============================================================================

test_start "All documented shortcuts are in --expect= list"
# Extract the --expect= value from the source
expect_line=$(echo "$wt_source" | grep -o "\-\-expect=[^'\"]*" | head -1)

expected_keys=("enter" "ctrl-o" "ctrl-d" "ctrl-p" "ctrl-n" "ctrl-r" "ctrl-a" "ctrl-e" "ctrl-h")
missing=""

for key in "${expected_keys[@]}"; do
  if [[ "$expect_line" != *"$key"* ]]; then
    missing+="$key "
  fi
done

if [[ -n "$missing" ]]; then
  test_fail "Missing keys in --expect=: $missing"
else
  test_pass
fi

# ============================================================================
# Test: No duplicate code in actions handlers
# ============================================================================

test_start "Actions menu code is not duplicated"
# Count occurrences of the action items - should appear in the helper, not twice
cancel_count=$(echo "$wt_source" | grep -c '"Cancel"' || true)
open_in_terminal_count=$(echo "$wt_source" | grep -c '"Open in terminal"' || true)

if (( cancel_count > 2 )); then
  test_fail "Cancel appears $cancel_count times (should be ~1-2)"
elif (( open_in_terminal_count > 2 )); then
  test_fail "Open in terminal appears $open_in_terminal_count times (should be ~1-2)"
else
  test_pass "code is not duplicated"
fi

# ============================================================================
# Test: Header matches actual shortcuts
# ============================================================================

test_start "FZF header documents available shortcuts"
# The header should mention the key shortcuts
if [[ "$wt_source" != *"^N=new"* ]] && [[ "$wt_source" != *"Ctrl-N"* ]]; then
  test_fail "Header should mention Ctrl-N for new"
elif [[ "$wt_source" != *"^A=actions"* ]] && [[ "$wt_source" != *"Ctrl-A"* ]]; then
  test_fail "Header should mention Ctrl-A for actions"
else
  test_pass
fi

# ============================================================================
# Test: Ctrl-A and Enter-in-menu-mode have consistent return behavior
# ============================================================================

test_start "Ctrl-A handler returns 0 after _wt_actions_menu"
# Extract the ctrl-a case block
ctrl_a_block=$(echo "$wt_source" | grep -A5 'ctrl-a)')

if [[ "$ctrl_a_block" != *"return 0"* ]]; then
  test_fail "ctrl-a handler should return 0 after _wt_actions_menu"
else
  test_pass
fi

test_start "Enter-in-menu-mode and Ctrl-A use same return pattern"
# Both should call _wt_actions_menu and return 0
# Count occurrences of "_wt_actions_menu" followed by "return 0" pattern
menu_calls=$(echo "$wt_source" | grep -c "_wt_actions_menu" || true)
return_after_menu=$(echo "$wt_source" | grep -B1 "return 0" | grep -c "_wt_actions_menu" || true)

# Both handlers (enter-in-menu and ctrl-a) should have return 0
if (( return_after_menu < 2 )); then
  test_fail "Both menu handlers should have 'return 0' (found $return_after_menu)"
else
  test_pass "both handlers return 0 consistently"
fi

test_suite_summary

