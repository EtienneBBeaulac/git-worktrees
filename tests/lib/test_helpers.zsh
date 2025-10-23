#!/usr/bin/env zsh
# Enhanced test helpers for comprehensive testing
# Part of Phase 0: Test Infrastructure

set -euo pipefail

# Colors for output
export TEST_RED='\033[0;31m'
export TEST_GREEN='\033[0;32m'
export TEST_YELLOW='\033[1;33m'
export TEST_BLUE='\033[0;34m'
export TEST_NC='\033[0m' # No Color

# Test counters (global)
typeset -g TEST_TOTAL=0
typeset -g TEST_PASSED=0
typeset -g TEST_FAILED=0
typeset -g TEST_SKIPPED=0

# Test context
typeset -g TEST_NAME=""
typeset -g TEST_FILE=""
typeset -g TEST_TMP_DIR=""

# ============================================================================
# Test Lifecycle Management
# ============================================================================

# Initialize test suite
test_suite_init() {
  local suite_name="$1"
  export TEST_SUITE_NAME="$suite_name"
  TEST_TOTAL=0
  TEST_PASSED=0
  TEST_FAILED=0
  TEST_SKIPPED=0
  
  echo -e "${TEST_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${TEST_NC}"
  echo -e "${TEST_BLUE}  Test Suite: $suite_name${TEST_NC}"
  echo -e "${TEST_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${TEST_NC}"
  echo ""
}

# Start a test
test_start() {
  local name="$1"
  TEST_NAME="$name"
  ((TEST_TOTAL++))
  echo -n "  ${name}... "
}

# Mark test as passed
test_pass() {
  local msg="${1:-}"
  ((TEST_PASSED++))
  echo -e "${TEST_GREEN}PASS${TEST_NC}${msg:+ ($msg)}"
}

# Mark test as failed
test_fail() {
  local msg="$1"
  ((TEST_FAILED++))
  echo -e "${TEST_RED}FAIL${TEST_NC}"
  echo -e "    ${TEST_RED}✗ $msg${TEST_NC}"
  
  # Print stack trace if available
  if [[ -n "${BASH_SOURCE:-}" ]]; then
    echo "    Stack trace:"
    local i
    for ((i=1; i<${#BASH_SOURCE[@]}; i++)); do
      echo "      ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]} ${FUNCNAME[$i]}"
    done
  fi
}

# Mark test as skipped
test_skip() {
  local reason="${1:-no reason given}"
  ((TEST_SKIPPED++))
  echo -e "${TEST_YELLOW}SKIP${TEST_NC} ($reason)"
}

# Print test suite summary
test_suite_summary() {
  echo ""
  echo -e "${TEST_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${TEST_NC}"
  echo "  Summary: ${TEST_SUITE_NAME:-Unknown}"
  echo -e "${TEST_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${TEST_NC}"
  echo "  Total:   $TEST_TOTAL"
  echo -e "  Passed:  ${TEST_GREEN}$TEST_PASSED${TEST_NC}"
  echo -e "  Failed:  ${TEST_RED}$TEST_FAILED${TEST_NC}"
  echo -e "  Skipped: ${TEST_YELLOW}$TEST_SKIPPED${TEST_NC}"
  echo ""
  
  if (( TEST_FAILED > 0 )); then
    echo -e "${TEST_RED}━━━━ TEST SUITE FAILED ━━━━${TEST_NC}"
    return 1
  else
    echo -e "${TEST_GREEN}━━━━ ALL TESTS PASSED ━━━━${TEST_NC}"
    return 0
  fi
}

# ============================================================================
# Setup & Teardown
# ============================================================================

# Setup test repository
test_setup_repo() {
  export TEST_TMP="$(mktemp -d)"
  export REPO_DIR="$TEST_TMP/repo"
  
  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR"
  
  # Initialize git repo
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  git config commit.gpgsign false
  
  # Create initial commit
  echo "# Test Repository" > README.md
  git add README.md
  git commit -q -m "Initial commit"
  git branch -M main
}

# Setup test repository with remote
test_setup_repo_with_remote() {
  test_setup_repo
  
  export BARE_DIR="$TEST_TMP/remote.git"
  git init --bare -q "$BARE_DIR"
  
  cd "$REPO_DIR"
  git remote add origin "$BARE_DIR"
  git push -q origin main
}

# Cleanup test repository
test_cleanup() {
  if [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]]; then
    rm -rf "$TEST_TMP"
  fi
  unset TEST_TMP REPO_DIR BARE_DIR
}

# Setup and teardown wrapper
test_with_repo() {
  local test_func="$1"
  test_setup_repo
  "$test_func"
  local status=$?
  test_cleanup
  return $status
}

# ============================================================================
# Assertions
# ============================================================================

# Assert command succeeds
assert_success() {
  local cmd="$@"
  if ! eval "$cmd" >/dev/null 2>&1; then
    test_fail "Command should succeed: $cmd"
    return 1
  fi
  return 0
}

# Assert command fails
assert_failure() {
  local cmd="$@"
  if eval "$cmd" >/dev/null 2>&1; then
    test_fail "Command should fail: $cmd"
    return 1
  fi
  return 0
}

# Assert exit code equals
assert_exit_code() {
  local expected="$1"
  local cmd="${@:2}"
  local actual=0
  eval "$cmd" >/dev/null 2>&1 || actual=$?
  
  if (( actual != expected )); then
    test_fail "Expected exit code $expected, got $actual: $cmd"
    return 1
  fi
  return 0
}

# Assert strings equal
assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-values should be equal}"
  
  if [[ "$actual" != "$expected" ]]; then
    test_fail "$msg"
    echo "      Expected: '$expected'"
    echo "      Actual:   '$actual'"
    return 1
  fi
  return 0
}

