#!/usr/bin/env bash
set -euo pipefail

# Simple release automation script
# Usage: ./scripts/release.sh 1.0.2

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 VERSION"
  echo "Example: $0 1.0.2"
  exit 1
fi

# Add v prefix if not present
if [[ ! "$VERSION" =~ ^v ]]; then
  VERSION="v${VERSION}"
fi

echo "🚀 Releasing $VERSION..."
echo ""

# Check if we're on main and up to date
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
  echo "❌ Must be on main branch (currently on $BRANCH)"
  exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "❌ You have uncommitted changes. Commit or stash them first."
  exit 1
fi

# Pull latest
echo "📥 Pulling latest changes..."
git pull

# Create and push tag
echo "🏷️  Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION"

# Wait for GitHub to generate tarball
echo "⏳ Waiting for GitHub to generate release tarball..."
sleep 10

# Calculate SHA256
echo "🔐 Calculating SHA256..."
TARBALL_URL="https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/${VERSION}.tar.gz"
SHA256=$(curl -fsSL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

if [[ -z "$SHA256" ]]; then
  echo "❌ Failed to calculate SHA256"
  exit 1
fi

echo "   SHA256: $SHA256"
echo ""

# Update Formula in main repo
echo "📝 Updating Formula in main repo..."
sed -i '' "s|url \".*\"|url \"${TARBALL_URL}\"|" Formula/git-worktrees.rb
sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|" Formula/git-worktrees.rb

git add Formula/git-worktrees.rb
if git diff --staged --quiet; then
  echo "   No changes needed"
else
  git commit -m "chore: update Homebrew formula to $VERSION"
  git push
  echo "   ✅ Pushed to main repo"
fi

# Check if tap exists locally
TAP_PATH="${HOME}/git/personal/homebrew-tap"
if [[ ! -d "$TAP_PATH" ]]; then
  echo ""
  echo "⚠️  Tap repository not found at $TAP_PATH"
  echo "   Manual update needed:"
  echo "   1. Edit Formula/git-worktrees.rb in your tap"
  echo "   2. Update url to: $TARBALL_URL"
  echo "   3. Update sha256 to: $SHA256"
  exit 0
fi

# Update Formula in tap
echo "📝 Updating Formula in tap..."
cd "$TAP_PATH"

# Make sure tap is up to date
git pull

sed -i '' "s|url \".*\"|url \"${TARBALL_URL}\"|" Formula/git-worktrees.rb
sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|" Formula/git-worktrees.rb

git add Formula/git-worktrees.rb
if git diff --staged --quiet; then
  echo "   No changes needed"
else
  git commit -m "Update git-worktrees to $VERSION"
  git push
  echo "   ✅ Pushed to tap"
fi

echo ""
echo "✅ Release $VERSION complete!"
echo ""
echo "Users can now update with:"
echo "  brew update"
echo "  brew upgrade git-worktrees"
echo ""
echo "Create GitHub release at:"
echo "  https://github.com/EtienneBBeaulac/git-worktrees/releases/new?tag=$VERSION"
