#!/usr/bin/env zsh
# wt-recovery.zsh - Error recovery and retry logic
# Part of Phase 1: Core Infrastructure

emulate -L zsh
setopt local_options pipefail
unsetopt xtrace verbose

# ============================================================================
# Retry Mechanism
# ============================================================================

# Generic retry wrapper with exponential backoff
# Usage: wt_retry <max_attempts> <command> [args...]
wt_retry() {
  local max_attempts="$1"; shift
  local attempt=1
  local backoff=1
  
  while (( attempt <= max_attempts )); do
    if "$@" 2>/dev/null; then
      return 0
    fi
    
    if (( attempt < max_attempts )); then
      echo "⚠️  Attempt $attempt failed, retrying in ${backoff}s..." >&2
      sleep "$backoff"
      backoff=$((backoff * 2))
    fi
    
    ((attempt++))
  done
  
  echo "❌ Failed after $max_attempts attempts" >&2
  return 1
}

# Retry with custom prompt for user intervention
# Usage: wt_retry_with_prompt <max_attempts> <prompt_fn> <command> [args...]
wt_retry_with_prompt() {
  local max_attempts="$1"; shift
  local prompt_fn="$1"; shift
  local attempt=1
  
  while (( attempt <= max_attempts )); do
    if "$@" 2>/dev/null; then
      return 0
    fi
    
    if (( attempt < max_attempts )); then
      # Call custom prompt function
      if ! "$prompt_fn" "$attempt" "$max_attempts"; then
        echo "❌ User cancelled retry" >&2
        return 1
      fi
    fi
    
    ((attempt++))
  done
  
  return 1
}

# ============================================================================
# Error Diagnosis
# ============================================================================

# Diagnose error from command output
# Usage: wt_diagnose_error <command> <output> <exit_code>
wt_diagnose_error() {
  local cmd="$1"
  local output="$2"
  local exit_code="$3"
  
  # Network errors
  if [[ "$output" == *"Could not resolve host"* ]] || \
     [[ "$output" == *"Network is unreachable"* ]] || \
     [[ "$output" == *"Connection refused"* ]]; then
    echo "network_failure"
    return 0
  fi
  
  # Permission errors
  if [[ "$output" == *"Permission denied"* ]] || \
     [[ "$output" == *"Operation not permitted"* ]]; then
    echo "permission_denied"
    return 0
  fi
  
  # Disk space errors
  if [[ "$output" == *"No space left"* ]] || \
     [[ "$output" == *"Disk quota exceeded"* ]]; then
    echo "disk_space"
    return 0
  fi
  
  # Already exists errors
  if [[ "$output" == *"already exists"* ]] || \
     [[ "$output" == *"already been added"* ]]; then
    echo "already_exists"
    return 0
  fi
  
  # Already checked out
  if [[ "$output" == *"already checked out"* ]]; then
    echo "already_checked_out"
    return 0
  fi
  
  # Invalid name/ref
  if [[ "$output" == *"not a valid"*"name"* ]] || \
     [[ "$output" == *"invalid"*"branch"* ]] || \
     [[ "$output" == *"invalid"*"reference"* ]]; then
    echo "invalid_name"
    return 0
  fi
  
  # Not found
  if [[ "$output" == *"not found"* ]] || \
     [[ "$output" == *"does not exist"* ]] || \
     [[ "$output" == *"did not match any"* ]] || \
     [[ "$output" == *"no such"* ]]; then
    echo "not_found"
    return 0
  fi
  
  # Dirty working directory
  if [[ "$output" == *"local changes"* ]] || \
     [[ "$output" == *"would be overwritten"* ]]; then
    echo "dirty_worktree"
    return 0
  fi
  
  # Unknown error
  echo "unknown"
  return 0
}

