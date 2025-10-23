#!/usr/bin/env zsh
# Comprehensive test runner
# Part of Phase 0: Test Infrastructure

set -euo pipefail

# Get root directory
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Source test helpers
source "$ROOT_DIR/tests/lib/test_helpers.zsh"

# ============================================================================
# Configuration
# ============================================================================

# Test categories
declare -A TEST_CATEGORIES
TEST_CATEGORIES=(
  [unit]="tests/unit"
  [integration]="tests/integration"
  [e2e]="tests/e2e"
  [performance]="tests/performance"
  [regression]="tests/regression"
)

# Counters
typeset -g SUITE_TOTAL=0
typeset -g SUITE_PASSED=0
typeset -g SUITE_FAILED=0
typeset -g SUITE_SKIPPED=0

# Options
VERBOSE=0
FAIL_FAST=0
PARALLEL=0
FILTER=""
CATEGORY="all"

# ============================================================================
# Command Line Parsing
# ============================================================================

print_usage() {
  cat <<'USAGE'
Usage: run_all.zsh [options] [category]

Categories:
  all           Run all tests (default)
  unit          Run unit tests only
  integration   Run integration tests
  e2e           Run end-to-end tests
  performance   Run performance benchmarks
  regression    Run regression tests

Options:
  -v, --verbose      Verbose output
  -f, --fail-fast    Stop on first failure
  -p, --parallel     Run tests in parallel (if available)
  --filter PATTERN   Only run tests matching pattern
  -h, --help         Show this help

Examples:
  ./tests/run_all.zsh                    # Run all tests
  ./tests/run_all.zsh unit               # Run unit tests only
  ./tests/run_all.zsh --filter wtnew     # Run tests matching "wtnew"
  ./tests/run_all.zsh -f integration     # Run integration, stop on failure

USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -f|--fail-fast)
      FAIL_FAST=1
      shift
      ;;
    -p|--parallel)
      PARALLEL=1
      shift
      ;;
    --filter)
      FILTER="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    unit|integration|e2e|performance|regression|all)
      CATEGORY="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 2
      ;;
  esac
done

# ============================================================================
# Test Discovery
# ============================================================================

discover_tests() {
  local category="$1"
  local filter="${2:-}"
  local -a test_files
  
  if [[ "$category" == "all" ]]; then
    # Find all test files
    test_files=(
      tests/unit/**/*.zsh(N)
      tests/integration/**/*.zsh(N)
      tests/e2e/**/*.zsh(N)
      tests/performance/**/*.zsh(N)
      tests/regression/**/*.zsh(N)
      tests/test_*.zsh(N)
      tests/test_*.sh(N)
    )
  else
    # Find tests in specific category
    local cat_dir="${TEST_CATEGORIES[$category]}"
    if [[ -d "$cat_dir" ]]; then
      test_files=( ${cat_dir}/**/*.(zsh|sh)(N) )
    fi
    
    # Also check root tests directory for legacy tests
    test_files+=( tests/test_${category}*.{zsh,sh}(N) )
  fi
  
  # Apply filter if provided
  if [[ -n "$filter" ]]; then
    local filtered=()
    for file in "${test_files[@]}"; do
      if [[ "$file" == *"$filter"* ]]; then
        filtered+=("$file")
      fi
    done
    test_files=("${filtered[@]}")
  fi
  
  # Return unique, sorted list
  printf "%s\n" "${test_files[@]}" | sort -u
}

# ============================================================================
# Test Execution
# ============================================================================

