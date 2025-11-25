#!/usr/bin/env zsh
# wt-common: shared helpers for git-worktrees tools (zsh)
#
# GLOBAL STATE DOCUMENTATION:
# This module uses the following global variables:
#   - __WT_COMMON_SOURCED: Guard to prevent double-sourcing
#   - __WT_LIB_DIR: Directory containing library files
#   - WT_VERSION: Current version string
#   - WT_CONFIG: Associative array of configuration values
#   - WT_DEBUG_LEVEL_CACHE: Cached debug level for performance
#
# Environment Variables (user-configurable):
#   - WT_DEBUG: Enable debug output (0/1)
#   - WT_EDITOR: Override default editor
#   - WT_FZF_HEIGHT: FZF height (default: 40%)
#   - WT_FZF_OPTS: Additional FZF options
#   - WT_FAST: Enable fast mode for status display

emulate -L zsh
unsetopt xtrace verbose
typeset -g __WT_COMMON_SOURCED=1

# Version (automatically updated by GitHub Actions on release)
typeset -g WT_VERSION="1.1.2"

# ============================================================================
# Centralized Path Functions (Pure - No Mutable Global State)
# ============================================================================
# These are pure functions that compute paths on demand, respecting
# environment variables at call time (not source time).

# Get config directory path (pure function)
wt_config_dir() {
  printf "%s" "${XDG_CONFIG_HOME:-$HOME/.config}/git-worktrees"
}

# Get config file path (pure function)
wt_config_file() {
  printf "%s/config" "$(wt_config_dir)"
}

# Get cache directory path (pure function)
wt_cache_dir() {
  printf "%s" "${XDG_CACHE_HOME:-$HOME/.cache}/git-worktrees"
}

# ============================================================================
# Global State Accessors (Prefer these over direct global access)
# ============================================================================

# Get the current version
# Usage: wt_get_version
wt_get_version() {
  printf "%s" "${WT_VERSION:-unknown}"
}

# Get the library directory
# Usage: wt_get_lib_dir
wt_get_lib_dir() {
  printf "%s" "${__WT_LIB_DIR:-}"
}

# Get FZF height setting
# Usage: wt_get_fzf_height
wt_get_fzf_height() {
  printf "%s" "${WT_FZF_HEIGHT:-40%}"
}

# Get additional FZF options
# Usage: wt_get_fzf_opts
wt_get_fzf_opts() {
  printf "%s" "${WT_FZF_OPTS:-}"
}

# ============================================================================
# Stub Functions for Optional Modules (Issue #4 fix)
# ============================================================================
# These provide no-op defaults so callers don't need `typeset -f` checks.
# The actual module implementations override these when loaded.

# Recovery module stubs
wt_recovery_enabled() { return 1; }
wt_diagnose_error() { echo "unknown"; }
wt_error_message() { echo "An error occurred."; }
wt_offer_recovery() { return 1; }
wt_transaction_begin() { :; }
wt_transaction_record() { :; }
wt_transaction_commit() { :; }
wt_transaction_rollback() { :; }

# Discovery module stubs
wt_show_hints() { :; }
wt_show_contextual_help() { :; }

# Error message stubs (actual implementations below, but define stubs for consistency)
wt_error_not_git_repo() { echo "❌ Not a git repository" >&2; }
wt_error_fzf_missing() { echo "⚠️  fzf not found" >&2; }

# Validation module stubs
wt_fuzzy_match_branch() { return 1; }
wt_sanitize_branch_name() { printf "%s" "$1"; }

# ============================================================================
# Load enhanced modules (Phase 1: Core Infrastructure)
# ============================================================================
__WT_LIB_DIR="${${(%):-%x}:A:h}"

# Load recovery module (error recovery, retry, transaction log)
# Note: Module will override stubs defined above
[[ -f "$__WT_LIB_DIR/wt-recovery.zsh" ]] && source "$__WT_LIB_DIR/wt-recovery.zsh"

# Load validation module (input validation, sanitization, fuzzy matching)
[[ -f "$__WT_LIB_DIR/wt-validation.zsh" ]] && source "$__WT_LIB_DIR/wt-validation.zsh"

# Load discovery module (help system, hints, cheatsheet)
[[ -f "$__WT_LIB_DIR/wt-discovery.zsh" ]] && source "$__WT_LIB_DIR/wt-discovery.zsh"

# ============================================================================
# Structured Worktree Data Type
# ============================================================================
# Worktrees are represented as tab-delimited strings with the following fields:
#   branch\tpath\tis_bare\tis_detached\tcommit_sha
#
# Access field helpers:

# Parse a worktree line into components
# Usage: wt_worktree_parse <line> <var_prefix>
# Sets: ${var_prefix}_branch, ${var_prefix}_path, ${var_prefix}_bare,
#       ${var_prefix}_detached, ${var_prefix}_sha
wt_worktree_parse() {
  emulate -L zsh
  setopt local_options pipefail
  local line="$1" prefix="${2:-WT}"
  local -a parts
  # Use IFS-based splitting for reliable tab parsing
  IFS=$'\t' read -rA parts <<< "$line"
  
  eval "${prefix}_branch=\"\${parts[1]:-}\""
  eval "${prefix}_path=\"\${parts[2]:-}\""
  eval "${prefix}_bare=\"\${parts[3]:-0}\""
  eval "${prefix}_detached=\"\${parts[4]:-0}\""
  eval "${prefix}_sha=\"\${parts[5]:-}\""
}

