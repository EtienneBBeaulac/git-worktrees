#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 v1.0.0"
  exit 1
fi

echo "Creating release $VERSION..."

# Verify clean state
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working directory is not clean"
  echo "Please commit or stash your changes first."
  exit 1
fi

# Verify tests pass
echo "Running tests..."
if ! make test; then
  echo "Error: Tests failed"
  exit 1
fi

# Create tag
echo "Creating tag..."
git tag -a "$VERSION" -m "Release $VERSION"

# Push tag
echo "Pushing tag..."
git push origin "$VERSION"

# Wait for GitHub to process the tag
echo "Waiting for GitHub to generate release tarball..."
sleep 10

# Calculate SHA256
echo "Calculating SHA256..."
SHA=$(curl -fsSL "https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/$VERSION.tar.gz" | shasum -a 256 | awk '{print $1}')

echo ""
echo "==================================="
echo "Release $VERSION created!"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. Create GitHub release:"
echo "   https://github.com/EtienneBBeaulac/git-worktrees/releases/new?tag=$VERSION"
echo ""
echo "2. Update Homebrew formula with this SHA256:"
echo "   sha256 \"$SHA\""
echo ""
echo "3. In your homebrew-tap repository:"
echo "   - Update url to: https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/$VERSION.tar.gz"
echo "   - Update sha256 to: $SHA"
echo "   - Commit and push"
echo ""
echo "4. Test the formula:"
echo "   brew uninstall git-worktrees"
echo "   brew update"
echo "   brew install etiennebbeaulac/tap/git-worktrees"
echo "   brew test git-worktrees"
echo ""