run_test_file() {
  local test_file="$1"
  local test_name="$(basename "$test_file" | sed 's/\.(zsh|sh)$//')"
  
  ((SUITE_TOTAL++))
  
  if (( VERBOSE )); then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $test_name"
    echo "File: $test_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo -n "  $test_name ... "
  fi
  
  # Determine shell to use
  local shell="zsh"
  if [[ "$test_file" == *.sh ]]; then
    shell="bash"
  fi
  
  # Run test with timeout
  local output status=0
  output="$(timeout 60 "$shell" "$test_file" 2>&1)" || status=$?
  
  if (( status == 0 )); then
    if (( VERBOSE )); then
      echo "$output"
      echo -e "${TEST_GREEN}✓ PASSED${TEST_NC}"
    else
      echo -e "${TEST_GREEN}PASS${TEST_NC}"
    fi
    ((SUITE_PASSED++))
    return 0
  elif (( status == 124 )); then
    if (( VERBOSE )); then
      echo -e "${TEST_YELLOW}⏱ TIMEOUT${TEST_NC}"
    else
      echo -e "${TEST_YELLOW}TIMEOUT${TEST_NC}"
    fi
    ((SUITE_FAILED++))
    return 1
  else
    if (( VERBOSE )); then
      echo "$output"
      echo -e "${TEST_RED}✗ FAILED (exit $status)${TEST_NC}"
    else
      echo -e "${TEST_RED}FAIL${TEST_NC}"
      # Show last few lines of output
      echo "$output" | tail -5 | sed 's/^/    /'
    fi
    ((SUITE_FAILED++))
    return 1
  fi
}

run_tests_sequential() {
  local -a test_files
  test_files=("$@")
  
  for test_file in "${test_files[@]}"; do
    run_test_file "$test_file" || {
      if (( FAIL_FAST )); then
        echo ""
        echo -e "${TEST_RED}Stopping due to failure (--fail-fast)${TEST_NC}"
        return 1
      fi
    }
  done
}