# Get a specific field from a worktree line
# Usage: wt_worktree_get <line> <field>
# Fields: branch, path, bare, detached, sha
wt_worktree_get() {
  emulate -L zsh
  local line="$1" field="$2"
  local -a parts
  # Use IFS-based splitting for reliable tab parsing
  IFS=$'\t' read -rA parts <<< "$line"
  
  case "$field" in
    branch)   printf "%s" "${parts[1]:-}";;
    path)     printf "%s" "${parts[2]:-}";;
    bare)     printf "%s" "${parts[3]:-0}";;
    detached) printf "%s" "${parts[4]:-0}";;
    sha)      printf "%s" "${parts[5]:-}";;
    *)        return 1;;
  esac
}

# Create a worktree line from components
# Usage: wt_worktree_create <branch> <path> [bare] [detached] [sha]
wt_worktree_create() {
  emulate -L zsh
  local branch="$1" path="$2" bare="${3:-0}" detached="${4:-0}" sha="${5:-}"
  printf "%s\t%s\t%s\t%s\t%s" "$branch" "$path" "$bare" "$detached" "$sha"
}

# Check if worktree is detached
# Usage: wt_worktree_is_detached <line>
wt_worktree_is_detached() {
  emulate -L zsh
  [[ "$(wt_worktree_get "$1" detached)" == "1" ]]
}

# Check if worktree is bare repository
# Usage: wt_worktree_is_bare <line>
wt_worktree_is_bare() {
  emulate -L zsh
  [[ "$(wt_worktree_get "$1" bare)" == "1" ]]
}

# ============================================================================
# Git Operation Wrappers (Consistent Abstraction Layer)
# ============================================================================

