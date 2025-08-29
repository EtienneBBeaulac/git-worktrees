#!/usr/bin/env bash
set -euo pipefail

PREFIX="${HOME}/.zsh/functions"
REPO_RAW="https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main"

EMOJI=${EMOJI:-1}
COLOR=${COLOR:-1}
QUIET=${QUIET:-0}
VERBOSE=${VERBOSE:-0}
DRY_RUN=${DRY_RUN:-0}
NO_SOURCE=${NO_SOURCE:-0}

prefix() { printf "%s" "[git-worktrees]"; }
say()    { (( QUIET )) || echo "$(prefix) $*"; }
ok()     { (( QUIET )) || echo "$(prefix) $*"; }
err()    { echo "$(prefix) $*" >&2; }
do_run() { if (( DRY_RUN )); then say "DRY: $*"; else eval "$@"; fi }

say "Installing…"

say "Ensuring directory: $PREFIX"
mkdir -p "$PREFIX"

fetch() {
  local src="$1" dst="$2"
  if (( VERBOSE )); then
    say "Fetching $src -> $dst"
  else
    say "Fetching $(basename "$src") -> $dst"
  fi
  if (( DRY_RUN )); then
    return 0
  fi
  curl -fsSL "$src" -o "$dst"
}

fetch "$REPO_RAW/scripts/wtnew"              "$PREFIX/wtnew.zsh"
fetch "$REPO_RAW/scripts/wtrm"               "$PREFIX/wtrm.zsh"
fetch "$REPO_RAW/scripts/wtopen"             "$PREFIX/wtopen.zsh"
fetch "$REPO_RAW/scripts/wtls"               "$PREFIX/wtls.zsh"
fetch "$REPO_RAW/scripts/lib/wt-common.zsh"  "$PREFIX/wt-common.zsh"

add_source_line() {
  local needle="$1" line="$2"
  if grep -q "$needle" "${HOME}/.zshrc"; then
    (( VERBOSE )) && say "~/.zshrc already has: $needle"
  else
    say "Updating ~/.zshrc"
    echo "$line" >> "${HOME}/.zshrc"
  fi
}

if (( ! NO_SOURCE )); then
  add_source_line 'wtnew.zsh'  '[[ -f ~/.zsh/functions/wtnew.zsh ]] && source ~/.zsh/functions/wtnew.zsh'
  add_source_line 'wtrm.zsh'   '[[ -f ~/.zsh/functions/wtrm.zsh  ]] && source ~/.zsh/functions/wtrm.zsh'
  add_source_line 'wtopen.zsh' '[[ -f ~/.zsh/functions/wtopen.zsh ]] && source ~/.zsh/functions/wtopen.zsh'
  add_source_line 'wtls.zsh'   '[[ -f ~/.zsh/functions/wtls.zsh  ]] && source ~/.zsh/functions/wtls.zsh'
  add_source_line 'wt-common.zsh' '[[ -f ~/.zsh/functions/wt-common.zsh ]] && source ~/.zsh/functions/wt-common.zsh'
fi

# Self-test (non-fatal)
if (( ! DRY_RUN )); then
  say "Self-test: sourcing functions…"
  if zsh -fc 'source ~/.zsh/functions/wt-common.zsh; source ~/.zsh/functions/wtnew.zsh; source ~/.zsh/functions/wtopen.zsh; source ~/.zsh/functions/wtrm.zsh; source ~/.zsh/functions/wtls.zsh; typeset -f wtnew wtopen wtrm wtls >/dev/null'; then
    ok "Commands available: wtnew, wtopen, wtrm, wtls"
  else
    err "Warning: could not verify commands in a subshell. Try: source ~/.zshrc"
  fi
fi

say "Installed. Restart your shell or run: source ~/.zshrc"

if (( ! QUIET )); then
  cat <<HELP
Commands:
  wtnew -n feature/x -b origin/main --push          # create and open worktree
  wtopen                                             # [wtopen-verify] browse picker
  wtrm --rm-detached --jobs 6 --yes                  # remove detached worktrees in parallel
  wtls --fzf --open                                  # list & open worktrees
HELP
fi
