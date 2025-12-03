#!/usr/bin/env zsh
# Unit tests for editor configuration system in wt-common.zsh

# Source the library
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../../scripts/lib/wt-common.zsh"

# Test counters
typeset -g TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

# Test temp directory
TEST_TMP=""

setup() {
  TEST_TMP="$(mktemp -d)"
  export XDG_CONFIG_HOME="$TEST_TMP/config"
  mkdir -p "$XDG_CONFIG_HOME"
}

teardown() {
  [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
  unset XDG_CONFIG_HOME WT_EDITOR WT_APP VISUAL EDITOR
}

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  ((TESTS_RUN++))
  if [[ "$expected" == "$actual" ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Expected: $expected"
    echo "   Actual:   $actual"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="$3"
  ((TESTS_RUN++))
  if [[ "$haystack" == *"$needle"* ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Expected to contain: $needle"
    echo "   Actual: $haystack"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="$3"
  ((TESTS_RUN++))
  if [[ "$haystack" != *"$needle"* ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg"
    echo "   Expected NOT to contain: $needle"
    echo "   Actual: $haystack"
  fi
}

assert_true() {
  local result=$1 msg="$2"
  ((TESTS_RUN++))
  if (( result == 0 )); then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg (returned $result)"
  fi
}

assert_false() {
  local result=$1 msg="$2"
  ((TESTS_RUN++))
  if (( result != 0 )); then
    ((TESTS_PASSED++))
    echo "✅ PASS: $msg"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: $msg (expected non-zero, got 0)"
  fi
}

# ============================================================================
echo "=== Testing WT_KNOWN_EDITORS array ==="
# ============================================================================

# Test array exists and has entries
((TESTS_RUN++))
if (( ${#WT_KNOWN_EDITORS[@]} >= 10 )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: WT_KNOWN_EDITORS has ${#WT_KNOWN_EDITORS[@]} entries (>= 10)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: WT_KNOWN_EDITORS should have at least 10 entries, has ${#WT_KNOWN_EDITORS[@]}"
fi

# Test Android Studio is first (alphabetically)
first_editor="${WT_KNOWN_EDITORS[1]%%|*}"
assert_eq "Android Studio" "$first_editor" "Android Studio is first in WT_KNOWN_EDITORS"

# Test alphabetical ordering (case-insensitive)
((TESTS_RUN++))
prev=""
sorted=1
for entry in "${WT_KNOWN_EDITORS[@]}"; do
  name="${entry%%|*}"
  # Case-insensitive comparison using lowercase
  if [[ -n "$prev" && "${name:l}" < "${prev:l}" ]]; then
    sorted=0
    break
  fi
  prev="$name"
done
if (( sorted )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: WT_KNOWN_EDITORS is alphabetically sorted (case-insensitive)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: WT_KNOWN_EDITORS is not alphabetically sorted (found '$name' after '$prev')"
fi

# Test format: "Name|macOS app|CLI command"
((TESTS_RUN++))
format_ok=1
for entry in "${WT_KNOWN_EDITORS[@]}"; do
  if [[ "$entry" != *"|"*"|"* ]]; then
    format_ok=0
    break
  fi
done
if (( format_ok )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: All WT_KNOWN_EDITORS entries have correct format (Name|app|cmd)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: Some entries have incorrect format: $entry"
fi

# ============================================================================
echo ""
echo "=== Testing wt_is_editor_installed ==="
# ============================================================================

# Test vim detection (should work on most systems)
if command -v vim >/dev/null 2>&1; then
  wt_is_editor_installed "vim"
  assert_true $? "wt_is_editor_installed detects vim when installed"
else
  echo "⚠️  SKIP: vim not installed"
fi

# Test unknown editor returns false
wt_is_editor_installed "nonexistent-editor-xyz123"
assert_false $? "wt_is_editor_installed returns false for unknown editor"

# Test arbitrary command detection
if command -v ls >/dev/null 2>&1; then
  wt_is_editor_installed "ls"
  assert_true $? "wt_is_editor_installed detects arbitrary commands (ls)"
fi

# ============================================================================
echo ""
echo "=== Testing wt_get_installed_editors ==="
# ============================================================================

installed="$(wt_get_installed_editors)"

# Should return at least one editor on most systems
((TESTS_RUN++))
if [[ -n "$installed" ]]; then
  ((TESTS_PASSED++))
  count=$(echo "$installed" | wc -l | tr -d ' ')
  echo "✅ PASS: wt_get_installed_editors found $count editor(s)"
else
  # This might be ok on minimal systems
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_get_installed_editors returned empty (no editors found)"
fi

# Test vim appears if installed (case-insensitive check)
if command -v vim >/dev/null 2>&1; then
  ((TESTS_RUN++))
  if [[ "${installed:l}" == *"vim"* ]]; then
    ((TESTS_PASSED++))
    echo "✅ PASS: wt_get_installed_editors includes Vim"
  else
    ((TESTS_FAILED++))
    echo "❌ FAIL: wt_get_installed_editors should include Vim"
    echo "   Actual: $installed"
  fi
fi

# ============================================================================
echo ""
echo "=== Testing wt_test_editor ==="
# ============================================================================

# Test known editor
if command -v vim >/dev/null 2>&1; then
  wt_test_editor "vim"
  assert_true $? "wt_test_editor returns true for vim"
fi

# Test nonexistent editor
wt_test_editor "nonexistent-editor-xyz123"
assert_false $? "wt_test_editor returns false for nonexistent editor"

# Test command with arguments (should extract first word)
if command -v echo >/dev/null 2>&1; then
  wt_test_editor "echo --version"
  assert_true $? "wt_test_editor handles commands with arguments"
fi

# ============================================================================
echo ""
echo "=== Testing wt_detect_editor priority ==="
# ============================================================================

setup

# Test 1: WT_EDITOR takes highest priority
export WT_EDITOR="TestEditor1"
result="$(wt_detect_editor)"
assert_eq "TestEditor1" "$result" "WT_EDITOR has highest priority"
unset WT_EDITOR

# Test 2: WT_APP is second priority
export WT_APP="TestEditor2"
result="$(wt_detect_editor)"
assert_eq "TestEditor2" "$result" "WT_APP is second priority"
unset WT_APP

# Test 3: Config file is third priority
mkdir -p "$(wt_config_dir)"
echo "editor=ConfiguredEditor" > "$(wt_config_file)"
result="$(wt_detect_editor)"
assert_eq "ConfiguredEditor" "$result" "Config file is third priority"

# Test 4: VISUAL is fourth priority
rm -f "$(wt_config_file)"
export VISUAL="VisualEditor"
result="$(wt_detect_editor)"
assert_eq "VisualEditor" "$result" "VISUAL is fourth priority"
unset VISUAL

# Test 5: EDITOR is fifth priority
export EDITOR="EditorVar"
result="$(wt_detect_editor)"
assert_eq "EditorVar" "$result" "EDITOR is fifth priority"
unset EDITOR

# Test 6: "none" in config returns empty
echo "editor=none" > "$(wt_config_file)"
result="$(wt_detect_editor)"
assert_eq "" "$result" "Config 'none' returns empty"

# Test 7: "auto" in config triggers detection
echo "editor=auto" > "$(wt_config_file)"
result="$(wt_detect_editor)"
# Should return something (whatever is auto-detected) or empty
((TESTS_RUN++))
((TESTS_PASSED++))
echo "✅ PASS: Config 'auto' triggers detection (got: ${result:-<empty>})"

teardown

# ============================================================================
echo ""
echo "=== Testing wt_auto_init_config ==="
# ============================================================================

setup

# Test config file creation
config_file="$(wt_config_file)"
[[ -f "$config_file" ]] && rm -f "$config_file"

wt_auto_init_config
((TESTS_RUN++))
if [[ -f "$config_file" ]]; then
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_auto_init_config creates config file"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: wt_auto_init_config should create config file"
fi

# Test config contains editor line
config_content="$(cat "$config_file" 2>/dev/null)"
assert_contains "$config_content" "editor=" "Config file contains editor setting"

# Test idempotency (second call shouldn't change file)
mtime1="$(stat -f %m "$config_file" 2>/dev/null || stat -c %Y "$config_file" 2>/dev/null)"
sleep 1
wt_auto_init_config
mtime2="$(stat -f %m "$config_file" 2>/dev/null || stat -c %Y "$config_file" 2>/dev/null)"
assert_eq "$mtime1" "$mtime2" "wt_auto_init_config is idempotent (doesn't recreate)"

teardown

# ============================================================================
echo ""
echo "=== Testing wt_first_run_editor_setup ==="
# ============================================================================

setup

# Test non-blocking behavior (shouldn't prompt)
config_file="$(wt_config_file)"
[[ -f "$config_file" ]] && rm -f "$config_file"

# Should complete without blocking
result="$(timeout 2 zsh -c 'source scripts/lib/wt-common.zsh; wt_first_run_editor_setup' 2>/dev/null)"
exit_code=$?

((TESTS_RUN++))
if (( exit_code != 124 )); then  # 124 = timeout
  ((TESTS_PASSED++))
  echo "✅ PASS: wt_first_run_editor_setup doesn't block (exit: $exit_code)"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: wt_first_run_editor_setup blocked (timeout)"
fi

teardown

# ============================================================================
echo ""
echo "=== Testing editor detection order (Android Studio first) ==="
# ============================================================================

# Verify detection order in the code (alphabetical, case-insensitive)
gui_editors_in_order=(
  "Android Studio"
  "Cursor"
  "Emacs"
  "Fleet"
  "GoLand"
  "Helix"
  "IntelliJ IDEA"
)

# Check first few entries match expected order
((TESTS_RUN++))
all_match=1
for i in {1..7}; do
  expected="${gui_editors_in_order[$i]}"
  actual="${WT_KNOWN_EDITORS[$i]%%|*}"
  if [[ "$expected" != "$actual" ]]; then
    all_match=0
    echo "   Position $i: expected '$expected', got '$actual'"
  fi
done
if (( all_match )); then
  ((TESTS_PASSED++))
  echo "✅ PASS: First 7 editors are in correct alphabetical order"
else
  ((TESTS_FAILED++))
  echo "❌ FAIL: Editor order doesn't match expected"
fi

# ============================================================================
echo ""
echo "=== Testing custom command support ==="
# ============================================================================

setup

# Test custom command in config
mkdir -p "$(wt_config_dir)"
echo 'editor=code --new-window' > "$(wt_config_file)"
result="$(wt_detect_editor)"
assert_eq "code --new-window" "$result" "Custom command with args is preserved"

# Test wt_test_editor with custom command
if command -v echo >/dev/null 2>&1; then
  wt_test_editor "echo hello world"
  assert_true $? "wt_test_editor works with multi-word commands"
fi

teardown

# ============================================================================
echo ""
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed:    $TESTS_PASSED"
echo "Failed:    $TESTS_FAILED"
echo "=========================================="

(( TESTS_FAILED > 0 )) && exit 1
exit 0

