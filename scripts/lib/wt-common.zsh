#!/usr/bin/env zsh
# wt-common: shared helpers for git-worktrees tools (zsh)

emulate -L zsh
unsetopt xtrace verbose
typeset -g __WT_COMMON_SOURCED=1

# Version (automatically updated by GitHub Actions on release)
typeset -g WT_VERSION="1.1.0"

# ============================================================================
# Load enhanced modules (Phase 1: Core Infrastructure)
# ============================================================================
__WT_LIB_DIR="${${(%):-%x}:A:h}"

# Load recovery module (error recovery, retry, transaction log)
[[ -f "$__WT_LIB_DIR/wt-recovery.zsh" ]] && source "$__WT_LIB_DIR/wt-recovery.zsh"

# Load validation module (input validation, sanitization, fuzzy matching)
[[ -f "$__WT_LIB_DIR/wt-validation.zsh" ]] && source "$__WT_LIB_DIR/wt-validation.zsh"

# Load discovery module (help system, hints, cheatsheet)
[[ -f "$__WT_LIB_DIR/wt-discovery.zsh" ]] && source "$__WT_LIB_DIR/wt-discovery.zsh"

# ============================================================================
# Original wt-common functionality
# ============================================================================

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

# Split a tab-delimited line into two fields via $reply array
# Usage: wt_split_tab "A\tB"; echo ${reply[1]} ${reply[2]}
wt_split_tab() {
  emulate -L zsh
  setopt local_options pipefail
  local line="$1" tab
  tab=$'\t'
  local left="${line%%${tab}*}"
  local right="${line#*${tab}}"
  right="${right%%${tab}*}"
  reply=("$left" "$right")
}

# Open a directory in Android Studio (robust macOS chain)
wt_open_in_android_studio() {
  emulate -L zsh
  setopt local_options pipefail
  local dir="$1" app_name="${2:-Android Studio}"
  # Test/override: prefer xdg-open when requested
  if [[ -n ${WT_PREFER_XDG_OPEN:-} ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$dir" >/dev/null 2>&1 || true
    return 0
  fi
  # Only use 'studio' command if app_name is actually Android Studio
  if [[ "$app_name" == "Android Studio" ]] && command -v studio >/dev/null 2>&1; then
    studio "$dir" >/dev/null 2>&1 || true
  else
    if [[ -d "$dir/.idea" ]]; then
      { open -a "$app_name" "$dir/.idea" >/dev/null 2>&1 || command -v xdg-open >/dev/null 2>&1 && xdg-open "$dir/.idea" >/dev/null 2>&1 || true; } || true
    elif [[ -f "$dir/settings.gradle" || -f "$dir/settings.gradle.kts" ]]; then
      local sg="$dir/settings.gradle"
      [[ -f "$dir/settings.gradle.kts" ]] && sg="$dir/settings.gradle.kts"
      { open -a "$app_name" "$sg" >/dev/null 2>&1 || command -v xdg-open >/dev/null 2>&1 && xdg-open "$sg" >/dev/null 2>&1 || true; } || true
    elif [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]; then
      local bg="$dir/build.gradle"
      [[ -f "$dir/build.gradle.kts" ]] && bg="$dir/build.gradle.kts"
      { open -a "$app_name" "$bg" >/dev/null 2>&1 || command -v xdg-open >/dev/null 2>&1 && xdg-open "$bg" >/dev/null 2>&1 || true; } || true
    else
      { open -a "$app_name" "$dir" >/dev/null 2>&1 || command -v xdg-open >/dev/null 2>&1 && xdg-open "$dir" >/dev/null 2>&1 || true; } || true
    fi
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
  local cfg
  if [[ -n ${WT_CONFIG_PATH:-} ]]; then
    cfg="$WT_CONFIG_PATH"
  elif [[ -n ${XDG_CONFIG_HOME:-} && -d ${XDG_CONFIG_HOME}/git-worktrees ]]; then
    cfg="${XDG_CONFIG_HOME}/git-worktrees/config"
  else
    cfg="${HOME:-$PWD}/.config/git-worktrees/config"
  fi
  printf "%s" "$cfg"
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
    # Trim whitespace around key
    key="${key##[[:space:]]*}"
    key="${key%%[[:space:]]*}"
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
  read -r choice
  
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
      sed -i.bak "s|^editor=.*|editor=${selected}|" "$config_file" && rm -f "${config_file}.bak"
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
  read -r
  
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

