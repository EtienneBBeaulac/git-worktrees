#!/usr/bin/env bash
set -euo pipefail

# Script to help update the Homebrew formula when releasing a new version
# Usage: ./scripts/update-homebrew-formula.sh v1.0.0 /path/to/homebrew-tap

VERSION="${1:-}"
TAP_PATH="${2:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 v1.0.0 [/path/to/homebrew-tap]"
  echo ""
  echo "This script helps you update your Homebrew formula after creating a new release."
  echo ""
  echo "Example:"
  echo "  $0 v1.0.0 ../homebrew-tap"
  exit 1
fi

REPO_URL="https://github.com/EtienneBBeaulac/git-worktrees"
TARBALL_URL="${REPO_URL}/archive/refs/tags/${VERSION}.tar.gz"

echo "================================================"
echo "Homebrew Formula Updater"
echo "================================================"
echo ""
echo "Version: $VERSION"
echo "Tarball: $TARBALL_URL"
echo ""

# Wait for GitHub to generate the tarball
echo "Waiting for GitHub to generate release tarball..."
sleep 5

# Calculate SHA256
echo "Calculating SHA256..."
SHA256=$(curl -fsSL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

if [[ -z "$SHA256" ]]; then
  echo "Error: Failed to calculate SHA256"
  exit 1
fi

echo "SHA256: $SHA256"
echo ""

# Show what needs to be updated
echo "================================================"
echo "Update Formula"
echo "================================================"
echo ""
echo "Update these lines in Formula/git-worktrees.rb:"
echo ""
echo "  url \"${TARBALL_URL}\""
echo "  sha256 \"${SHA256}\""
echo ""

# If tap path provided, try to update it automatically
if [[ -n "$TAP_PATH" ]] && [[ -d "$TAP_PATH" ]]; then
  FORMULA_FILE="$TAP_PATH/Formula/git-worktrees.rb"
  
  if [[ ! -f "$FORMULA_FILE" ]]; then
    echo "Error: Formula not found at $FORMULA_FILE"
    exit 1
  fi
  
  echo "Found formula at: $FORMULA_FILE"
  echo ""
  read -p "Update formula automatically? [y/N] " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create backup
    cp "$FORMULA_FILE" "${FORMULA_FILE}.bak"
    echo "Created backup: ${FORMULA_FILE}.bak"
    
    # Update the formula
    # This is a simple sed replacement - might need adjustment based on formula format
    if grep -q "^  url " "$FORMULA_FILE"; then
      # Update existing url line
      sed -i '' "s|^  url .*|  url \"${TARBALL_URL}\"|" "$FORMULA_FILE"
      echo "✓ Updated url"
    else
      echo "⚠ Could not find url line to update"
    fi
    
    if grep -q "^  sha256 " "$FORMULA_FILE"; then
      # Update existing sha256 line
      sed -i '' "s|^  sha256 .*|  sha256 \"${SHA256}\"|" "$FORMULA_FILE"
      echo "✓ Updated sha256"
    else
      echo "⚠ Could not find sha256 line to update"
    fi
    
    echo ""
    echo "Formula updated! Review the changes:"
    echo ""
    diff "${FORMULA_FILE}.bak" "$FORMULA_FILE" || true
    echo ""
    echo "Next steps:"
    echo "  cd $TAP_PATH"
    echo "  git diff Formula/git-worktrees.rb  # Review changes"
    echo "  git add Formula/git-worktrees.rb"
    echo "  git commit -m \"Update git-worktrees to $VERSION\""
    echo "  git push"
    echo ""
    echo "Test the update:"
    echo "  brew update"
    echo "  brew upgrade git-worktrees"
  fi
else
  echo "Manual update required."
  echo ""
  echo "In your homebrew-tap repository:"
  echo "  1. Edit Formula/git-worktrees.rb"
  echo "  2. Update the url and sha256 lines (shown above)"
  echo "  3. git add Formula/git-worktrees.rb"
  echo "  4. git commit -m \"Update git-worktrees to $VERSION\""
  echo "  5. git push"
  echo ""
fi

echo "================================================"
echo "Test the Formula"
echo "================================================"
echo ""
echo "After pushing to your tap:"
echo "  brew update"
echo "  brew upgrade git-worktrees"
echo "  brew test git-worktrees"
echo ""