# Get user-friendly error message for error type
# Usage: wt_error_message <error_type>
wt_error_message() {
  local error_type="$1"
  
  case "$error_type" in
    network_failure)
      echo "Network connection failed. Check your internet connection."
      ;;
    permission_denied)
      echo "Permission denied. Check file/directory permissions."
      ;;
    disk_space)
      echo "Insufficient disk space. Free up space and try again."
      ;;
    already_exists)
      echo "Path or resource already exists."
      ;;
    already_checked_out)
      echo "Branch is already checked out in another worktree."
      ;;
    invalid_name)
      echo "Invalid name format. Check naming rules."
      ;;
    not_found)
      echo "Resource not found. Check if it exists."
      ;;
    dirty_worktree)
      echo "Working directory has uncommitted changes."
      ;;
    *)
      echo "An error occurred. Check the output for details."
      ;;
  esac
}

# ============================================================================
# Recovery Options
# ============================================================================

# Offer recovery options based on error type
# Usage: wt_offer_recovery <error_type> <context...>
# Returns: 0 if user wants to retry, 1 if cancelled
wt_offer_recovery() {
  local error_type="$1"; shift
  
  case "$error_type" in
    network_failure)
      echo ""
      echo "💡 Recovery options:"
      echo "   [1] Retry connection"
      echo "   [2] Skip network operations (continue offline)"
      echo "   [3] Cancel"
      printf "   Choice [1-3]: "
      local choice; read -r choice
      case "$choice" in
        1) return 0 ;;
        2) return 2 ;;  # Special: skip network
        *) return 1 ;;
      esac
      ;;
      
    permission_denied)
      local path="${1:-unknown}"
      echo ""
      echo "💡 Recovery options:"
      echo "   [1] Try with sudo"
      echo "   [2] Choose different location"
      echo "   [3] Cancel"
      printf "   Choice [1-3]: "
      local choice; read -r choice
      case "$choice" in
        1) return 3 ;;  # Special: use sudo
        2) return 4 ;;  # Special: change location
        *) return 1 ;;
      esac
      ;;
      
    disk_space)
      echo ""
      echo "💡 Recovery options:"
      echo "   [1] Choose different location"
      echo "   [2] Show disk usage"
      echo "   [3] Cancel"
      printf "   Choice [1-3]: "
      local choice; read -r choice
      case "$choice" in
        1) return 4 ;;  # Special: change location
        2)
          df -h 2>/dev/null || true
          return 0  # Retry after showing info
          ;;
        *) return 1 ;;
      esac
      ;;
      
    already_exists)
      local path="${1:-unknown}"
      echo ""
      echo "💡 Recovery options:"
      echo "   [1] Use different name/path"
      echo "   [2] Remove existing (if safe)"
      echo "   [3] Reuse existing"
      echo "   [4] Cancel"
      printf "   Choice [1-4]: "
      local choice; read -r choice
      case "$choice" in
        1) return 4 ;;  # Special: change name
        2) return 5 ;;  # Special: remove
        3) return 6 ;;  # Special: reuse
        *) return 1 ;;
      esac
      ;;
      
    *)
      echo ""
      printf "Try again? [y/N]: "
      local retry; read -r retry
      [[ "${retry:l}" == "y" ]] && return 0
      return 1
      ;;
  esac
}

# ============================================================================
# Session State Management
# ============================================================================

# Session state directory - computed on demand via function
# Can be overridden with WT_SESSION_DIR env var (useful for testing)
wt_session_dir() {
  # Allow test override
  if [[ -n "${WT_SESSION_DIR:-}" ]]; then
    printf "%s" "$WT_SESSION_DIR"
    return
  fi
  
  local cache_dir
  if typeset -f wt_cache_dir >/dev/null 2>&1; then
    cache_dir="$(wt_cache_dir)"
  else
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/git-worktrees"
  fi
  printf "%s/sessions" "$cache_dir"
}