# Check if currently inside a git worktree/repository
# Usage: wt_git_is_repo [directory]
wt_git_is_repo() {
  emulate -L zsh
  local dir="${1:-.}"
  git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

# Get the git root directory
# Usage: wt_git_root [directory]
wt_git_root() {
  emulate -L zsh
  local dir="${1:-.}"
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null
}

# Get porcelain worktree list output
# Usage: wt_git_worktree_list_porcelain [directory]
wt_git_worktree_list_porcelain() {
  emulate -L zsh
  local dir="${1:-.}"
  git -C "$dir" worktree list --porcelain 2>/dev/null
}

# Check if a branch exists (local)
# Usage: wt_git_branch_exists <branch_name> [directory]
wt_git_branch_exists() {
  emulate -L zsh
  local branch="$1" dir="${2:-.}"
  git -C "$dir" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Check if a remote branch exists
# Usage: wt_git_remote_branch_exists <remote> <branch_name> [directory]
wt_git_remote_branch_exists() {
  emulate -L zsh
  local remote="$1" branch="$2" dir="${3:-.}"
  git -C "$dir" show-ref --verify --quiet "refs/remotes/$remote/$branch" 2>/dev/null
}

# Fetch from remote (with error handling)
# Usage: wt_git_fetch [remote] [directory]
wt_git_fetch() {
  emulate -L zsh
  local remote="${1:-origin}" dir="${2:-.}"
  git -C "$dir" fetch "$remote" --prune 2>/dev/null
}

# Add a worktree
# Usage: wt_git_worktree_add <path> <branch> [base_ref]
# Returns: 0 on success, 1 on failure
wt_git_worktree_add() {
  emulate -L zsh
  local path="$1" branch="$2" base_ref="${3:-}"
  if [[ -n "$base_ref" ]]; then
    git worktree add -b "$branch" "$path" "$base_ref" 2>&1
  else
    git worktree add "$path" "$branch" 2>&1
  fi
}

# Remove a worktree
# Usage: wt_git_worktree_remove <path> [--force]
wt_git_worktree_remove() {
  emulate -L zsh
  local path="$1"
  shift
  git worktree remove "$path" "$@" 2>&1
}

# Prune stale worktrees
# Usage: wt_git_worktree_prune [-v]
wt_git_worktree_prune() {
  emulate -L zsh
  git worktree prune "$@" 2>&1
}

# Get current branch name
# Usage: wt_git_current_branch [directory]
wt_git_current_branch() {
  emulate -L zsh
  local dir="${1:-.}"
  git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Check if branch is fully merged into base
# Usage: wt_git_is_merged <branch> <base> [directory]
wt_git_is_merged() {
  emulate -L zsh
  local branch="$1" base="$2" dir="${3:-.}"
  local merge_base branch_sha
  merge_base="$(git -C "$dir" merge-base "$branch" "$base" 2>/dev/null)" || return 1
  branch_sha="$(git -C "$dir" rev-parse "$branch" 2>/dev/null)" || return 1
  [[ "$merge_base" == "$branch_sha" ]]
}

# Find the default/base branch (pure function - no global state)
# Usage: wt_find_default_branch [directory] [candidate1 candidate2 ...]
# If no candidates provided, uses sensible defaults
# Returns: branch name on stdout, empty if none found
wt_find_default_branch() {
  emulate -L zsh
  local dir="${1:-.}"
  shift 2>/dev/null || true
  
  # Use provided candidates or defaults (no global state)
  local -a candidates
  if (( $# > 0 )); then
    candidates=("$@")
  else
    # Sensible defaults - computed inline, not stored globally
    candidates=(
      origin/main origin/master origin/develop
      main master develop
    )
  fi
  
  local ref
  for ref in "${candidates[@]}"; do
    if git -C "$dir" rev-parse --verify -q "$ref" >/dev/null 2>&1; then
      printf "%s" "$ref"
      return 0
    fi
  done
  return 1
}

# Check if worktree has uncommitted changes (Issue #8 fix)
# Usage: wt_is_worktree_dirty <directory>
# Returns: 0 if dirty (has changes), 1 if clean
wt_is_worktree_dirty() {
  emulate -L zsh
  local dir="$1"
  local status
  status="$(git -C "$dir" status --porcelain --untracked-files=all 2>/dev/null)"
  [[ -n "$status" ]]
}

# Get worktree status (porcelain output)
# Usage: wt_get_worktree_status <directory>
# Returns: porcelain status output
wt_get_worktree_status() {
  emulate -L zsh
  local dir="$1"
  git -C "$dir" status --porcelain --untracked-files=all 2>/dev/null
}

# ============================================================================
# UI Layer (Presentation - Separate from Business Logic)
# ============================================================================
# These functions handle user interaction and presentation.
# Business logic should NOT call these directly - use callbacks or return values.

# Display a confirmation prompt
# Usage: wt_ui_confirm "message" [default]
# Returns: 0 if yes, 1 if no
wt_ui_confirm() {
  emulate -L zsh
  local msg="$1" default="${2:-n}"
  local prompt reply
  
  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi
  
  printf "%s %s " "$msg" "$prompt"
  read -r reply
  
  if [[ -z "$reply" ]]; then
    reply="$default"
  fi
  
  [[ "${reply:l}" == "y" || "${reply:l}" == "yes" ]]
}

# Display a selection menu (fallback when FZF not available)
# Usage: wt_ui_select_menu <prompt> <options...>
# Returns: Selected option on stdout
wt_ui_select_menu() {
  emulate -L zsh
  local prompt="$1"
  shift
  local -a options=("$@")
  local i choice
  
  echo "$prompt"
  for (( i=1; i <= ${#options[@]}; i++ )); do
    echo "  $i) ${options[$i]}"
  done
  
  printf "Choice [1-%d]: " "${#options[@]}"
  read -r choice
  
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    printf "%s" "${options[$choice]}"
  else
    return 1
  fi
}

# Format a worktree for display
# Usage: wt_ui_format_worktree <branch> <path> [status]
wt_ui_format_worktree() {
  emulate -L zsh
  local branch="$1" path="$2" status="${3:-}"
  
  if [[ -n "$status" ]]; then
    printf "%-30s %s %s" "$branch" "$path" "$status"
  else
    printf "%-30s %s" "$branch" "$path"
  fi
}

# Show progress spinner (for long operations)
# Usage: wt_ui_spinner <pid> <message>
wt_ui_spinner() {
  emulate -L zsh
  local pid="$1" msg="$2"
  local -a chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r%s %s" "${chars[$((i % ${#chars[@]} + 1))]}" "$msg"
    sleep 0.1
    ((i++))
  done
  printf "\r\033[K"  # Clear line
}

# ============================================================================
# Standardized Output Helpers
# ============================================================================

# Print an error message and optionally return a code
# Usage: wt_msg_error "message" [exit_code]
# Note: This is for user-facing messages; wt_error() is for debug logging
wt_msg_error() {
  emulate -L zsh
  local msg="$1"
  local code="${2:-1}"
  echo "❌ $msg" >&2
  return "$code"
}

# Print a warning message
# Usage: wt_msg_warn "message"
wt_msg_warn() {
  emulate -L zsh
  echo "⚠️  $1" >&2
}

# Print a success message
# Usage: wt_msg_success "message"
wt_msg_success() {
  emulate -L zsh
  echo "✅ $1"
}

# Print an info message
# Usage: wt_msg_info "message"
wt_msg_info() {
  emulate -L zsh
  echo "ℹ️  $1"
}

# Print a status/progress message
# Usage: wt_msg_status "message"
wt_msg_status() {
  emulate -L zsh
  echo "🚀 $1"
}

# ============================================================================
# Extracted/Composable Helper Functions
# ============================================================================

# Check if FZF is available
# Usage: wt_has_fzf
wt_has_fzf() {
  emulate -L zsh
  command -v fzf >/dev/null 2>&1
}

# Select a branch using FZF
# Usage: wt_select_branch_fzf [prompt] [allow_remote]
# Returns: Selected branch name on stdout, empty if cancelled
wt_select_branch_fzf() {
  emulate -L zsh
  setopt local_options pipefail
  local prompt="${1:-Branch: }" allow_remote="${2:-0}"
  
  wt_has_fzf || return 1
  
  local branches
  if (( allow_remote )); then
    branches="$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null)"
  else
    branches="$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads 2>/dev/null)"
  fi
  
  [[ -z "$branches" ]] && return 1
  
  printf "%s\n" "$branches" | fzf --prompt="$prompt" --height=40% --reverse
}

# Select from worktree list using FZF
# Usage: wt_select_worktree_fzf [prompt] [include_detached]
# Returns: Selected line (branch\tpath) on stdout
wt_select_worktree_fzf() {
  emulate -L zsh
  setopt local_options pipefail
  local prompt="${1:-Worktree: }" include_detached="${2:-0}"
  
  wt_has_fzf || return 1
  
  local porcelain selectable
  porcelain="$(wt_git_worktree_list_porcelain)"
  selectable="$(wt_parse_worktrees_porcelain "$include_detached" "$porcelain")"
  
  [[ -z "$selectable" ]] && return 1
  
  printf "%s\n" "$selectable" | fzf --prompt="$prompt" --height=40% --reverse --with-nth=1 --delimiter=$'\t'
}

# Get the path for a worktree hosting a specific branch
# Usage: wt_get_worktree_path_for_branch <branch>
# Returns: Path on stdout, empty if not found
wt_get_worktree_path_for_branch() {
  emulate -L zsh
  setopt local_options pipefail
  local branch="$1"
  
  local porcelain rows
  porcelain="$(wt_git_worktree_list_porcelain)"
  rows="$(wt_parse_worktrees_porcelain 0 "$porcelain")"
  
  printf "%s\n" "$rows" | awk -F"\t" -v b="$branch" '$1==b{print $2; exit}'
}

# Parse common flag patterns (used by multiple commands)
# Sets variables: open_ide, open_app, do_help
# Usage: wt_parse_common_flags "$@" && shift $PARSED_COUNT
wt_parse_common_flags() {
  emulate -L zsh
  setopt local_options pipefail
  typeset -g PARSED_COUNT=0
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-open) open_ide=0; ((PARSED_COUNT++)); shift;;
      --app) open_app="$2"; ((PARSED_COUNT+=2)); shift 2;;
      --app=*) open_app="${1#--app=}"; ((PARSED_COUNT++)); shift;;
      -h|--help) do_help=1; ((PARSED_COUNT++)); shift; return 0;;
      *) return 0;;  # Unknown flag, stop parsing
    esac
  done
}

# ============================================================================
# Original wt-common functionality
# ============================================================================

# Check if a wt command is available (as function or in PATH)
# Usage: wt_has_cmd <cmd_name>
# Returns: 0 if available, 1 if not
wt_has_cmd() {
  emulate -L zsh
  local cmd="$1"
  typeset -f "$cmd" >/dev/null 2>&1 || command -v "$cmd" >/dev/null 2>&1
}

# Run a wt command or show error if unavailable
# Usage: wt_run <cmd_name> [args...]
# Example: wt_run wtnew --name foo
wt_run() {
  emulate -L zsh
  local cmd="$1"
  shift
  if wt_has_cmd "$cmd"; then
    "$cmd" "$@"
  else
    echo "❌ $cmd not available" >&2
    return 1
  fi
}

# Shorten a ref to a branch short name when possible
wt_short_ref() {
  emulate -L zsh
  setopt local_options pipefail
  local sel="$1"
  if [[ "$sel" =~ ^refs/heads/(.+)$ ]]; then
    printf "%s" "${match[1]}"; return 0
  elif [[ "$sel" =~ ^refs/remotes/([^/]+)/(.+)$ ]]; then
    printf "%s" "${match[2]}"; return 0
  elif [[ "$sel" =~ ^remotes/([^/]+)/(.+)$ ]]; then
    printf "%s" "${match[2]}"; return 0
  fi
  printf "%s" "$sel"
}

# Parse `git worktree list --porcelain` blocks into tab-separated rows.
# Usage:
#   wt_parse_worktrees_porcelain include_detached "${porcelain_text}"
# Returns lines like:
#   branch\t/path/to/worktree
#   (detached)\t/path/to/worktree   # only if include_detached=1
wt_parse_worktrees_porcelain() {
  emulate -L zsh
  setopt local_options pipefail
  local include_detached="$1"
  local porcelain_text="${2:-}"
  if [[ -z "$porcelain_text" ]]; then
    porcelain_text="$(cat)"
  fi
  # shellcheck disable=SC2016
  awk -v inc_det="${include_detached}" '
    BEGIN{d="";b="";det=0}
    function flush(){
      if(d!=""){
        if(b!="" && det==0){ gsub(/^refs\/heads\//,"",b); print b "\t" d }
        else if(det==1 && inc_det==1){ print "(detached)\t" d }
        d=""; b=""; det=0
      }
    }
    /^worktree /{flush(); d=$2; next}
    /^branch /  {b=$2; next}
    /^detached/ {det=1; next}
    /^$/        {flush()}
    END         {flush()}
  ' <<< "$porcelain_text"
}

# Parse porcelain into pipe-delimited rows: path|branchShortOr(detached)|headSha
# Detached entries have branch "(detached)" and include head sha.
wt_parse_worktrees_table() {
  emulate -L zsh
  setopt local_options pipefail
  local porcelain_text="${1:-}"
  [[ -z "$porcelain_text" ]] && porcelain_text="$(cat)"
  awk '
    BEGIN { path=""; head=""; br="" }
    function flush() {
      if (path != "") {
        b = br
        if (b == "") b = "(detached)"
        sub(/^refs\/heads\//, "", b)
        printf "%s|%s|%s\n", path, b, head
      }
    }
    /^worktree / { flush(); path=$2; head=""; br=""; next }
    /^HEAD /     { head=$2; next }
    /^branch /   { br=$0; sub(/^branch /, "", br); next }
    END { flush() }
  ' <<< "$porcelain_text"
}

# ============================================================================
# Editor/IDE Opening (Single Source of Truth)
# ============================================================================

# Check if app is a JetBrains IDE
# Usage: _wt_is_jetbrains_ide <app_name>
_wt_is_jetbrains_ide() {
  local app="$1"
  case "$app" in
    "Android Studio"|"IntelliJ IDEA"|"IntelliJ IDEA CE"|"PyCharm"|"WebStorm"|"PhpStorm"|"RubyMine"|"GoLand"|"CLion"|"Rider"|"DataGrip"|"Fleet")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Open a directory in the specified editor/IDE
# Usage: wt_open_in_editor <directory> [app_name]
# This is the ONLY function that should handle editor opening logic.
wt_open_in_editor() {
  emulate -L zsh
  setopt local_options pipefail
  local dir="$1"
  local app_name="${2:-}"
  
  # If no app specified, try to detect
  [[ -z "$app_name" ]] && app_name="$(wt_get_editor 2>/dev/null)" || true
  
  # If still no app (user chose "none"), just return
  [[ -z "$app_name" || "$app_name" == "none" ]] && return 0
  
  # Test/override: prefer xdg-open when requested (for testing)
  if [[ -n ${WT_PREFER_XDG_OPEN:-} ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$dir" >/dev/null 2>&1
    return 0
  fi
  
  # Android Studio: use 'studio' CLI if available
  if [[ "$app_name" == "Android Studio" ]] && command -v studio >/dev/null 2>&1; then
    studio "$dir" >/dev/null 2>&1 || true
    return 0
  fi
  
  # Determine what to open (project file detection)
  # Only use .idea/project files for JetBrains IDEs; other editors should open the directory
  local target="$dir"
  if _wt_is_jetbrains_ide "$app_name"; then
    # JetBrains IDEs work best when opening .idea or gradle files
    if [[ -d "$dir/.idea" ]]; then
      target="$dir/.idea"
    elif [[ -f "$dir/settings.gradle.kts" ]]; then
      target="$dir/settings.gradle.kts"
    elif [[ -f "$dir/settings.gradle" ]]; then
      target="$dir/settings.gradle"
    elif [[ -f "$dir/build.gradle.kts" ]]; then
      target="$dir/build.gradle.kts"
    elif [[ -f "$dir/build.gradle" ]]; then
      target="$dir/build.gradle"
    fi
  fi
  # For non-JetBrains editors (VS Code, Cursor, Sublime, vim, etc.), just open the directory
  
  # Open with appropriate command
  if command -v open >/dev/null 2>&1; then
    # macOS
    open -a "$app_name" "$target" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    # Linux
    xdg-open "$target" >/dev/null 2>&1 || true
  fi
}

# Legacy alias for backward compatibility
wt_open_in_android_studio() {
  wt_open_in_editor "$@"
}

# Convenience wrapper: opens worktree in editor or shows path if no editor configured
# Usage: wt_open_or_show [-v] <directory> [app_name]
# Options:
#   -v  Verbose mode: print "Opening in..." message
wt_open_or_show() {
  emulate -L zsh
  setopt local_options pipefail
  local verbose=0
  
  if [[ "$1" == "-v" ]]; then
    verbose=1
    shift
  fi
  
  local dir="$1"
  local app="${2:-}"
  
  [[ -z "$app" ]] && app="$(wt_get_editor 2>/dev/null)" || true
  
  if [[ -n "$app" && "$app" != "none" ]]; then
    (( verbose )) && echo "🚀  Opening in ${app}…"
    wt_open_in_editor "$dir" "$app"
  else
    echo "ℹ️  Worktree is at: $dir"
  fi
}

# zsh completions helpers and widgets
# Provide basic completion for branches and flags.
__wt_list_branches_for_completion() {
  emulate -L zsh
  setopt local_options pipefail
  git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | sed -E 's#^refs/heads/##'
}

_wtnew() {
  local -a opts
  opts=(
    '--name=-'
    '--base=-'
    '--dir=-'
    '--remote=-'
    '--no-open'
    '--app=-'
    '--push'
    '--inside-ok'
    '--help'
  )
  _arguments \
    '1: :->first' \
    '*:: :->rest'
  case $state in
    first)
      _describe -t options 'wtnew options' opts
      _values 'branches' $(__wt_list_branches_for_completion)
      ;;
  esac
}
# Register completion only in interactive shells where compdef is available
if [[ -o interactive ]] && whence -w compdef >/dev/null 2>&1; then
  compdef _wtnew wtnew
fi

_wtopen() {
  local -a opts
  opts=(
    '--start=-'
    '--detached'
    '--enter-default=-'
    '--list'
    '--fzf'
    '--no-open'
    '--app=-'
    '--prune-stale'
    '--dry-run'
    '--exact'
    '--cwd'
    '--help'
  )
  _arguments \
    '1:branch:->branch' \
    '*:: :->rest'
  case $state in
    branch)
      _values 'branches' $(__wt_list_branches_for_completion)
      ;;
  esac
}
if [[ -o interactive ]] && whence -w compdef >/dev/null 2>&1; then
  compdef _wtopen wtopen
fi

_wtrm() {
  local -a opts
  opts=(
    '--dir=-'
    '--branch=-'
    '--delete-branch'
    '--base=-'
    '--force'
    '--no-fzf'
    '--prune-only'
    '--rm-detached'
    '--yes'
    '--help'
  )
  _arguments \
    '1: :->first' \
    '*:: :->rest'
  case $state in
    first)
      _describe -t options 'wtrm options' opts
      _values 'branches' $(__wt_list_branches_for_completion)
      ;;
  esac
}
if [[ -o interactive ]] && whence -w compdef >/dev/null 2>&1; then
  compdef _wtrm wtrm
fi


# ----------------------
# Centralized config load
# ----------------------
# Simple KEY=VALUE config loader with safe parsing; no eval, ignores comments.
# Location precedence for file path: WT_CONFIG_PATH > $XDG_CONFIG_HOME/git-worktrees/config > $HOME/.config/git-worktrees/config
# Access precedence per script should be: CLI flags > env vars > config > defaults.
# This module only provides config-level defaults; scripts must handle flags/env.

typeset -gA WT_CONFIG

wt_find_config_file() {
  emulate -L zsh
  setopt local_options pipefail
  # Use global constant, allow override via WT_CONFIG_PATH
  if [[ -n ${WT_CONFIG_PATH:-} ]]; then
    printf "%s" "$WT_CONFIG_PATH"
  else
    printf "%s" "$(wt_config_file)"
  fi
}

wt_load_config() {
  emulate -L zsh
  setopt local_options pipefail
  typeset -gA WT_CONFIG
  WT_CONFIG=()
  local file; file="$(wt_find_config_file)"
  [[ -f "$file" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    # Accept KEY=VALUE, where VALUE may contain spaces; trim trailing CR
    line="${line%$'\r'}"
    key="${line%%=*}"
    val="${line#*=}"
    [[ -z "$key" ]] && continue
    # Trim leading and trailing whitespace from key (zsh extended glob)
    key="${key#"${key%%[^[:space:]]*}"}"   # Remove leading whitespace
    key="${key%"${key##*[^[:space:]]}"}"   # Remove trailing whitespace
    WT_CONFIG[$key]="$val"
  done < "$file"
}

wt_get_config() {
  emulate -L zsh
  setopt local_options pipefail
  local key="$1" default_value="${2:-}"
  if [[ -n ${WT_CONFIG[$key]:-} ]]; then
    printf "%s" "${WT_CONFIG[$key]}"
  else
    printf "%s" "$default_value"
  fi
}

# Set a config value in config file
# Usage: wt_set_config KEY VALUE
wt_set_config() {
  emulate -L zsh
  setopt local_options pipefail
  local key="$1" value="$2"
  local cfg_dir="$(wt_config_dir)"
  local cfg_file="$(wt_config_file)"
  
  mkdir -p "$cfg_dir" 2>/dev/null || true
  
  # Update in-memory config
  WT_CONFIG[$key]="$value"
  
  # Update or append to file
  if [[ -f "$cfg_file" ]] && grep -q "^${key}=" "$cfg_file" 2>/dev/null; then
    # Key exists - update it using grep + awk (safer than sed for special chars)
    local tmp_file="${cfg_file}.tmp.$$"
    awk -v k="$key" -v v="$value" '
      BEGIN { FS="="; OFS="=" }
      $1 == k { print k, v; next }
      { print }
    ' "$cfg_file" > "$tmp_file" && mv "$tmp_file" "$cfg_file"
  else
    # Key doesn't exist - append it
    echo "${key}=${value}" >> "$cfg_file"
  fi
}

# ----------------------
# System utilities
# ----------------------

# Return number of CPUs available
wt_num_cpus() {
  emulate -L zsh
  setopt local_options pipefail
  local n=""
  if command -v getconf >/dev/null 2>&1; then
    n="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  fi
  if [[ -z "$n" ]] && command -v sysctl >/dev/null 2>&1; then
    n="$(sysctl -n hw.ncpu 2>/dev/null || true)"
  fi
  if [[ -z "$n" ]] && command -v nproc >/dev/null 2>&1; then
    n="$(nproc 2>/dev/null || true)"
  fi
  [[ -z "$n" ]] && n=2
  printf "%s" "$n"
}

# Decide parallel jobs based on requested value and total tasks
wt_detect_jobs_cap() {
  emulate -L zsh
  setopt local_options pipefail
  local requested="$1" total="$2"
  local cpus; cpus="$(wt_num_cpus)"
  local def_jobs=4
  if [[ "$cpus" -lt "$def_jobs" ]]; then def_jobs="$cpus"; fi
  local jobs
  if [[ -n "$requested" ]]; then
    jobs="$requested"
  else
    jobs="$def_jobs"
  fi
  if [[ -z "$total" || "$total" -lt 1 ]]; then total=1; fi
  if [[ "$jobs" -gt "$total" ]]; then jobs="$total"; fi
  if [[ "$jobs" -lt 1 ]]; then jobs=1; fi
  printf "%s" "$jobs"
}

# Check if xargs supports -P (parallel) and -0
wt_xargs_supports_parallel() {
  emulate -L zsh
  setopt local_options pipefail
  command -v xargs >/dev/null 2>&1 || return 1
  printf "%s\0" x | xargs -0 -P 2 -n 1 echo >/dev/null 2>&1 || return 1
  return 0
}

# Portable sed in-place edit (handles macOS vs GNU sed differences)
# Usage: wt_sed_i 's/old/new/' file
wt_sed_i() {
  emulate -L zsh
  setopt local_options pipefail
  local pattern="$1" file="$2"
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS BSD sed requires '' after -i
    sed -i '' "$pattern" "$file"
  else
    # GNU sed uses -i directly
    sed -i "$pattern" "$file"
  fi
}

# ----------------------
# Unified logging helpers
# ----------------------
typeset -g WT_DEBUG_LEVEL_CACHE

wt_get_debug_level() {
  emulate -L zsh
  setopt local_options pipefail
  if [[ -n ${WT_DEBUG_LEVEL_CACHE:-} ]]; then
    printf "%s" "$WT_DEBUG_LEVEL_CACHE"; return 0
  fi
  local lvl="0"
  local raw="${WT_DEBUG:-}"
  if [[ -z "$raw" && -n ${WT_CONFIG[WT_DEBUG_DEFAULT]:-} ]]; then
    raw="${WT_CONFIG[WT_DEBUG_DEFAULT]}"
  fi
  if [[ -n "$raw" ]]; then
    case "${raw:l}" in
      ("1"|"true"|"on"|"yes") lvl="1";;
      ("2"|"verbose") lvl="2";;
      (*) if [[ "$raw" == <-> ]]; then lvl="$raw"; else lvl="1"; fi;;
    esac
  fi
  WT_DEBUG_LEVEL_CACHE="$lvl"
  printf "%s" "$lvl"
}

wt__script_name() {
  emulate -L zsh
  setopt local_options pipefail
  local n
  n="${0##*/}"
  printf "%s" "$n"
}

wt_debug() {
  emulate -L zsh
  setopt local_options pipefail
  local lvl; lvl="$(wt_get_debug_level)"
  (( lvl > 0 )) || return 0
  local script; script="$(wt__script_name)"
  printf "%s\n" "DBG [$script] $*" >&2
}

wt_info()  { emulate -L zsh; setopt local_options pipefail; printf "%s\n" "INF [$0:t] $*" >&2; }
wt_warn()  { emulate -L zsh; setopt local_options pipefail; printf "%s\n" "WRN [$0:t] $*" >&2; }
wt_error() { emulate -L zsh; setopt local_options pipefail; printf "%s\n" "ERR [$0:t] $*" >&2; }

# ============================================================================
# Better Error Messages (Phase 2 - v1.1.0)
# ============================================================================

# Show error when not in a git repository
wt_error_not_git_repo() {
  cat >&2 <<'ERROR'
❌ Not a git repository

This command must be run from inside a git repository.

Try:
  cd /path/to/your/repo        # Navigate to your repository
  git init                     # Initialize new repository
  git clone <url>              # Clone existing repository

What's a git repository?
  A directory containing a .git folder that tracks your code history.

ERROR
}

# Show error when fzf is missing but recommended
wt_error_fzf_missing() {
  cat >&2 <<'ERROR'
⚠️  fzf not found

For the best experience, install fzf (fuzzy finder):
  brew install fzf            # macOS via Homebrew
  apt install fzf             # Ubuntu/Debian
  
Continuing with basic selection...

ERROR
}

# Show error when branch already exists
wt_error_branch_exists() {
  local branch="$1"
  cat >&2 <<ERROR
❌ Branch '$branch' already exists

Did you mean:
  wt open $branch              # Open existing worktree for this branch
  wtopen $branch               # (same thing)
  wt new ${branch}-v2          # Create with a different name

Or use a different branch name:
  wt new $branch-new
  wt new $branch-$(date +%Y%m%d)

ERROR
}

# ============================================================================
# Smart Editor Detection (Phase 1 - v1.0.3)
# ============================================================================

# Detect the best editor/IDE to use
# Priority: WT_EDITOR > WT_APP > VISUAL > EDITOR > GUI detection > fallback
# Returns: editor name (e.g. "Visual Studio Code", "vim") or empty
wt_detect_editor() {
  emulate -L zsh
  setopt local_options pipefail
  
  # 1. Explicit user preferences (highest priority)
  if [[ -n ${WT_EDITOR:-} ]]; then
    echo "$WT_EDITOR"
    return 0
  fi
  
  if [[ -n ${WT_APP:-} ]]; then
    echo "$WT_APP"
    return 0
  fi
  
  # 2. Standard environment variables
  if [[ -n ${VISUAL:-} ]]; then
    echo "$VISUAL"
    return 0
  fi
  
  if [[ -n ${EDITOR:-} ]]; then
    echo "$EDITOR"
    return 0
  fi
  
  # 3. Detect common GUI editors on macOS
  if [[ "$OSTYPE" == darwin* ]]; then
    local gui_editors=(
      "Visual Studio Code"
      "Code"
      "Cursor"
      "IntelliJ IDEA"
      "IntelliJ IDEA CE"
      "PyCharm"
      "WebStorm"
      "Android Studio"
      "Sublime Text"
      "Atom"
      "TextMate"
      "MacVim"
    )
    
    for editor in "${gui_editors[@]}"; do
      if [[ -d "/Applications/${editor}.app" ]]; then
        echo "$editor"
        return 0
      fi
    done
  fi
  
  # 4. Check for command-line editors
  local cli_editors=(code cursor idea pycharm webstorm vim nvim emacs nano)
  for cmd in "${cli_editors[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd"
      return 0
    fi
  done
  
  # 5. No editor found
  echo ""
  return 1
}

# First-run editor setup (one time only)
# Shows interactive menu and saves preference
wt_first_run_editor_setup() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Handle interrupt gracefully - use auto-detection if user cancels
  local _interrupted=0
  trap '_interrupted=1' INT
  
  echo "" >&2
  echo "👋 Welcome to git-worktrees!" >&2
  echo "" >&2
  echo "📂 Choose your default editor:" >&2
  echo "  1) Android Studio" >&2
  echo "  2) Visual Studio Code" >&2
  echo "  3) Cursor" >&2
  echo "  4) IntelliJ IDEA" >&2
  echo "  5) PyCharm" >&2
  echo "  6) WebStorm" >&2
  echo "  7) Sublime Text" >&2
  echo "  8) vim" >&2
  echo "  9) Don't auto-open (show path only)" >&2
  echo "" >&2
  printf "Choice [1-9]: " >&2
  
  local choice
  read -r choice || _interrupted=1
  
  # Handle Ctrl-C: fall back to auto-detection
  if (( _interrupted )); then
    echo "" >&2
    echo "⚠️  Setup interrupted. Using auto-detection." >&2
    trap - INT
    local detected
    detected="$(wt_detect_editor 2>/dev/null)" || detected=""
    [[ -n "$detected" ]] && echo "$detected"
    return 0
  fi
  
  local selected=""
  case "$choice" in
    1) selected="Android Studio" ;;
    2) selected="Visual Studio Code" ;;
    3) selected="Cursor" ;;
    4) selected="IntelliJ IDEA" ;;
    5) selected="PyCharm" ;;
    6) selected="WebStorm" ;;
    7) selected="Sublime Text" ;;
    8) selected="vim" ;;
    9) selected="none" ;;
    *) 
      echo "" >&2
      echo "⚠️  Invalid choice. Using auto-detection." >&2
      selected="auto"
      ;;
  esac
  
  # Save to config
  local config_dir="${HOME}/.config/git-worktrees"
  local config_file="${config_dir}/config"
  mkdir -p "$config_dir"
  
  if [[ "$selected" == "auto" ]]; then
    # Try to detect
    selected="$(wt_detect_editor)"
    [[ -z "$selected" ]] && selected="none"
  fi
  
  # Create config with choice
  if typeset -f wt_init_config >/dev/null 2>&1; then
    wt_init_config >/dev/null 2>&1
    if [[ -f "$config_file" ]]; then
      wt_sed_i "s|^editor=.*|editor=${selected}|" "$config_file"
    fi
  else
    cat > "$config_file" <<EOF
# git-worktrees configuration
editor=${selected}
behavior.autoopen=true
behavior.editor_prompt=silent
EOF
  fi
  
  echo "" >&2
  if [[ "$selected" == "none" ]]; then
    echo "✅ Configured: Show path only (no auto-open)" >&2
  else
    echo "✅ Saved: $selected" >&2
  fi
  echo "" >&2
  echo "  You can change this anytime:" >&2
  echo "    wt config edit" >&2
  echo "    wt config set editor \"Different Editor\"" >&2
  echo "    export WT_EDITOR=\"Different Editor\"" >&2
  echo "" >&2
  printf "Press Enter to continue... " >&2
  read -r || true  # Ignore Ctrl-C on final prompt
  
  trap - INT  # Reset interrupt handler
  [[ "$selected" != "none" ]] && echo "$selected"
  return 0
}

# Get the editor/app to use
# Returns: editor name or empty (if user chose "none")
wt_get_editor() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Check if first run needed
  local config_file="${HOME}/.config/git-worktrees/config"
  if [[ ! -f "$config_file" ]]; then
    wt_first_run_editor_setup
    return $?
  fi
  
  # Load from config or detect
  local detected
  detected="$(wt_detect_editor)"
  
  if [[ -n "$detected" ]]; then
    echo "$detected"
    return 0
  fi
  
  # No editor found
  return 1
}

# Load editor from config if not already set via env var
wt_load_editor_config() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Already set via env var? Use that.
  if [[ -n ${WT_EDITOR:-} ]] || [[ -n ${WT_APP:-} ]]; then
    return 0
  fi
  
  local config_file="${HOME}/.config/git-worktrees/config"
  if [[ -f "$config_file" ]]; then
    local saved_editor
    saved_editor="$(grep "^editor=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    if [[ -n "$saved_editor" && "$saved_editor" != "none" ]]; then
      export WT_EDITOR="$saved_editor"
    fi
  fi
}

