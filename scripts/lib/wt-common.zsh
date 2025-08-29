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

# Open a directory in Android Studio (robust macOS chain)
wt_open_in_android_studio() {
  emulate -L zsh
  setopt local_options pipefail
  local dir="$1" app_name="${2:-Android Studio}"
  if command -v studio >/dev/null 2>&1; then
    studio "$dir" >/dev/null 2>&1 || true
  else
    if [[ -d "$dir/.idea" ]]; then
      open -a "$app_name" "$dir/.idea" >/dev/null 2>&1 || true
    elif [[ -f "$dir/settings.gradle" || -f "$dir/settings.gradle.kts" ]]; then
      local sg="$dir/settings.gradle"
      [[ -f "$dir/settings.gradle.kts" ]] && sg="$dir/settings.gradle.kts"
      open -a "$app_name" "$sg" >/dev/null 2>&1 || true
    elif [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]; then
      local bg="$dir/build.gradle"
      [[ -f "$dir/build.gradle.kts" ]] && bg="$dir/build.gradle.kts"
      open -a "$app_name" "$bg" >/dev/null 2>&1 || true
    else
      open -a "$app_name" "$dir" >/dev/null 2>&1 || true
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


