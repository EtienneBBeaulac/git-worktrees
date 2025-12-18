#!/usr/bin/env zsh
# wt-common.zsh: Core library for git-worktrees
#
# This is the single entry point for all git-worktrees functionality.
# All scripts source this file, and it loads all required modules.
#
# GLOBAL STATE:
#   - __WT_LIB_LOADED: Guard to prevent double-sourcing
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

# ============================================================================
# Source Guard - Prevent Double Sourcing
# ============================================================================
[[ -n ${__WT_LIB_LOADED:-} ]] && return 0

emulate -L zsh
unsetopt xtrace verbose

typeset -g __WT_LIB_LOADED=1

# ============================================================================
# Determine Library Directory
# ============================================================================
# ${(%):-%x} gets the path of THIS file, even when sourced
# :A makes it absolute, :h gets the directory
typeset -g __WT_LIB_DIR="${${(%):-%x}:A:h}"

# Version (automatically updated by GitHub Actions on release)
typeset -g WT_VERSION="1.0.2-test"

# ============================================================================
# Load Required Modules
# ============================================================================
# These modules are REQUIRED, not optional. If any are missing, the
# installation is broken and we fail loudly rather than silently degrading.

_wt_require_module() {
  local module="$1"
  local path="$__WT_LIB_DIR/$module"
  if [[ ! -f "$path" ]]; then
    echo "FATAL: $module not found at $path" >&2
    echo "       Your git-worktrees installation may be incomplete." >&2
    echo "       Try reinstalling or check that all lib files are present." >&2
    return 1
  fi
  source "$path" || {
    echo "FATAL: Failed to source $module" >&2
    return 1
  }
}

_wt_require_module "wt-recovery.zsh" || return 1
_wt_require_module "wt-validation.zsh" || return 1
_wt_require_module "wt-discovery.zsh" || return 1

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

# Check if worktree has uncommitted changes
# Usage: wt_is_worktree_dirty <directory>
# Returns: 0 if dirty (has changes), 1 if clean
wt_is_worktree_dirty() {
  emulate -L zsh
  local dir="$1"
  local git_status
  git_status="$(git -C "$dir" status --porcelain --untracked-files=all 2>/dev/null)"
  [[ -n "$git_status" ]]
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
  echo "ℹ️  $1" >&2  # Info messages go to stderr for clean stdout capture
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
# Boolean/Flag Parsing Utilities
# ----------------------

# Parse a boolean environment variable or value
# Usage: wt_parse_bool "value" [default]
# Returns: 0 (true) or 1 (false)
# Recognizes: true/false, yes/no, on/off, 1/0 (case-insensitive)
wt_parse_bool() {
  emulate -L zsh
  local val="${1:-}" default="${2:-false}"
  
  # Empty value uses default
  [[ -z "$val" ]] && val="$default"
  
  case "${val:l}" in
    1|true|yes|on|enabled) return 0 ;;
    0|false|no|off|disabled|"") return 1 ;;
    *) return 1 ;;  # Unknown values treated as false
  esac
}

# ----------------------
# Non-Interactive Mode Support
# ----------------------

# Check if running in interactive mode
# Returns: 0 if interactive, 1 if non-interactive (batch/test mode)
# Non-interactive when:
#   - WT_NON_INTERACTIVE is set (explicit test/batch mode)
#   - CI environment detected
# Note: We don't check -t 0 (stdin is tty) because some tests pipe valid input
wt_is_interactive() {
  emulate -L zsh
  [[ -z "${WT_NON_INTERACTIVE:-}" && -z "${CI:-}" ]]
}

# Prompt for a numbered choice, fail in non-interactive mode
# Usage: wt_prompt_choice "prompt" max_choice [default]
# Sets REPLY to choice number
# Returns: 0 on success, 1 if non-interactive without default
wt_prompt_choice() {
  emulate -L zsh
  local prompt="$1" max="$2" default="${3:-}"
  
  if wt_is_interactive; then
    printf "%s" "$prompt"
    read -r REPLY
    return 0
  elif [[ -n "$default" ]]; then
    REPLY="$default"
    return 0
  else
    return 1  # Signal non-interactive failure
  fi
}