# Assert output contains substring
assert_output_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-should contain substring}"
  
  if [[ "$haystack" != *"$needle"* ]]; then
    test_fail "$msg"
    echo "      Haystack: '$haystack'"
    echo "      Needle:   '$needle'"
    return 1
  fi
  test_pass
  return 0
}

# Assert output does not contain substring
assert_output_not_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-should not contain substring}"
  
  if [[ "$haystack" == *"$needle"* ]]; then
    test_fail "$msg"
    echo "      Haystack: '$haystack'"
    echo "      Needle:   '$needle'"
    return 1
  fi
  return 0
}

# Note: assert_contains and assert_not_contains are provided by assert.sh
# for file-based assertions. Use assert_output_contains for string matching.

# Assert output matches pattern
assert_matches() {
  local actual="$1"
  local pattern="$2"
  local msg="${3:-should match pattern}"
  
  if ! [[ "$actual" =~ $pattern ]]; then
    test_fail "$msg"
    echo "      Actual:  '$actual'"
    echo "      Pattern: '$pattern'"
    return 1
  fi
  return 0
}

# Assert file exists
assert_file_exists() {
  local file="$1"
  local msg="${2:-file should exist: $file}"
  
  if [[ ! -f "$file" ]]; then
    test_fail "$msg"
    return 1
  fi
  return 0
}

# Assert file does not exist
assert_file_not_exists() {
  local file="$1"
  local msg="${2:-file should not exist: $file}"
  
  if [[ -f "$file" ]]; then
    test_fail "$msg"
    return 1
  fi
  return 0
}

# Assert directory exists
assert_dir_exists() {
  local dir="$1"
  local msg="${2:-directory should exist: $dir}"
  
  if [[ ! -d "$dir" ]]; then
    test_fail "$msg"
    return 1
  fi
  return 0
}

# Assert directory does not exist
assert_dir_not_exists() {
  local dir="$1"
  local msg="${2:-directory should not exist: $dir}"
  
  if [[ -d "$dir" ]]; then
    test_fail "$msg"
    return 1
  fi
  return 0
}

# Assert file contains text
assert_file_contains() {
  local file="$1"
  local text="$2"
  local msg="${3:-file should contain text}"
  
  if ! grep -Fq "$text" "$file" 2>/dev/null; then
    test_fail "$msg"
    echo "      File: $file"
    echo "      Text: '$text'"
    return 1
  fi
  return 0
}

# Assert worktree exists for branch
assert_worktree_exists() {
  local branch="$1"
  local msg="${2:-worktree should exist for branch: $branch}"
  
  if ! git worktree list --porcelain 2>/dev/null | grep -q "branch refs/heads/$branch"; then
    test_fail "$msg"
    echo "      Branch: $branch"
    echo "      Worktrees:"
    git worktree list 2>/dev/null | sed 's/^/        /'
    return 1
  fi
  return 0
}

# Assert worktree does not exist for branch
assert_worktree_not_exists() {
  local branch="$1"
  local msg="${2:-worktree should not exist for branch: $branch}"
  
  if git worktree list --porcelain 2>/dev/null | grep -q "branch refs/heads/$branch"; then
    test_fail "$msg"
    echo "      Branch: $branch"
    return 1
  fi
  return 0
}

# Assert git branch exists
assert_branch_exists() {
  local branch="$1"
  local msg="${2:-branch should exist: $branch}"
  
  if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    test_fail "$msg"
    echo "      Branch: $branch"
    return 1
  fi
  return 0
}

# Assert git branch does not exist
assert_branch_not_exists() {
  local branch="$1"
  local msg="${2:-branch should not exist: $branch}"
  
  if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    test_fail "$msg"
    echo "      Branch: $branch"
    return 1
  fi
  return 0
}

# ============================================================================
# Mocking & Stubbing
# ============================================================================

# Mock stdin with provided input
mock_stdin() {
  local input="$1"
  echo "$input"
}

# Capture command output
capture_output() {
  local output_var="$1"
  shift
  local output
  output="$("$@" 2>&1)" || true
  eval "$output_var=\"\$output\""
}

# Capture command output and exit code
capture_output_and_code() {
  local output_var="$1"
  local code_var="$2"
  shift 2
  local output code=0
  output="$("$@" 2>&1)" || code=$?
  eval "$output_var=\"\$output\""
  eval "$code_var=$code"
}

