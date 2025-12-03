#!/usr/bin/env zsh
# Unit tests to ensure documentation matches implementation
# These tests would have caught the issues we fixed

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-common.zsh"
source "$ROOT_DIR/scripts/lib/wt-discovery.zsh"

test_suite_init "Documentation Consistency"

# ============================================================================
# Test: Cheatsheet shortcuts match actual hub implementation
# ============================================================================

test_start "Cheatsheet shortcuts match wt hub --expect= list"
# Extract shortcuts from cheatsheet
cheatsheet_output=$(wt_cheatsheet shortcuts 2>&1)
# The hub expects these keys (from scripts/wt line ~558)
# --expect=enter,ctrl-o,ctrl-d,ctrl-p,ctrl-n,ctrl-r,ctrl-a,ctrl-e,ctrl-h
expected_shortcuts=("Enter" "Ctrl-O" "Ctrl-N" "Ctrl-R" "Ctrl-D" "Ctrl-P" "Ctrl-A" "Ctrl-E" "Ctrl-H" "Esc")

missing=""
for shortcut in "${expected_shortcuts[@]}"; do
  if [[ "$cheatsheet_output" != *"$shortcut"* ]]; then
    missing+="$shortcut "
  fi
done

if [[ -n "$missing" ]]; then
  test_fail "Cheatsheet missing shortcuts: $missing"
else
  test_pass
fi

test_start "Cheatsheet does NOT document non-existent shortcuts"
# These were incorrectly documented before the fix
non_existent=("Ctrl-Y" "Ctrl-L" "Ctrl-F")
found_bad=""
for shortcut in "${non_existent[@]}"; do
  if [[ "$cheatsheet_output" == *"$shortcut"* ]]; then
    found_bad+="$shortcut "
  fi
done

if [[ -n "$found_bad" ]]; then
  test_fail "Cheatsheet documents non-existent shortcuts: $found_bad"
else
  test_pass
fi

# ============================================================================
# Test: wtnew help documents correct flags
# ============================================================================

test_start "wtnew help shows -b/--base (not --from)"
source "$ROOT_DIR/scripts/wtnew"
wtnew_help=$(wtnew --help 2>&1)

if [[ "$wtnew_help" != *"-b, --base"* ]] && [[ "$wtnew_help" != *"--base"* ]]; then
  test_fail "wtnew help should document -b/--base flag"
elif [[ "$wtnew_help" == *"--from"* ]]; then
  test_fail "wtnew help should NOT document --from (use --base instead)"
else
  test_pass
fi

test_start "wtnew help shows positional branch-name argument"
if [[ "$wtnew_help" != *"branch-name"* ]] && [[ "$wtnew_help" != *"[branch"* ]]; then
  test_fail "wtnew help should document positional branch argument"
else
  test_pass
fi

# ============================================================================
# Test: Discovery examples use correct flags
# ============================================================================

test_start "wt_show_examples wtnew uses -b (not --from)"
examples_output=$(wt_show_examples wtnew 2>&1)

if [[ "$examples_output" == *"--from"* ]]; then
  test_fail "wtnew examples should use -b, not --from"
elif [[ "$examples_output" != *"-b "* ]] && [[ "$examples_output" != *"-b main"* ]]; then
  test_fail "wtnew examples should show -b flag"
else
  test_pass
fi

test_start "wt_show_examples wt uses subcommands (not --list, --new)"
examples_output=$(wt_show_examples wt 2>&1)

if [[ "$examples_output" == *"wt --list"* ]]; then
  test_fail "wt examples should use 'wt list' not 'wt --list'"
elif [[ "$examples_output" == *"wt --new"* ]]; then
  test_fail "wt examples should use 'wt new' not 'wt --new'"
else
  test_pass
fi

# ============================================================================
# Test: Environment variables documentation
# ============================================================================

test_start "Documented env vars actually exist in code"
env_section=$(wt_cheatsheet env 2>&1)

# These should be documented (they're actually used)
documented_vars=("WT_EDITOR" "WT_FZF_OPTS" "WT_DEBUG")
for var in "${documented_vars[@]}"; do
  if [[ "$env_section" != *"$var"* ]]; then
    test_fail "Should document $var (it's actually used)"
  fi
done
test_pass

test_start "Non-implemented env vars are NOT documented"
# WT_START_DIR and WT_WORKTREES_DIR were documented but never implemented
if [[ "$env_section" == *"WT_START_DIR"* ]]; then
  test_fail "WT_START_DIR is documented but not implemented"
elif [[ "$env_section" == *"WT_WORKTREES_DIR"* ]]; then
  test_fail "WT_WORKTREES_DIR is documented but not implemented"
else
  test_pass
fi

# ============================================================================
# Test: Contextual help accuracy
# ============================================================================

test_start "branch_selection help does NOT mention multi-select"
help_output=$(wt_show_contextual_help branch_selection 2>&1)

# Multi-select hints shouldn't appear since wtnew uses single-select
if [[ "$help_output" == *"Select all"* ]] || [[ "$help_output" == *"multi-select"* ]]; then
  test_fail "branch_selection help should not mention multi-select (single-select mode)"
elif [[ "$help_output" == *"Tab: Toggle"* ]]; then
  test_fail "Tab toggle doesn't apply to single-select mode"
else
  test_pass
fi

test_start "fzf_shortcuts help matches actual wt hub keys"
shortcuts_help=$(wt_show_contextual_help fzf_shortcuts 2>&1)

# Should mention the actual actions
if [[ "$shortcuts_help" != *"Create new"* ]] && [[ "$shortcuts_help" != *"Ctrl-N"* ]]; then
  test_fail "Should document Ctrl-N for creating new worktree"
elif [[ "$shortcuts_help" != *"Remove"* ]] && [[ "$shortcuts_help" != *"Ctrl-D"* ]]; then
  test_fail "Should document Ctrl-D for removing worktree"
else
  test_pass
fi

test_suite_summary