# ============================================================================
# Extended Config Support (Phase 2 - v1.1.0)
# ============================================================================

# Load full config file and set environment variables
wt_load_full_config() {
  emulate -L zsh
  setopt local_options pipefail
  
  local config_file="${HOME}/.config/git-worktrees/config"
  [[ ! -f "$config_file" ]] && return 0
  
  # Load behavior settings (don't override if already set)
  if [[ -z ${WTNEW_AUTO_OPEN:-} ]]; then
    local auto_open
    auto_open="$(grep "^behavior.autoopen=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    [[ "$auto_open" == "true" ]] && export WTNEW_AUTO_OPEN=1
    [[ "$auto_open" == "false" ]] && export WTNEW_AUTO_OPEN=0
  fi
  
  if [[ -z ${WTNEW_ALWAYS_PUSH:-} ]]; then
    local auto_push
    auto_push="$(grep "^behavior.autopush=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    [[ "$auto_push" == "true" ]] && export WTNEW_ALWAYS_PUSH=1
  fi
  
  if [[ -z ${WTNEW_PREFER_REUSE:-} ]]; then
    local prefer_reuse
    prefer_reuse="$(grep "^behavior.preferreuse=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    [[ "$prefer_reuse" == "true" ]] && export WTNEW_PREFER_REUSE=1
  fi
  
  # Load UI settings
  if [[ -z ${WT_FZF_HEIGHT:-} ]]; then
    local fzf_height
    fzf_height="$(grep "^ui.fzfheight=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    [[ -n "$fzf_height" ]] && export WT_FZF_HEIGHT="$fzf_height"
  fi
  
  return 0
}

