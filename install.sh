#!/usr/bin/env bash
set -euo pipefail

# Install to a subdirectory to match source structure exactly
PREFIX="${HOME}/.zsh/functions/git-worktrees"
REPO_RAW_DEFAULT="https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main"
REPO_RAW=${REPO_RAW:-"$REPO_RAW_DEFAULT"}

EMOJI=${EMOJI:-1}
COLOR=${COLOR:-1}
QUIET=${QUIET:-0}
VERBOSE=${VERBOSE:-0}
DRY_RUN=${DRY_RUN:-0}
NO_SOURCE=${NO_SOURCE:-0}
ASSUME_YES=0
PIN_TAG=""
CHECKSUM_FILE=""

prefix() { printf "%s" "[git-worktrees]"; }
say()    { (( QUIET )) || echo "$(prefix) $*"; }
ok()     { (( QUIET )) || echo "$(prefix) $*"; }
err()    { echo "$(prefix) $*" >&2; }
do_run() {
  if (( DRY_RUN )); then
    say "DRY: $*"
  else
    "$@"
  fi
}

usage() {
  cat <<USAGE
Usage: install.sh [--yes] [--tag vX.Y.Z] [--checksum-file PATH_OR_URL] [--dry-run] [--quiet]
  --yes               Non-interactive; do not prompt
  --tag vX.Y.Z        Install from a specific tag (ignored if REPO_RAW is set)
  --checksum-file P   Verify downloaded files using a sha256 list
  --dry-run           Print actions without changing the system
  --quiet             Minimal output
USAGE
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) ASSUME_YES=1; shift;;
    --tag) PIN_TAG="$2"; shift 2;;
    --checksum-file) CHECKSUM_FILE="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --quiet) QUIET=1; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage; exit 2;;
  esac
done

# Apply tag pinning if REPO_RAW was not overridden
if [[ -n "$PIN_TAG" && "$REPO_RAW" == "$REPO_RAW_DEFAULT" ]]; then
  REPO_RAW="https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/${PIN_TAG}"
fi

ROLLBACK_FILES=()
ROLLBACK_BACKUPS=()
ZSHRC_BACKUP=""
INSTALL_OK=0

on_exit() {
  local rc=$?
  if (( rc != 0 )); then
    err "Install failed (rc=$rc). Rolling back…"
    # Restore backups
    local i
    for i in "${ROLLBACK_BACKUPS[@]:-}"; do
      # format: backup_path::dest_path
      local b="${i%%::*}" d="${i##*::}"
      if [[ -f "$b" ]]; then
        mv -f "$b" "$d" 2>/dev/null || true
      fi
    done
    # Remove files created with no backups
    for i in "${ROLLBACK_FILES[@]:-}"; do
      rm -f "$i" 2>/dev/null || true
    done
    # Restore ~/.zshrc if backed up
    if [[ -n "$ZSHRC_BACKUP" && -f "$ZSHRC_BACKUP" ]]; then
      cp -f "$ZSHRC_BACKUP" "${HOME}/.zshrc" 2>/dev/null || true
    fi
  fi
  exit $rc
}
trap on_exit EXIT

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    err "No sha256 tool found"; return 1
  fi
}

