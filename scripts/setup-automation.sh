#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Setting up Automated Releases for git-worktrees"
echo "=================================================="
echo ""
echo "This will help you set up GitHub Actions to fully automate releases."
echo ""
echo "You'll need to:"
echo "  1. Create a Personal Access Token (PAT) on GitHub"
echo "  2. Add it to your repository secrets"
echo ""
echo "Total time: ~3 minutes"
echo ""
read -p "Ready to start? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo "Setup cancelled."
  exit 0
fi

echo ""
echo "=================================================="
echo "Step 1: Create Personal Access Token"
echo "=================================================="
echo ""
echo "I'll open GitHub in your browser to create a token."
echo ""
echo "Instructions:"
echo "  1. Set token name to: TAP_UPDATE_TOKEN"
echo "  2. Set expiration to: No expiration (or choose a date)"
echo "  3. Check these scopes:"
echo "     ✅ repo (Full control of private repositories)"
echo "     ✅ workflow (Update GitHub Action workflows)"
echo "  4. Click 'Generate token' (green button at bottom)"
echo "  5. COPY THE TOKEN (you won't see it again!)"
echo ""
read -p "Press Enter to open GitHub..." -r
echo ""

# Open GitHub token creation page
if command -v open >/dev/null 2>&1; then
  open "https://github.com/settings/tokens/new?scopes=repo,workflow&description=TAP_UPDATE_TOKEN"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "https://github.com/settings/tokens/new?scopes=repo,workflow&description=TAP_UPDATE_TOKEN"
else
  echo "Open this URL in your browser:"
  echo "https://github.com/settings/tokens/new?scopes=repo,workflow&description=TAP_UPDATE_TOKEN"
fi

echo ""
echo "⏳ Waiting for you to create the token..."
echo ""
read -p "Have you created and COPIED the token? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo ""
  echo "❌ Please create the token first, then run this script again."
  exit 1
fi

echo ""
echo "=================================================="
echo "Step 2: Add Token to Repository Secrets"
echo "=================================================="
echo ""
echo "I'll open the repository secrets page in your browser."
echo ""
echo "Instructions:"
echo "  1. Set name to: TAP_UPDATE_TOKEN"
echo "  2. Paste the token you just copied"
echo "  3. Click 'Add secret' (green button)"
echo ""
read -p "Press Enter to open repository secrets..." -r
echo ""

# Open repository secrets page
REPO_URL="https://github.com/EtienneBBeaulac/git-worktrees/settings/secrets/actions/new"
if command -v open >/dev/null 2>&1; then
  open "$REPO_URL"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$REPO_URL"
else
  echo "Open this URL in your browser:"
  echo "$REPO_URL"
fi

echo ""
echo "⏳ Waiting for you to add the secret..."
echo ""
read -p "Have you added the secret? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo ""
  echo "❌ Please add the secret, then run this script again."
  exit 1
fi

echo ""
echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "You can now create automated releases by just pushing a tag:"
echo ""
echo "  git tag v1.0.2"
echo "  git push origin v1.0.2"
echo ""
echo "The workflow will automatically:"
echo "  ✅ Update Formula in main repo"
echo "  ✅ Update Formula in homebrew-tap"
echo "  ✅ Create GitHub release with notes"
echo ""
echo "Want to test it now with a test release? [Y/n] "
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
  echo ""
  echo "Creating test release v1.0.2-test..."
  git tag v1.0.2-test
  git push origin v1.0.2-test
  
  echo ""
  echo "✅ Test tag pushed!"
  echo ""
  echo "Watch the workflow run at:"
  echo "https://github.com/EtienneBBeaulac/git-worktrees/actions"
  echo ""
  
  if command -v open >/dev/null 2>&1; then
    open "https://github.com/EtienneBBeaulac/git-worktrees/actions"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "https://github.com/EtienneBBeaulac/git-worktrees/actions"
  fi
  
  echo "After verifying it works, delete the test release:"
  echo ""
  echo "  git tag -d v1.0.2-test"
  echo "  git push origin :refs/tags/v1.0.2-test"
  echo ""
  echo "Then delete the test release from:"
  echo "https://github.com/EtienneBBeaulac/git-worktrees/releases"
fi

echo ""
echo "🎉 All done! Happy releasing!"