# Yes/No confirmation, fail in non-interactive mode
# Usage: wt_confirm "prompt" [default: y|n]
# Returns: 0 for yes, 1 for no or non-interactive
wt_confirm() {
  emulate -L zsh
  local prompt="$1" default="${2:-n}"
  
  if wt_is_interactive; then
    printf "%s" "$prompt"
    read -r REPLY
    [[ "${REPLY:l}" == "y"* ]]
  elif [[ "${default:l}" == "y"* ]]; then
    return 0
  else
    return 1
  fi
}

# ----------------------
# Validation Utilities
# ----------------------

# Validate a value is one of allowed options
# Usage: wt_validate_option "value" "opt1" "opt2" ...
# Returns: 0 if valid, 1 if invalid (prints error)
wt_validate_option() {
  emulate -L zsh
  local val="$1"
  shift
  local opt
  for opt in "$@"; do
    [[ "$val" == "$opt" ]] && return 0
  done
  echo "Invalid value: '$val'. Expected one of: $*" >&2
  return 1
}

# ----------------------
# Git Operations with Timeout
# ----------------------

# Run git fetch with timeout to prevent hanging on slow networks
# Usage: wt_git_fetch_with_timeout [timeout_seconds]
# Returns: 0 on success, 1 on failure/timeout
# Sets: WT_FETCH_STATUS with result message
wt_git_fetch_with_timeout() {
  emulate -L zsh
  local timeout_secs="${1:-${WT_FETCH_TIMEOUT:-30}}"
  
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_secs" git fetch --all --prune --tags --quiet 2>/dev/null
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$timeout_secs" git fetch --all --prune --tags --quiet 2>/dev/null
  else
    # No timeout command available, run without timeout
    git fetch --all --prune --tags --quiet 2>/dev/null
  fi
}

# Fetch remotes with user feedback and graceful failure
# Usage: wt_fetch_remotes_safe
# Always succeeds (continues with cached refs on failure)
wt_fetch_remotes_safe() {
  emulate -L zsh
  echo "🔄  Fetching remotes…"
  if ! wt_git_fetch_with_timeout; then
    echo "⚠️  Fetch failed or timed out, continuing with cached refs..."
  fi
}

# ----------------------
# Editor Selection Menu
# ----------------------

# Known editors with their detection methods
# Format: "Name|macOS app name|CLI command"
# Sorted alphabetically (case-insensitive) - Android Studio first
typeset -ga WT_KNOWN_EDITORS=(
  "Android Studio|Android Studio|studio"
  "Cursor|Cursor|cursor"
  "Emacs||emacs"
  "Fleet|Fleet|fleet"
  "GoLand|GoLand|goland"
  "Helix||hx"
  "IntelliJ IDEA|IntelliJ IDEA|idea"
  "IntelliJ IDEA CE|IntelliJ IDEA CE|idea"
  "MacVim|MacVim|mvim"
  "Neovim||nvim"
  "PyCharm|PyCharm|pycharm"
  "RustRover|RustRover|rustrover"
  "Sublime Text|Sublime Text|subl"
  "TextMate|TextMate|mate"
  "Vim||vim"
  "Visual Studio Code|Visual Studio Code|code"
  "WebStorm|WebStorm|webstorm"
  "Zed|Zed|zed"
)