# Save session state for recovery
# Usage: wt_save_session <tool_name> <key=value> [key=value...]
wt_save_session() {
  local tool="$1"; shift
  local session_file="$(wt_session_dir)/${tool}_last.json"
  
  mkdir -p "$(wt_session_dir)" 2>/dev/null || return 1
  
  local timestamp="$(date +%s)"
  local pwd_escaped="$(pwd | sed 's/"/\\"/g')"
  
  # Build JSON manually (no jq dependency)
  {
    echo "{"
    echo "  \"tool\": \"$tool\","
    echo "  \"timestamp\": $timestamp,"
    echo "  \"pwd\": \"$pwd_escaped\","
    echo "  \"state\": {"
    
    local first=1
    while [[ $# -gt 0 ]]; do
      local key="${1%%=*}"
      local val="${1#*=}"
      # Escape quotes in value
      val="${val//\"/\\\"}"
      
      (( first )) || echo ","
      echo -n "    \"$key\": \"$val\""
      first=0
      shift
    done
    
    echo ""
    echo "  }"
    echo "}"
  } > "$session_file"
}

# Restore session state
# Usage: wt_restore_session <tool_name>
# Outputs: key=value pairs to stdout
wt_restore_session() {
  local tool="$1"
  local session_file="$(wt_session_dir)/${tool}_last.json"
  
  [[ -f "$session_file" ]] || return 1
  
  # More robust JSON parsing without jq
  # Only parse lines within the "state" object, handle escaped quotes and special chars
  awk '
    # Track if we are inside the "state" block
    /"state"[[:space:]]*:[[:space:]]*\{/ { in_state=1; next }
    in_state && /\}/ { in_state=0; next }
    in_state {
      # Match "key": "value" patterns, handle escaped quotes in values
      if (match($0, /"([^"]+)"[[:space:]]*:[[:space:]]*"([^"\\]*(\\.[^"\\]*)*)"/, arr)) {
        key = arr[1]
        val = arr[2]
        # Skip metadata keys
        if (key != "tool" && key != "timestamp" && key != "pwd") {
          # Unescape escaped quotes
          gsub(/\\"/, "\"", val)
          print key "=" val
        }
      }
    }
  ' "$session_file" 2>/dev/null || {
    # Fallback to simple parsing if awk fails (older awk versions)
    grep -o '"[^"]*": "[^"]*"' "$session_file" 2>/dev/null | \
      sed 's/": "/=/; s/"//g' | \
      grep -v "tool=\|timestamp=\|pwd=" || true
  }
}

# Check if session is recent (within 1 hour)
# Usage: wt_session_is_recent <tool_name>
wt_session_is_recent() {
  local tool="$1"
  local session_file="$(wt_session_dir)/${tool}_last.json"
  
  [[ -f "$session_file" ]] || return 1
  
  local now="$(date +%s)"
  local session_time="$(grep '"timestamp":' "$session_file" | grep -o '[0-9]*')"
  local age=$((now - session_time))
  
  (( age < 3600 ))  # 1 hour
}

# Clear session state
# Usage: wt_clear_session <tool_name>
wt_clear_session() {
  local tool="$1"
  local session_file="$(wt_session_dir)/${tool}_last.json"
  
  rm -f "$session_file" 2>/dev/null || true
}

# Offer to resume from saved session
# Usage: wt_offer_resume <tool_name>
# Returns: 0 if should resume, 1 if not
wt_offer_resume() {
  local tool="$1"
  
  wt_session_is_recent "$tool" || return 1
  
  local session_file="$(wt_session_dir)/${tool}_last.json"
  local timestamp="$(grep '"timestamp":' "$session_file" | grep -o '[0-9]*')"
  local time_str="$(date -r "$timestamp" "+%H:%M:%S" 2>/dev/null || echo "recently")"
  
  echo ""
  echo "💾 Found recent ${tool} session from $time_str:"
  
  # Show saved state
  wt_restore_session "$tool" | while IFS='=' read -r key value; do
    echo "   • $key: $value"
  done
  
  echo ""
  printf "Resume from this state? [Y/n]: "
  local resume; read -r resume
  
  [[ "${resume:l}" != "n" ]]
}

# ============================================================================
# Transaction Log (for rollback)
# ============================================================================