verify_checksums() {
  local list="$1"; shift
  local tmp_list=""
  if [[ "$list" =~ ^https?:// ]]; then
    tmp_list=$(mktemp)
    curl -fsSL "$list" -o "$tmp_list" || { err "Failed to download checksums"; return 1; }
    list="$tmp_list"
  fi
  [[ -f "$list" ]] || { err "Checksum file not found: $list"; return 1; }

  local ok=1
  local name hash expected
  for dst in "$@"; do
    name=$(basename "$dst")
    base_no_ext=${name%.zsh}
    hash=$(sha256_file "$dst")
    # Accept entries matching scripts/<name>, scripts/lib/<name>, just <name>, and variants without .zsh
    expected=$(awk -v n="$name" -v m="$base_no_ext" '{h=$1; $1=""; sub(/^ +/, "", $0); f=$0; if (f=="scripts/" n || f=="scripts/lib/" n || f==n || f=="scripts/" m || f=="scripts/lib/" m || f==m) {print h}}' "$list" | tail -n1)
    if [[ -z "$expected" ]]; then
      err "No checksum entry for $name"; ok=0; continue
    fi
    if [[ "$hash" != "$expected" ]]; then
      err "Checksum mismatch for $name"; ok=0
    fi
  done
  [[ $ok -eq 1 ]] || return 1
  return 0
}

say "Installing to $PREFIX..."

# Create directory structure that matches source exactly
say "Ensuring directories: $PREFIX and $PREFIX/lib"
mkdir -p "$PREFIX"
mkdir -p "$PREFIX/lib"

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
  local tmp
  tmp=$(mktemp)
  if ! curl -fsSL "$src" -o "$tmp"; then
    err "Failed to download $src"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  fi
  # Backup existing file, if any
  if [[ -f "$dst" ]]; then
    local bkp
    bkp=$(mktemp)
    cp -f "$dst" "$bkp"
    ROLLBACK_BACKUPS+=("$bkp::$dst")
  else
    ROLLBACK_FILES+=("$dst")
  fi
  install -m 0644 "$tmp" "$dst"
  rm -f "$tmp" 2>/dev/null || true
}

# Main script files (no .zsh extension to match source structure)
F_WT="$PREFIX/wt"
F_WTNEW="$PREFIX/wtnew"
F_WTRM="$PREFIX/wtrm"
F_WTOPEN="$PREFIX/wtopen"
F_WTLS="$PREFIX/wtls"

# Library files - ALL of them are required
F_COMMON="$PREFIX/lib/wt-common.zsh"
F_RECOVERY="$PREFIX/lib/wt-recovery.zsh"
F_VALIDATION="$PREFIX/lib/wt-validation.zsh"
F_DISCOVERY="$PREFIX/lib/wt-discovery.zsh"

# Fetch main scripts
fetch "$REPO_RAW/scripts/wt"      "$F_WT"
fetch "$REPO_RAW/scripts/wtnew"   "$F_WTNEW"
fetch "$REPO_RAW/scripts/wtrm"    "$F_WTRM"
fetch "$REPO_RAW/scripts/wtopen"  "$F_WTOPEN"
fetch "$REPO_RAW/scripts/wtls"    "$F_WTLS"

# Fetch ALL library files (modules are required, not optional)
fetch "$REPO_RAW/scripts/lib/wt-common.zsh"     "$F_COMMON"
fetch "$REPO_RAW/scripts/lib/wt-recovery.zsh"   "$F_RECOVERY"
fetch "$REPO_RAW/scripts/lib/wt-validation.zsh" "$F_VALIDATION"
fetch "$REPO_RAW/scripts/lib/wt-discovery.zsh"  "$F_DISCOVERY"

if [[ -n "$CHECKSUM_FILE" ]] && (( ! DRY_RUN )); then
  verify_checksums "$CHECKSUM_FILE" \
    "$F_WT" "$F_WTNEW" "$F_WTRM" "$F_WTOPEN" "$F_WTLS" \
    "$F_COMMON" "$F_RECOVERY" "$F_VALIDATION" "$F_DISCOVERY"
fi

add_source_line() {
  local needle="$1" line="$2"
  if (( DRY_RUN )); then return 0; fi
  if [[ -z "$ZSHRC_BACKUP" && -f "${HOME}/.zshrc" ]]; then
    ZSHRC_BACKUP=$(mktemp)
    cp -f "${HOME}/.zshrc" "$ZSHRC_BACKUP" 2>/dev/null || true
  fi
  if [[ -f "${HOME}/.zshrc" ]] && grep -Fq "$needle" "${HOME}/.zshrc"; then
    (( VERBOSE )) && say "~/.zshrc already has: $needle"
  else
    say "Updating ~/.zshrc"
    echo "$line" >> "${HOME}/.zshrc"
  fi
}

if (( ! NO_SOURCE )); then
  # Source scripts from the new location (they auto-load wt-common.zsh which loads all modules)
  add_source_line 'git-worktrees/wt' \
    '[[ -f ~/.zsh/functions/git-worktrees/wt ]] && source ~/.zsh/functions/git-worktrees/wt'
  add_source_line 'git-worktrees/wtnew' \
    '[[ -f ~/.zsh/functions/git-worktrees/wtnew ]] && source ~/.zsh/functions/git-worktrees/wtnew'
  add_source_line 'git-worktrees/wtrm' \
    '[[ -f ~/.zsh/functions/git-worktrees/wtrm ]] && source ~/.zsh/functions/git-worktrees/wtrm'
  add_source_line 'git-worktrees/wtopen' \
    '[[ -f ~/.zsh/functions/git-worktrees/wtopen ]] && source ~/.zsh/functions/git-worktrees/wtopen'
  add_source_line 'git-worktrees/wtls' \
    '[[ -f ~/.zsh/functions/git-worktrees/wtls ]] && source ~/.zsh/functions/git-worktrees/wtls'
fi

# Self-test (non-fatal)
if (( ! DRY_RUN )); then
  say "Self-test: sourcing functions…"
  if zsh -fc '
    source ~/.zsh/functions/git-worktrees/wt
    source ~/.zsh/functions/git-worktrees/wtnew
    source ~/.zsh/functions/git-worktrees/wtrm
    source ~/.zsh/functions/git-worktrees/wtopen
    source ~/.zsh/functions/git-worktrees/wtls
    typeset -f wt wtnew wtrm wtopen wtls >/dev/null
  '; then
    ok "Commands available: wt, wtnew, wtopen, wtrm, wtls"
  else
    err "Warning: could not verify commands in a subshell. Try: source ~/.zshrc"
  fi
fi

INSTALL_OK=1
trap - EXIT
say "Installed. Restart your shell or run: source ~/.zshrc"

if (( ! QUIET )); then
  cat <<HELP
Commands:
  wt                                                 # hub: list, open, new, remove (Ctrl-E toggles Enter)
  wtnew -n feature/x -b origin/main --push          # create and open worktree
  wtopen                                             # open existing worktree (fzf)
  wtrm --rm-detached --jobs 6 --yes                  # remove detached worktrees in parallel
  wtls --fzf --open                                  # list & open worktrees
HELP
fi