# Check if a specific editor is installed
# Usage: wt_is_editor_installed "Visual Studio Code"
# Returns: 0 if installed, 1 if not
wt_is_editor_installed() {
  emulate -L zsh
  local name="$1"
  local entry mac_app cli_cmd
  
  for entry in "${WT_KNOWN_EDITORS[@]}"; do
    local editor_name="${entry%%|*}"
    # Case-insensitive comparison for known editors
    if [[ "${editor_name:l}" == "${name:l}" ]]; then
      local rest="${entry#*|}"
      mac_app="${rest%%|*}"
      cli_cmd="${rest#*|}"
      
      # Check macOS app
      if [[ -n "$mac_app" && -d "/Applications/${mac_app}.app" ]]; then
        return 0
      fi
      # Check CLI command
      if [[ -n "$cli_cmd" ]] && command -v "$cli_cmd" >/dev/null 2>&1; then
        return 0
      fi
      return 1
    fi
  done
  
  # Unknown editor - check if it's a command
  if command -v "$name" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Get list of installed editors
# Usage: installed=($(wt_get_installed_editors))
# Returns: newline-separated list of installed editor names
wt_get_installed_editors() {
  emulate -L zsh
  local entry editor_name rest mac_app cli_cmd
  local -a installed
  
  for entry in "${WT_KNOWN_EDITORS[@]}"; do
    editor_name="${entry%%|*}"
    rest="${entry#*|}"
    mac_app="${rest%%|*}"
    cli_cmd="${rest#*|}"
    
    # Check macOS app
    if [[ -n "$mac_app" && -d "/Applications/${mac_app}.app" ]]; then
      installed+=("$editor_name")
      continue
    fi
    # Check CLI command
    if [[ -n "$cli_cmd" ]] && command -v "$cli_cmd" >/dev/null 2>&1; then
      installed+=("$editor_name")
    fi
  done
  
  printf "%s\n" "${installed[@]}"
}

# Test if an editor command works
# Usage: wt_test_editor "code"
# Returns: 0 if works, 1 if not
wt_test_editor() {
  emulate -L zsh
  local editor="$1"
  
  # For known editors, check installation
  if wt_is_editor_installed "$editor"; then
    return 0
  fi
  
  # For arbitrary commands, check if command exists
  local cmd="${editor%% *}"  # Get first word (command without args)
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  
  return 1
}

# Display smart editor selection menu (shows only installed editors)
# Usage: selected=$(wt_editor_selection_menu)
# Returns: Editor name, "auto", "none", or custom command on stdout; empty on cancel
wt_editor_selection_menu() {
  emulate -L zsh
  local -a installed
  local line i=0
  
  # Get installed editors
  while IFS= read -r line; do
    [[ -n "$line" ]] && installed+=("$line")
  done < <(wt_get_installed_editors)
  
  # Use FZF if available and we have multiple options
  if wt_has_fzf && (( ${#installed[@]} > 0 )); then
    local options=""
    for editor in "${installed[@]}"; do
      options+="$editor (installed)"$'\n'
    done
    options+="Auto-detect"$'\n'
    options+="Custom command..."$'\n'
    options+="None (show path only)"
    
    local selection
    selection="$(printf "%s" "$options" | FZF_DEFAULT_OPTS= command fzf \
      --prompt="📂 Select editor: " \
      --height=${WT_FZF_HEIGHT:-40%} \
      --reverse \
      ${WT_FZF_OPTS:-})" || return 1
    
    case "$selection" in
      "Auto-detect") echo "auto" ;;
      "Custom command..."*)
        printf "Enter command (e.g., 'code --new-window'): " >&2
        local custom
        read -r custom
        [[ -n "$custom" ]] && echo "$custom" || return 1
        ;;
      "None (show path only)") echo "none" ;;
      *" (installed)") echo "${selection% (installed)}" ;;
      *) echo "$selection" ;;
    esac
    return 0
  fi
  
  # Fallback to numbered menu
  echo "" >&2
  echo "📂 Choose your default editor:" >&2
  echo "" >&2
  
  # Show installed editors first
  local -A choice_map
  i=1
  if (( ${#installed[@]} > 0 )); then
    echo "  Installed:" >&2
    for editor in "${installed[@]}"; do
      echo "  $i) $editor" >&2
      choice_map[$i]="$editor"
      ((i++))
    done
    echo "" >&2
  fi
  
  # Special options
  local auto_idx=$i; ((i++))
  local custom_idx=$i; ((i++))
  local none_idx=$i
  
  echo "  $auto_idx) Auto-detect" >&2
  echo "  $custom_idx) Custom command..." >&2
  echo "  $none_idx) None (show path only)" >&2
  echo "" >&2
  printf "Choice [1-$none_idx]: " >&2
  
  local choice
  read -r choice
  
  if [[ "$choice" == "$auto_idx" ]]; then
    echo "auto"
  elif [[ "$choice" == "$custom_idx" ]]; then
    printf "Enter command (e.g., 'code --new-window'): " >&2
    local custom
    read -r custom
    [[ -n "$custom" ]] && echo "$custom" || return 1
  elif [[ "$choice" == "$none_idx" ]]; then
    echo "none"
  elif [[ -n "${choice_map[$choice]:-}" ]]; then
    echo "${choice_map[$choice]}"
  else
    return 1
  fi
}

# Prompt user to select editor and save to config
# Usage: wt_change_editor_interactive
# Returns: 0 on success, 1 on cancel/invalid
wt_change_editor_interactive() {
  emulate -L zsh
  local selected
  selected="$(wt_editor_selection_menu)"
  
  if [[ -z "$selected" ]]; then
    echo "⚠️  Cancelled"
    return 1
  fi
  
  # Handle auto-detect
  if [[ "$selected" == "auto" ]]; then
    local detected
    detected="$(wt_detect_editor)"
    if [[ -n "$detected" ]]; then
      echo "🔍 Auto-detected: $detected"
      selected="$detected"
    else
      echo "⚠️  No editor detected, using 'none'"
      selected="none"
    fi
  fi
  
  # Test the editor before saving (unless it's 'none' or 'auto')
  if [[ "$selected" != "none" ]]; then
    echo -n "Testing $selected... " >&2
    if wt_test_editor "$selected"; then
      echo "✅" >&2
    else
      echo "⚠️  Not found (saving anyway)" >&2
    fi
  fi
  
  # Save to config
  wt_set_config "editor" "$selected"
  
  if [[ "$selected" == "none" ]]; then
    echo "✅ Configured: Show path only (no auto-open)"
  else
    echo "✅ Saved: $selected"
  fi
  return 0
}

# ----------------------
# Shell Quoting Utilities
# ----------------------
# These functions help create shell-safe strings for display and copy-paste.

# Escape a string for use inside single quotes
# Replaces each ' with '\'' (end quote, escaped quote, start quote)
# Usage: wt_escape_single_quotes "string with 'quotes'"
# Output: string with '\''quotes'\''
wt_escape_single_quotes() {
  emulate -L zsh
  local str="$1"
  # Use explicit replacement to avoid zsh escaping issues
  # Each ' becomes '\'' (4 chars: apostrophe, backslash, apostrophe, apostrophe)
  local result=""
  local i char
  for (( i=1; i <= ${#str}; i++ )); do
    char="${str[$i]}"
    if [[ "$char" == "'" ]]; then
      result+="'\\''";
    else
      result+="$char"
    fi
  done
  printf "%s" "$result"
}

# Quote a string for safe shell use (single-quoted with escaping)
# Usage: wt_shell_quote "/path/with 'special' chars"
# Output: '/path/with '\''special'\'' chars'
wt_shell_quote() {
  emulate -L zsh
  local str="$1"
  printf "'%s'" "$(wt_escape_single_quotes "$str")"
}

# Build a safe cd command for display/copy-paste
# Usage: wt_cd_command "/path/to/dir"
# Output: cd '/path/to/dir'  (with proper escaping)
wt_cd_command() {
  emulate -L zsh
  local dir="$1"
  printf "cd %s" "$(wt_shell_quote "$dir")"
}

# Build a safe shell command string with multiple arguments
# Usage: wt_shell_command "git" "push" "-u" "origin" "my branch"
# Output: git push -u origin 'my branch'
# Note: Only quotes arguments that need it (contain spaces/special chars)
wt_shell_command() {
  emulate -L zsh
  local cmd="" arg
  for arg in "$@"; do
    [[ -n "$cmd" ]] && cmd+=" "
    # Quote if contains spaces, quotes, or shell special chars
    if [[ "$arg" =~ [[:space:]\'\"\$\`\\] ]]; then
      cmd+="$(wt_shell_quote "$arg")"
    else
      cmd+="$arg"
    fi
  done
  printf "%s" "$cmd"
}

# ----------------------
# Cross-Platform Clipboard
# ----------------------

# Copy text to system clipboard (cross-platform)
# Usage: wt_copy_to_clipboard "text to copy"
# Returns: 0 on success, 1 if no clipboard tool available
wt_copy_to_clipboard() {
  emulate -L zsh
  local text="$1"
  
  if command -v pbcopy >/dev/null 2>&1; then
    # macOS
    printf "%s" "$text" | pbcopy
    return 0
  elif command -v xclip >/dev/null 2>&1; then
    # Linux with X11
    printf "%s" "$text" | xclip -selection clipboard
    return 0
  elif command -v xsel >/dev/null 2>&1; then
    # Linux with X11 (alternative)
    printf "%s" "$text" | xsel --clipboard --input
    return 0
  elif command -v wl-copy >/dev/null 2>&1; then
    # Wayland
    printf "%s" "$text" | wl-copy
    return 0
  fi
  
  # No clipboard tool available
  return 1
}

# ----------------------
# Cross-Platform Terminal
# ----------------------

# Open a directory in a new terminal window (cross-platform)
# Usage: wt_open_in_terminal "/path/to/dir"
# Returns: 0 on success, 1 on failure
wt_open_in_terminal() {
  emulate -L zsh
  local dir="$1"
  local term_app="${WT_TERMINAL_APP:-}"
  
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS
    [[ -z "$term_app" ]] && term_app="iTerm"
    if open -a "$term_app" "$dir" >/dev/null 2>&1; then
      return 0
    elif open -a "Terminal" "$dir" >/dev/null 2>&1; then
      return 0
    else
      wt_msg_error "Could not open terminal"
      return 1
    fi
  else
    # Linux - try common terminals
    if [[ -n "$term_app" ]]; then
      # Validate custom terminal command exists
      if ! command -v "$term_app" >/dev/null 2>&1; then
        wt_msg_error "Terminal '$term_app' not found"
        echo "   Check WT_TERMINAL_APP setting or install the terminal" >&2
        return 1
      fi
      # Detect terminal type and use appropriate flags
      # Note: background processes always "succeed" at fork, so we can only
      # validate the command exists, not that the window actually opened
      case "$term_app" in
        *konsole*)
          "$term_app" --workdir "$dir" &>/dev/null &
          ;;
        *xterm*)
          "$term_app" -e "cd $(wt_shell_quote "$dir") && exec \$SHELL" &>/dev/null &
          ;;
        *alacritty*)
          "$term_app" --working-directory "$dir" &>/dev/null &
          ;;
        *)
          # Most terminals support --working-directory
          "$term_app" --working-directory="$dir" &>/dev/null &
          ;;
      esac
      return 0
    elif command -v gnome-terminal >/dev/null 2>&1; then
      gnome-terminal --working-directory="$dir" &>/dev/null &
      return 0
    elif command -v konsole >/dev/null 2>&1; then
      konsole --workdir "$dir" &>/dev/null &
      return 0
    elif command -v xfce4-terminal >/dev/null 2>&1; then
      xfce4-terminal --working-directory="$dir" &>/dev/null &
      return 0
    elif command -v xterm >/dev/null 2>&1; then
      xterm -e "cd $(wt_shell_quote "$dir") && exec \$SHELL" &>/dev/null &
      return 0
    else
      wt_msg_error "No terminal emulator found"
      echo "   Set WT_TERMINAL_APP to your terminal command" >&2
      return 1
    fi
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
# Priority: WT_EDITOR > WT_APP > config > VISUAL > EDITOR > GUI detection > fallback
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
  
  # 2. Check saved config (before env vars, user explicitly chose this)
  local config_file="$(wt_config_file 2>/dev/null)" || config_file=""
  if [[ -n "$config_file" && -f "$config_file" ]]; then
    local saved_editor
    saved_editor="$(grep "^editor=" "$config_file" 2>/dev/null | cut -d= -f2-)"
    if [[ -n "$saved_editor" && "$saved_editor" != "none" && "$saved_editor" != "auto" ]]; then
      echo "$saved_editor"
      return 0
    fi
    # If explicitly set to "none", return empty
    if [[ "$saved_editor" == "none" ]]; then
      return 1
    fi
  fi
  
  # 3. Standard environment variables
  if [[ -n ${VISUAL:-} ]]; then
    echo "$VISUAL"
    return 0
  fi
  
  if [[ -n ${EDITOR:-} ]]; then
    echo "$EDITOR"
    return 0
  fi
  
  # 4. Detect GUI editors on macOS (alphabetical, Android Studio first)
  if [[ "$OSTYPE" == darwin* ]]; then
    local gui_editors=(
      "Android Studio"
      "Cursor"
      "Fleet"
      "GoLand"
      "IntelliJ IDEA"
      "IntelliJ IDEA CE"
      "MacVim"
      "PyCharm"
      "RustRover"
      "Sublime Text"
      "TextMate"
      "Visual Studio Code"
      "WebStorm"
      "Zed"
    )
    
    for editor in "${gui_editors[@]}"; do
      if [[ -d "/Applications/${editor}.app" ]]; then
        echo "$editor"
        return 0
      fi
    done
  fi
  
  # 5. Check for command-line editors (alphabetical)
  local cli_editors=(cursor code emacs fleet goland hx idea mvim nvim pycharm rustrover studio subl vim webstorm zed)
  for cmd in "${cli_editors[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      # Map CLI command back to friendly name
      case "$cmd" in
        studio) echo "Android Studio" ;;
        hx) echo "Helix" ;;
        mvim) echo "MacVim" ;;
        nvim) echo "Neovim" ;;
        subl) echo "Sublime Text" ;;
        code) echo "Visual Studio Code" ;;
        *) echo "$cmd" ;;
      esac
      return 0
    fi
  done
  
  # 6. No editor found
  echo ""
  return 1
}

