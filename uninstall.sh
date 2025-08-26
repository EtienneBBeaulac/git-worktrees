#!/usr/bin/env bash
set -euo pipefail
rm -f ~/.zsh/functions/wtnew.zsh ~/.zsh/functions/wtrm.zsh
sed -i '' '/wtnew\.zsh/d' ~/.zshrc || true
sed -i '' '/wtrm\.zsh/d'  ~/.zshrc || true
echo "Uninstalled. Restart your shell."
