#!/usr/bin/env zsh
# wt-common: shared helpers for git-worktrees tools (zsh)

typeset -g __WT_COMMON_SOURCED=1

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
  if command -v studio >/dev/null 2>&1; then
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