# Initialize config with auto-detected editor (non-blocking)
# Called automatically on first use - no user interaction
wt_auto_init_config() {
  emulate -L zsh
  setopt local_options pipefail
  
  local config_dir="$(wt_config_dir)"
  local config_file="$(wt_config_file)"
  
  # Already initialized
  [[ -f "$config_file" ]] && return 0
  
  mkdir -p "$config_dir" 2>/dev/null || return 1
  
  # Auto-detect editor
  local detected="auto"  # Let wt_detect_editor handle it dynamically
  
  # Create config
  cat > "$config_file" <<EOF
# git-worktrees configuration
# Editor: 'auto' means auto-detect, or set to specific editor name
# Run 'wt config set editor "Editor Name"' to change
editor=${detected}
behavior.autoopen=true
EOF
  
  return 0
}

# First-run editor setup - now just shows a one-time tip
# No blocking prompt - uses auto-detection by default
wt_first_run_editor_setup() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Initialize config silently
  wt_auto_init_config
  
  # Detect and return editor (no prompt)
  local detected
  detected="$(wt_detect_editor)"
  
  # Show one-time tip (only if we found an editor)
  if [[ -n "$detected" ]]; then
    # Check if we've shown the tip before
    local config_file="$(wt_config_file)"
    if ! grep -q "^tip_shown=true" "$config_file" 2>/dev/null; then
      echo "" >&2
      echo "🔍 Using $detected (auto-detected)" >&2
      echo "💡 Change anytime: wt config set editor \"Other Editor\"" >&2
      echo "" >&2
      # Mark tip as shown
      echo "tip_shown=true" >> "$config_file" 2>/dev/null || true
    fi
    echo "$detected"
    return 0
  fi
  
  # No editor found
  return 1
}

# Get the editor/app to use
# Returns: editor name or empty (if user chose "none" or nothing found)
# Non-blocking: auto-detects on first run without prompting
wt_get_editor() {
  emulate -L zsh
  setopt local_options pipefail
  
  # Ensure config exists (non-blocking)
  local config_file="$(wt_config_file)"
  if [[ ! -f "$config_file" ]]; then
    wt_first_run_editor_setup
    return $?
  fi
  
  # Use wt_detect_editor which checks config, env vars, and auto-detects
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
  
  local config_file="$(wt_config_file)"
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
  
  local config_file="$(wt_config_file)"
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
  
  local config_dir="$(wt_config_dir)"
  local config_file="$(wt_config_file)"
  
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

