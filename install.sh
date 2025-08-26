#!/usr/bin/env bash
set -euo pipefail
PREFIX="${HOME}/.zsh/functions"
REPO_RAW="https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main"

mkdir -p "$PREFIX"
curl -fsSL "$REPO_RAW/scripts/wtnew" -o "$PREFIX/wtnew.zsh"
curl -fsSL "$REPO_RAW/scripts/wtrm"  -o "$PREFIX/wtrm.zsh"

grep -q 'wtnew.zsh' "${HOME}/.zshrc" || echo '[[ -f ~/.zsh/functions/wtnew.zsh ]] && source ~/.zsh/functions/wtnew.zsh' >> "${HOME}/.zshrc"
grep -q 'wtrm.zsh'  "${HOME}/.zshrc" || echo '[[ -f ~/.zsh/functions/wtrm.zsh  ]] && source ~/.zsh/functions/wtrm.zsh'  >> "${HOME}/.zshrc"

echo "Installed. Restart your shell or run: source ~/.zshrc"