# Initialize config file with sensible defaults
wt_init_config() {
  emulate -L zsh
  setopt local_options pipefail
  
  local config_dir="${HOME}/.config/git-worktrees"
  local config_file="${config_dir}/config"
  
  # Don't overwrite existing config
  [[ -f "$config_file" ]] && return 0
  
  mkdir -p "$config_dir"
  
  local detected_editor
  detected_editor="$(wt_detect_editor 2>/dev/null)" || detected_editor=""
  
  cat > "$config_file" <<EOF
# git-worktrees configuration
# Edit this file to customize behavior
# Or use environment variables to override (higher priority)

# ============================================================================
# Editor Settings
# ============================================================================
# Which editor/IDE to open worktrees in
# Environment variable override: WT_EDITOR or WT_APP
editor=${detected_editor:-}

# ============================================================================
# Behavior Settings
# ============================================================================
# Automatically open editor after creating worktree
# Environment variable override: WTNEW_AUTO_OPEN
behavior.autoopen=true

# Always push new branches to remote by default
# Environment variable override: WTNEW_ALWAYS_PUSH
behavior.autopush=false

# Prefer reusing existing worktree directories
# Environment variable override: WTNEW_PREFER_REUSE
behavior.preferreuse=false

# ============================================================================
# UI Settings
# ============================================================================
# FZF height (e.g. 40%, 20, etc.)
# Environment variable override: WT_FZF_HEIGHT
ui.fzfheight=40%

# Show keyboard shortcuts in FZF header
ui.showshortcuts=true

# ============================================================================
# Priority Order
# ============================================================================
# 1. Command-line flags (highest priority)
# 2. Environment variables
# 3. This config file (lowest priority)
#
# Example:
#   export WT_EDITOR="VS Code"    # Overrides config file
#   wtnew --app="IntelliJ IDEA"   # Overrides everything
EOF
  
  echo "✅ Created config file: $config_file" >&2
  return 0
}