run_tests_parallel() {
  local -a test_files
  test_files=("$@")
  
  echo "Running tests in parallel..."
  
  # Create temp directory for results
  local result_dir="$(mktemp -d)"
  trap "rm -rf '$result_dir'" EXIT
  
  # Run tests in parallel using xargs
  local max_jobs="${MAX_JOBS:-4}"
  printf "%s\n" "${test_files[@]}" | xargs -P "$max_jobs" -I {} bash -c "
    source '$ROOT_DIR/tests/lib/test_helpers.zsh'
    result_file='$result_dir/\$(basename {} | sed 's/[^a-zA-Z0-9]/_/g').result'
    if timeout 60 zsh '{}' > '\$result_file' 2>&1; then
      echo 'PASS' > '\$result_file.status'
    else
      echo 'FAIL' > '\$result_file.status'
    fi
  "
  
  # Collect results
  for test_file in "${test_files[@]}"; do
    local test_name="$(basename "$test_file" | sed 's/[^a-zA-Z0-9]/_/g')"
    local status_file="$result_dir/${test_name}.result.status"
    local result_file="$result_dir/${test_name}.result"
    
    ((SUITE_TOTAL++))
    
    if [[ -f "$status_file" ]] && grep -q "PASS" "$status_file"; then
      echo -e "  $(basename "$test_file" | sed 's/\.(zsh|sh)$//') ... ${TEST_GREEN}PASS${TEST_NC}"
      ((SUITE_PASSED++))
    else
      echo -e "  $(basename "$test_file" | sed 's/\.(zsh|sh)$//') ... ${TEST_RED}FAIL${TEST_NC}"
      if [[ -f "$result_file" ]]; then
        tail -3 "$result_file" | sed 's/^/    /'
      fi
      ((SUITE_FAILED++))
    fi
  done
  
  rm -rf "$result_dir"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  echo ""
  echo -e "${TEST_BLUE}╔════════════════════════════════════════════════════════╗${TEST_NC}"
  echo -e "${TEST_BLUE}║          Git Worktrees Test Suite                     ║${TEST_NC}"
  echo -e "${TEST_BLUE}╚════════════════════════════════════════════════════════╝${TEST_NC}"
  echo ""
  
  # Discover tests
  local -a test_files
  test_files=( $(discover_tests "$CATEGORY" "$FILTER") )
  
  if (( ${#test_files[@]} == 0 )); then
    echo "No tests found for category: $CATEGORY"
    if [[ -n "$FILTER" ]]; then
      echo "Filter: $FILTER"
    fi
    exit 1
  fi
  
  echo "Discovered ${#test_files[@]} test(s)"
  if [[ -n "$FILTER" ]]; then
    echo "Filter: $FILTER"
  fi
  echo ""
  
  # Run syntax checks first
  echo -e "${TEST_BLUE}━━━ Syntax Checks ━━━${TEST_NC}"
  for script in scripts/wt scripts/wtnew scripts/wtrm scripts/wtopen scripts/wtls; do
    if [[ -f "$script" ]]; then
      echo -n "  Checking $(basename "$script") ... "
      if zsh -fn "$script" 2>/dev/null; then
        echo -e "${TEST_GREEN}PASS${TEST_NC}"
      else
        echo -e "${TEST_RED}FAIL${TEST_NC}"
        ((SUITE_FAILED++))
      fi
    fi
  done
  echo ""
  
  # Run tests
  if [[ "$CATEGORY" == "all" ]]; then
    # Run by category
    for cat in unit integration e2e performance regression; do
      local -a cat_tests
      cat_tests=( $(discover_tests "$cat" "$FILTER") )
      
      if (( ${#cat_tests[@]} > 0 )); then
        echo -e "${TEST_BLUE}━━━ ${cat^} Tests ━━━${TEST_NC}"
        
        if (( PARALLEL && ${#cat_tests[@]} > 3 )); then
          run_tests_parallel "${cat_tests[@]}"
        else
          run_tests_sequential "${cat_tests[@]}"
        fi
        
        echo ""
      fi
    done
    
    # Run legacy tests from tests/ root
    local -a legacy_tests
    legacy_tests=( tests/test_*.{zsh,sh}(N) )
    if (( ${#legacy_tests[@]} > 0 )); then
      echo -e "${TEST_BLUE}━━━ Legacy Tests ━━━${TEST_NC}"
      run_tests_sequential "${legacy_tests[@]}"
      echo ""
    fi
  else
    # Run single category
    echo -e "${TEST_BLUE}━━━ ${CATEGORY^} Tests ━━━${TEST_NC}"
    
    if (( PARALLEL && ${#test_files[@]} > 3 )); then
      run_tests_parallel "${test_files[@]}"
    else
      run_tests_sequential "${test_files[@]}"
    fi
    
    echo ""
  fi
  
  # Print summary
  echo -e "${TEST_BLUE}╔════════════════════════════════════════════════════════╗${TEST_NC}"
  echo -e "${TEST_BLUE}║                    Test Summary                        ║${TEST_NC}"
  echo -e "${TEST_BLUE}╚════════════════════════════════════════════════════════╝${TEST_NC}"
  echo ""
  echo "  Total:   $SUITE_TOTAL"
  echo -e "  Passed:  ${TEST_GREEN}$SUITE_PASSED${TEST_NC}"
  echo -e "  Failed:  ${TEST_RED}$SUITE_FAILED${TEST_NC}"
  echo -e "  Skipped: ${TEST_YELLOW}$SUITE_SKIPPED${TEST_NC}"
  echo ""
  
  if (( SUITE_FAILED > 0 )); then
    echo -e "${TEST_RED}╔════════════════════════════════════════════════════════╗${TEST_NC}"
    echo -e "${TEST_RED}║                  ✗ TESTS FAILED                        ║${TEST_NC}"
    echo -e "${TEST_RED}╚════════════════════════════════════════════════════════╝${TEST_NC}"
    return 1
  else
    echo -e "${TEST_GREEN}╔════════════════════════════════════════════════════════╗${TEST_NC}"
    echo -e "${TEST_GREEN}║                ✓ ALL TESTS PASSED                      ║${TEST_NC}"
    echo -e "${TEST_GREEN}╚════════════════════════════════════════════════════════╝${TEST_NC}"
    return 0
  fi
}

# Run main
main
exit $?

