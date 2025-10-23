#!/usr/bin/env zsh
# Unit tests for wt-discovery.zsh - Basic functionality
# Part of Phase 1: Core Infrastructure

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../../.." && pwd)
source "$ROOT_DIR/tests/lib/test_helpers.zsh"
source "$ROOT_DIR/scripts/lib/wt-discovery.zsh"

test_suite_init "wt-discovery: Basic Functions"

# Test: Cheatsheet generation
test_start "wt_cheatsheet generates output for 'all'"
output=$(wt_cheatsheet all 2>&1)
[[ "$output" == *"CORE COMMANDS"* ]] || test_fail "Missing CORE COMMANDS section"
[[ "$output" == *"KEYBOARD SHORTCUTS"* ]] || test_fail "Missing SHORTCUTS section"
test_pass

test_start "wt_cheatsheet generates output for 'commands'"
output=$(wt_cheatsheet commands 2>&1)
[[ "$output" == *"wt [pattern]"* ]] || test_fail "Missing wt command"
[[ "$output" == *"wtnew"* ]] || test_fail "Missing wtnew"
test_pass

# Test: Examples
test_start "wt_show_examples generates output for 'wt'"
output=$(wt_show_examples wt 2>&1)
[[ "$output" == *"Examples"* ]] || test_fail "Missing Examples header"
[[ "$output" == *"wt"* ]] || test_fail "Missing command examples"
test_pass

test_start "wt_show_examples generates output for 'wtnew'"
output=$(wt_show_examples wtnew 2>&1)
[[ "$output" == *"wtnew"* ]] || test_fail "Missing wtnew examples"
test_pass

# Test: Contextual help
test_start "wt_show_contextual_help shows fzf_shortcuts"
output=$(wt_show_contextual_help fzf_shortcuts 2>&1)
[[ "$output" == *"Ctrl-E"* ]] || test_fail "Missing Ctrl-E shortcut"
[[ "$output" == *"Keyboard Shortcuts"* ]] || test_fail "Missing header"
test_pass

# Test: Hints
test_start "wt_show_hints shows first_time hint"
output=$(wt_show_hints first_time 2>&1)
[[ "$output" == *"Welcome"* ]] || test_fail "Missing welcome message"
test_pass

# Test: Feature detection
test_start "wt_has_feature detects fzf"
if command -v fzf >/dev/null 2>&1; then
  wt_has_feature fzf && test_pass || test_fail "Should detect fzf"
else
  wt_has_feature fzf && test_fail "Should not detect fzf" || test_pass
fi

test_start "wt_has_feature returns false for unknown feature"
wt_has_feature unknown_feature_xyz && test_fail "Should not detect unknown" || test_pass

test_suite_summary

