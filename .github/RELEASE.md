# Release Automation

You have two options for automating releases:

## Option 1: GitHub Actions (Fully Automated) ✨

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically:
- Updates the Formula in the main repo
- Creates a GitHub release with notes
- Updates the Formula in your Homebrew tap

### Setup:

1. **Create a Personal Access Token (PAT):**
   - Go to: https://github.com/settings/tokens/new
   - Name: `TAP_UPDATE_TOKEN`
   - Select scopes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
   - Click "Generate token" and **copy it**

2. **Add the token to repository secrets:**
   - Go to: https://github.com/EtienneBBeaulac/git-worktrees/settings/secrets/actions
   - Click "New repository secret"
   - Name: `TAP_UPDATE_TOKEN`
   - Value: Paste the token you copied
   - Click "Add secret"

3. **That's it!** Now whenever you push a tag, everything happens automatically.

### Usage:

```bash
# Just push a tag, and GitHub Actions does the rest!
git tag -a v1.0.2 -m "Release v1.0.2"
git push origin v1.0.2

# Watch the workflow run at:
# https://github.com/EtienneBBeaulac/git-worktrees/actions
```

The workflow will:
1. Update Formula in main repo
2. Create GitHub release
3. Update Formula in homebrew-tap
4. Push changes to both repos

---

## Option 2: Local Script (Semi-Automated) 🛠️

If you prefer to run releases locally, use the `release.sh` script:

### Usage:

```bash
# From the git-worktrees directory:
./scripts/release.sh 1.0.2

# The script will:
# 1. Create and push the tag
# 2. Calculate SHA256
# 3. Update Formula in main repo
# 4. Update Formula in homebrew-tap (if found locally)
# 5. Commit and push everything
```

### What it does:

- ✅ Creates and pushes version tag
- ✅ Calculates SHA256 checksum
- ✅ Updates Formula in main repo
- ✅ Updates Formula in tap (if `~/git/personal/homebrew-tap` exists)
- ✅ Commits and pushes changes
- ⚠️  You still need to manually create the GitHub release

---

## Comparison

| Feature | GitHub Actions | Local Script |
|---------|----------------|--------------|
| Fully automated | ✅ Yes | ⚠️ Semi (need to create GH release) |
| Requires setup | Yes (PAT token) | No |
| Creates GitHub release | ✅ Yes | ❌ No (manual) |
| Updates main repo | ✅ Yes | ✅ Yes |
| Updates tap | ✅ Yes | ✅ Yes (if local) |
| Works from anywhere | ✅ Yes | ❌ Needs local tap clone |
| Run from CI/CD | ✅ Yes | ❌ No |

---

## Recommendation

**Use GitHub Actions** if:
- ✅ You want fully automated releases
- ✅ You want GitHub releases created automatically
- ✅ You release from different machines
- ✅ You're comfortable setting up the PAT token (one-time, 5 minutes)

**Use Local Script** if:
- ✅ You prefer manual control
- ✅ You don't want to set up tokens
- ✅ You always release from the same machine
- ✅ You're okay with manually creating GitHub releases

---

## Testing

Test the workflow safely without updating the tap:

```bash
# Create a test tag (anything with -test, -alpha, -beta, or -rc)
git tag v1.0.3-test
git push origin v1.0.3-test

# The workflow will:
# ✅ Update Formula in main repo (safe to test)
# ✅ Create a DRAFT release (not visible to users)
# ❌ Skip updating the tap (prevents breaking production)

# After verifying it works, clean up:
git tag -d v1.0.3-test
git push origin :refs/tags/v1.0.3-test
# Then delete the draft release from GitHub
```

### Test Tag Suffixes

The workflow automatically handles these suffixes:
- `-test` → Draft release, no tap update
- `-alpha` → Pre-release, no tap update
- `-beta` → Pre-release, no tap update  
- `-rc` → Pre-release, no tap update
- No suffix → Full release, updates tap