# Transaction log path - computed on demand via function
# Get transaction log path
# Can be overridden with WT_TRANSACTION_LOG env var (useful for testing)
wt_transaction_log() {
  # Allow test override
  if [[ -n "${WT_TRANSACTION_LOG:-}" ]]; then
    printf "%s" "$WT_TRANSACTION_LOG"
    return
  fi
  
  local cache_dir
  if typeset -f wt_cache_dir >/dev/null 2>&1; then
    cache_dir="$(wt_cache_dir)"
  else
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/git-worktrees"
  fi
  printf "%s/transaction.log" "$cache_dir"
}
typeset -g WT_TRANSACTION_ACTIVE=0

# Begin transaction
wt_transaction_begin() {
  mkdir -p "$(dirname "$(wt_transaction_log)")" 2>/dev/null
  echo "# Transaction started at $(date)" > "$(wt_transaction_log)"
  WT_TRANSACTION_ACTIVE=1
}

# Record an action in transaction log
# Usage: wt_transaction_record <action_type> <details...>
wt_transaction_record() {
  (( WT_TRANSACTION_ACTIVE )) || return 0
  
  local action="$1"; shift
  local details="$*"
  
  echo "$action|$details" >> "$(wt_transaction_log)"
}

# Commit transaction (clear log)
wt_transaction_commit() {
  rm -f "$(wt_transaction_log)" 2>/dev/null || true
  WT_TRANSACTION_ACTIVE=0
}

# Portable reverse file reader (tac is not available on macOS)
_wt_tac() {
  if command -v tac >/dev/null 2>&1; then
    tac "$@"
  elif command -v tail >/dev/null 2>&1; then
    # macOS: tail -r reverses lines
    tail -r "$@" 2>/dev/null || awk '{a[NR]=$0} END {for(i=NR;i>=1;i--) print a[i]}' "$@"
  else
    # Fallback: pure awk
    awk '{a[NR]=$0} END {for(i=NR;i>=1;i--) print a[i]}' "$@"
  fi
}

# Rollback transaction (undo all recorded actions)
wt_transaction_rollback() {
  (( WT_TRANSACTION_ACTIVE )) || return 0
  
  [[ -f "$(wt_transaction_log)" ]] || return 0
  
  echo "↩️  Rolling back changes..."
  
  # Read log in reverse and undo (use process substitution to avoid subshell)
  local action details
  while IFS='|' read -r action details; do
    [[ "$action" =~ ^# ]] && continue  # Skip comments
    [[ -z "$action" ]] && continue
    
    case "$action" in
      worktree_add)
        echo "   • Removing worktree: $details"
        git worktree remove --force "$details" 2>/dev/null || true
        ;;
      branch_create)
        echo "   • Deleting branch: $details"
        git branch -D "$details" 2>/dev/null || true
        ;;
      file_create)
        echo "   • Removing file: $details"
        rm -rf "$details" 2>/dev/null || true
        ;;
      dir_create)
        echo "   • Removing directory: $details"
        rm -rf "$details" 2>/dev/null || true
        ;;
      config_set)
        local key="${details%% *}"
        local repo="${details#* }"
        echo "   • Unsetting config: $key"
        git -C "$repo" config --unset "$key" 2>/dev/null || true
        ;;
    esac
  done < <(_wt_tac "$(wt_transaction_log)")
  
  wt_transaction_commit
  echo "✅ Rollback complete"
}

# ============================================================================
# Helper Functions
# ============================================================================

# Check if we should enable recovery features
wt_recovery_enabled() {
  [[ -z "${WT_NO_RECOVERY:-}" ]]
}

# Get max retry attempts from config or default
wt_max_retries() {
  echo "${WT_MAX_RECOVERY_ATTEMPTS:-3}"
}

# Export functions for use (silently)
{
  typeset -gf wt_retry wt_retry_with_prompt
  typeset -gf wt_diagnose_error wt_error_message wt_offer_recovery
  typeset -gf wt_save_session wt_restore_session wt_session_is_recent
  typeset -gf wt_clear_session wt_offer_resume
  typeset -gf wt_transaction_begin wt_transaction_record
  typeset -gf wt_transaction_commit wt_transaction_rollback
  typeset -gf wt_recovery_enabled wt_max_retries
} >/dev/null 2>&1