# Mock git command
mock_git() {
  local mock_script="$1"
  export GIT_MOCK_DIR="$TEST_TMP/git_mock"
  mkdir -p "$GIT_MOCK_DIR"
  
  cat > "$GIT_MOCK_DIR/git" <<EOF
#!/usr/bin/env bash
$mock_script
EOF
  chmod +x "$GIT_MOCK_DIR/git"
  export PATH="$GIT_MOCK_DIR:$PATH"
}

# Restore real git
unmock_git() {
  if [[ -n "${GIT_MOCK_DIR:-}" ]]; then
    export PATH="${PATH#$GIT_MOCK_DIR:}"
    rm -rf "$GIT_MOCK_DIR"
    unset GIT_MOCK_DIR
  fi
}

# ============================================================================
# Test Utilities
# ============================================================================

# Skip test if condition not met
skip_unless() {
  local condition="$1"
  local reason="${2:-condition not met}"
  
  if ! eval "$condition" >/dev/null 2>&1; then
    test_skip "$reason"
    return 1
  fi
  return 0
}

# Run test with timeout
run_with_timeout() {
  local timeout_sec="$1"
  shift
  local cmd="$@"
  
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_sec" bash -c "$cmd"
  else
    # Fallback for systems without timeout
    eval "$cmd"
  fi
}

# Wait for condition to be true
wait_for() {
  local condition="$1"
  local timeout="${2:-10}"
  local interval="${3:-0.5}"
  
  local elapsed=0
  while ! eval "$condition" >/dev/null 2>&1; do
    sleep "$interval"
    elapsed=$(echo "$elapsed + $interval" | bc 2>/dev/null || echo "999")
    if (( $(echo "$elapsed >= $timeout" | bc 2>/dev/null || echo "1") )); then
      return 1
    fi
  done
  return 0
}

# Generate random string
random_string() {
  local length="${1:-8}"
  LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Create temporary directory
make_temp_dir() {
  mktemp -d "${TEST_TMP:-/tmp}/test.XXXXXX"
}

# Print debug info if TEST_DEBUG is set
debug() {
  if [[ -n "${TEST_DEBUG:-}" ]]; then
    echo -e "${TEST_YELLOW}[DEBUG]${TEST_NC} $*" >&2
  fi
}

# ============================================================================
# Git Test Helpers
# ============================================================================

# Create a commit in current repo
make_commit() {
  local msg="${1:-test commit}"
  local file="${2:-test-$(random_string 4).txt}"
  
  echo "test content $(date +%s)" > "$file"
  git add "$file"
  git commit -q -m "$msg"
}

# Create a branch
make_branch() {
  local branch="$1"
  local base="${2:-HEAD}"
  
  git branch "$branch" "$base"
}

# Create and checkout branch
checkout_branch() {
  local branch="$1"
  
  git checkout -q -b "$branch"
}

# Create a remote branch
make_remote_branch() {
  local remote="$1"
  local branch="$2"
  local base="${3:-HEAD}"
  
  git push -q "$remote" "$base:refs/heads/$branch"
}

# Add a worktree
add_test_worktree() {
  local dir="$1"
  local branch="$2"
  local base="${3:-HEAD}"
  
  git worktree add -b "$branch" "$dir" "$base" >/dev/null 2>&1
}

# Remove a worktree
remove_test_worktree() {
  local dir="$1"
  
  git worktree remove "$dir" >/dev/null 2>&1 || true
}

# ============================================================================
# Performance Testing
# ============================================================================

# Benchmark a command
benchmark() {
  local name="$1"
  shift
  local cmd="$@"
  
  local start=$(date +%s.%N 2>/dev/null || date +%s)
  eval "$cmd" >/dev/null 2>&1
  local end=$(date +%s.%N 2>/dev/null || date +%s)
  
  local duration
  if command -v bc >/dev/null 2>&1; then
    duration=$(echo "$end - $start" | bc)
  else
    duration="?"
  fi
  
  echo "  Benchmark: $name = ${duration}s"
}

# Assert performance under threshold
assert_performance() {
  local threshold="$1"
  shift
  local cmd="$@"
  
  local start=$(date +%s.%N 2>/dev/null || date +%s)
  eval "$cmd" >/dev/null 2>&1
  local end=$(date +%s.%N 2>/dev/null || date +%s)
  
  if command -v bc >/dev/null 2>&1; then
    local duration=$(echo "$end - $start" | bc)
    if (( $(echo "$duration > $threshold" | bc) )); then
      test_fail "Performance threshold exceeded: ${duration}s > ${threshold}s"
      return 1
    fi
  fi
  
  return 0
}

# ============================================================================
# Compatibility
# ============================================================================

# Source bash-style assertions for compatibility
if [[ -f "$(dirname "$0")/assert.sh" ]]; then
  source "$(dirname "$0")/assert.sh" 2>/dev/null || true
fi

# Export functions for use in tests
# Don't export functions - causes issues with function printing
# Functions are available when sourced

